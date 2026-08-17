// Imports explicites de la 2ᵉ génération. Depuis firebase-functions 6.0, la
// racine `require("firebase-functions")` pointe déjà sur la v2 : la nommer
// laissait croire qu'on écrivait de la v1, et c'est ce malentendu qui avait
// figé `generateAgoraToken` sur une signature de gestionnaire abandonnée.
const logger = require("firebase-functions/logger");
const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { onSchedule } = require("firebase-functions/v2/scheduler");
const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const admin = require("firebase-admin");
const nodemailer = require("nodemailer");
const { RtcTokenBuilder, RtcRole } = require("agora-token");

admin.initializeApp();
const db = admin.firestore();
db.settings({ databaseId: "native-db" });

// ─── Configuration Agora ────────────────────────────────────────────────────
const APP_ID = "52d589a829974813817265517619f360";
const APP_CERTIFICATE = "169b45b62b6f4d1da3026a98dca26533";

// Token validity: 1 hour (3600 seconds)
const TOKEN_EXPIRY_SECONDS = 3600;

/**
 * Callable Cloud Function — génère un token Agora RTC sécurisé.
 *
 * Paramètres attendus :
 *   - channelName (string) : nom du channel Agora (= liveId Firestore)
 *   - role        (int)    : 1 = broadcaster, 2 = audience
 *   - uid         (int)    : UID de l'utilisateur (0 = auto-assigné par Agora)
 */
exports.generateAgoraToken = onCall(async (request) => {
  // Vérifier que l'utilisateur est authentifié
  if (!request.auth) {
    throw new HttpsError(
      "unauthenticated",
      "L'utilisateur doit être connecté pour générer un token."
    );
  }

  const { channelName, role, uid = 0 } = request.data;

  if (!channelName || typeof channelName !== "string") {
    throw new HttpsError(
      "invalid-argument",
      "channelName est requis."
    );
  }

  // role: 1 = Publisher (broadcaster), 2 = Subscriber (audience)
  const agoraRole = role === 1 ? RtcRole.PUBLISHER : RtcRole.SUBSCRIBER;

  const currentTimestamp = Math.floor(Date.now() / 1000);
  const privilegeExpiredTs = currentTimestamp + TOKEN_EXPIRY_SECONDS;

  const token = RtcTokenBuilder.buildTokenWithUid(
    APP_ID,
    APP_CERTIFICATE,
    channelName,
    uid,
    agoraRole,
    privilegeExpiredTs,
    privilegeExpiredTs
  );

  logger.info(`Token généré pour channel: ${channelName}, uid: ${request.auth.uid}`);

  return { token };
});

// ─── Envoi du code de vérification par email ────────────────────────────────
exports.sendPasswordResetCode = onCall(async (request) => {
  const { email } = request.data;
  if (!email) throw new HttpsError("invalid-argument", "Email requis");

  // Vérifier que l'utilisateur existe dans Firebase Auth
  try {
    await admin.auth().getUserByEmail(email);
  } catch (e) {
    throw new HttpsError("not-found", "Aucun compte trouvé avec cet email.");
  }

  // Générer un code à 4 chiffres
  const code = Math.floor(1000 + Math.random() * 9000).toString();
  const expiry = Date.now() + 15 * 60 * 1000; // 15 minutes

  // Stocker le code dans Firestore
  await db.collection("passwordResetCodes").doc(email).set({ code, expiry, email });

  // Envoyer l'email via Gmail (config via process.env — fichier functions/.env)
  const emailUser = process.env.EMAIL_USER;
  const emailPassword = process.env.EMAIL_PASSWORD;
  if (!emailUser || !emailPassword) {
    logger.error("EMAIL_USER ou EMAIL_PASSWORD manquant dans functions/.env");
    throw new HttpsError("failed-precondition", "Service email non configuré.");
  }

  const transporter = nodemailer.createTransport({
    service: "gmail",
    auth: { user: emailUser, pass: emailPassword },
  });

  await transporter.sendMail({
    from: `SIADE <${emailUser}>`,
    to: email,
    subject: "Code de vérification SIADE",
    html: `
      <div style="font-family:Arial,sans-serif;max-width:420px;margin:0 auto;padding:24px;background:#0A0E27;border-radius:12px;">
        <h2 style="color:#7B61A8;text-align:center;">Réinitialisation du mot de passe</h2>
        <p style="color:#ccc;">Votre code de vérification est :</p>
        <div style="font-size:44px;font-weight:bold;letter-spacing:12px;color:#7B61A8;text-align:center;padding:16px 0;">${code}</div>
        <p style="color:#ccc;">Ce code expire dans <strong>15 minutes</strong>.</p>
        <p style="color:#888;font-size:12px;">Si vous n'avez pas demandé cette réinitialisation, ignorez cet email.</p>
      </div>
    `,
  });

  logger.info(`Code envoyé à ${email}`);
  return { success: true };
});

// ─── Vérifier le code (sans réinitialiser) ──────────────────────────────────
exports.checkResetCode = onCall(async (request) => {
  const { email, code } = request.data;
  if (!email || !code) throw new HttpsError("invalid-argument", "Email et code requis");

  const doc = await db.collection("passwordResetCodes").doc(email).get();
  if (!doc.exists) throw new HttpsError("not-found", "Code introuvable ou expiré");

  const { code: storedCode, expiry } = doc.data();
  if (Date.now() > expiry) {
    await doc.ref.delete();
    throw new HttpsError("deadline-exceeded", "Code expiré. Veuillez recommencer.");
  }
  if (code !== storedCode) throw new HttpsError("invalid-argument", "Code incorrect");

  return { valid: true };
});

// ─── Vérifier le code et réinitialiser le mot de passe ──────────────────────
exports.verifyCodeAndResetPassword = onCall(async (request) => {
  const { email, code, newPassword } = request.data;
  if (!email || !code || !newPassword) throw new HttpsError("invalid-argument", "Données manquantes");
  if (newPassword.length < 6) throw new HttpsError("invalid-argument", "Mot de passe trop court (min 6 caractères)");

  const doc = await db.collection("passwordResetCodes").doc(email).get();
  if (!doc.exists) throw new HttpsError("not-found", "Code introuvable ou expiré");

  const { code: storedCode, expiry } = doc.data();
  if (Date.now() > expiry) {
    await doc.ref.delete();
    throw new HttpsError("deadline-exceeded", "Code expiré. Veuillez recommencer.");
  }
  if (code !== storedCode) throw new HttpsError("invalid-argument", "Code incorrect");

  const user = await admin.auth().getUserByEmail(email);
  await admin.auth().updateUser(user.uid, { password: newPassword });
  await doc.ref.delete();

  logger.info(`Mot de passe réinitialisé pour ${email}`);
  return { success: true };
});

// ─── Nettoyage automatique des stories expirées (toutes les heures) ──────────
exports.cleanupExpiredStories = onSchedule(
  { schedule: "every 1 hours", timeZone: "UTC" },
  async (_event) => {
    const now = admin.firestore.Timestamp.now();
    let totalDeleted = 0;

    // Suppression par batch de 500 (limite Firestore)
    while (true) {
      const snapshot = await db
        .collection("stories")
        .where("expiresAt", "<", now)
        .limit(500)
        .get();

      if (snapshot.empty) break;

      const batch = db.batch();
      snapshot.docs.forEach((doc) => batch.delete(doc.ref));
      await batch.commit();
      totalDeleted += snapshot.size;

      if (snapshot.size < 500) break;
    }

    logger.info(
      `cleanupExpiredStories: ${totalDeleted} story/stories supprimée(s)`
    );
  }
);

// ─── Notification quand un utilisateur démarre un live ───────────────────────
// Déclenché à chaque création de document dans la collection "lives".
// Envoie une notif FCM + crée un doc in-app à tous les utilisateurs qui ont
// interagi (like, commentaire, partage) avec les posts du streamer.
exports.notifyLiveStarted = onDocumentCreated(
  { document: "lives/{liveId}", database: "native-db" },
  async (event) => {
    const liveId = event.params.liveId;
    const liveData = event.data?.data();
    if (!liveData || liveData.isLive !== true) return;

    const hostUid = liveData.hostUid;
    const hostName = liveData.hostName || "Quelqu'un";
    const hostPhoto = liveData.hostPhotoUrl || "";

    logger.info(`Live démarré: ${liveId} par ${hostUid} (${hostName})`);

    // ── 1. Recueillir les UIDs des interacteurs ──────────────────────────
    const postsSnap = await db
      .collection("posts")
      .where("userId", "==", hostUid)
      .limit(200)
      .get();

    const interactorUids = new Set();

    for (const postDoc of postsSnap.docs) {
      const postData = postDoc.data();

      // likedBy
      for (const uid of postData.likedBy || []) {
        if (uid && uid !== hostUid) interactorUids.add(uid);
      }

      // sharedBy
      for (const uid of postData.sharedBy || []) {
        if (uid && uid !== hostUid) interactorUids.add(uid);
      }
    }

    // Commentaires (sous-collection globale "comments" avec postId)
    if (postsSnap.docs.length > 0) {
      const postIds = postsSnap.docs.map((d) => d.id);
      // Firestore whereIn max 30 — traiter par chunks
      const chunkSize = 30;
      for (let i = 0; i < postIds.length; i += chunkSize) {
        const chunk = postIds.slice(i, i + chunkSize);
        const commentsSnap = await db
          .collection("comments")
          .where("postId", "in", chunk)
          .get();
        for (const c of commentsSnap.docs) {
          const uid = c.data().userId;
          if (uid && uid !== hostUid) interactorUids.add(uid);
        }
      }
    }

    if (interactorUids.size === 0) {
      logger.info("notifyLiveStarted: aucun interacteur trouvé, fin.");
      return;
    }

    logger.info(`notifyLiveStarted: ${interactorUids.size} utilisateur(s) à notifier`);

    // ── 2. Récupérer les tokens FCM + créer les notifs in-app ───────────
    const uidsArray = Array.from(interactorUids);
    const fcmTokens = [];
    const notifBatch = db.batch();
    const notifBody = `${hostName} est en live !`;

    // Traiter par chunks de 30 (limite get Firestore)
    const chunkSize2 = 30;
    for (let i = 0; i < uidsArray.length; i += chunkSize2) {
      const chunk = uidsArray.slice(i, i + chunkSize2);
      const usersSnap = await db
        .collection("users")
        .where(admin.firestore.FieldPath.documentId(), "in", chunk)
        .get();

      for (const userDoc of usersSnap.docs) {
        const userData = userDoc.data();
        const token = userData.fcmToken;
        if (token) fcmTokens.push(token);

        // Créer la notif in-app dans notifications/{uid}/items
        const notifRef = db
          .collection("notifications")
          .doc(userDoc.id)
          .collection("items")
          .doc();

        notifBatch.set(notifRef, {
          type: "live",
          fromUid: hostUid,
          fromName: hostName,
          fromPhoto: hostPhoto,
          liveId: liveId,
          body: notifBody,
          read: false,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });
      }
    }

    await notifBatch.commit();
    logger.info(`notifyLiveStarted: ${uidsArray.length} notifs in-app créées.`);

    // ── 3. Envoyer FCM en multicast (max 500 tokens par appel) ──────────
    if (fcmTokens.length === 0) {
      logger.info("notifyLiveStarted: aucun token FCM, skip push.");
      return;
    }

    const fcmChunkSize = 500;
    let totalSent = 0;
    for (let i = 0; i < fcmTokens.length; i += fcmChunkSize) {
      const tokenChunk = fcmTokens.slice(i, i + fcmChunkSize);
      const message = {
        notification: {
          title: "🔴 En Direct",
          body: notifBody,
        },
        data: {
          type: "live",
          liveId: liveId,
          fromName: hostName,
          fromPhoto: hostPhoto,
          click_action: "FLUTTER_NOTIFICATION_CLICK",
        },
        android: {
          priority: "high",
          notification: {
            sound: "default",
            channelId: "live_notifications",
          },
        },
        apns: {
          payload: {
            aps: { sound: "default", badge: 1 },
          },
        },
        tokens: tokenChunk,
      };

      try {
        const response = await admin.messaging().sendEachForMulticast(message);
        totalSent += response.successCount;
        logger.info(
          `FCM chunk: ${response.successCount}/${tokenChunk.length} envoyé(s), échecs: ${response.failureCount}`
        );
      } catch (err) {
        logger.error("Erreur FCM multicast:", err);
      }
    }

    logger.info(`notifyLiveStarted: ${totalSent} push FCM envoyé(s).`);
  }
);

// ─── Suppression définitive d'un compte ──────────────────────────────────────
// Règle App Store 5.1.1(v) : une app qui permet de créer un compte doit
// permettre de le supprimer depuis l'app. Le nettoyage passe obligatoirement
// par une fonction Cloud : un client authentifié ne peut ni effacer les
// documents des autres participants d'une conversation, ni supprimer sa propre
// entrée Firebase Auth de façon fiable après plusieurs mois de session.

/** Taille maximale d'un batch d'écriture Firestore. */
const TAILLE_BATCH = 450;

/**
 * Supprime tous les documents d'une requête, par pages, sans charger la
 * collection entière en mémoire.
 *
 * @param {admin.firestore.Query} requete requête à vider
 * @param {(doc: admin.firestore.QueryDocumentSnapshot) => Promise<void>} [avantSuppression]
 *   travail à effectuer sur chaque document avant de l'effacer
 * @return {Promise<number>} nombre de documents supprimés
 */
async function supprimerParLots(requete, avantSuppression) {
  let total = 0;
  for (;;) {
    const snapshot = await requete.limit(TAILLE_BATCH).get();
    if (snapshot.empty) return total;

    if (avantSuppression) {
      for (const doc of snapshot.docs) await avantSuppression(doc);
    }

    const batch = db.batch();
    snapshot.docs.forEach((doc) => batch.delete(doc.ref));
    await batch.commit();
    total += snapshot.size;

    // Une page incomplète signifie qu'il n'y a plus rien après.
    if (snapshot.size < TAILLE_BATCH) return total;
  }
}

/** Vide une sous-collection entière. */
async function viderSousCollection(reference) {
  return supprimerParLots(reference);
}

/**
 * Retire l'uid des tableaux `likedBy` où il apparaît, sinon les compteurs de
 * réactions resteraient gonflés par un compte qui n'existe plus.
 *
 * @param {string} collection nom de la collection à parcourir
 * @param {string} uid identifiant à retirer
 */
async function retirerDesLikes(collection, uid) {
  for (;;) {
    const snapshot = await db
      .collection(collection)
      .where("likedBy", "array-contains", uid)
      .limit(TAILLE_BATCH)
      .get();
    if (snapshot.empty) return;

    const batch = db.batch();
    snapshot.docs.forEach((doc) =>
      batch.update(doc.ref, {
        likedBy: admin.firestore.FieldValue.arrayRemove(uid),
      })
    );
    await batch.commit();

    if (snapshot.size < TAILLE_BATCH) return;
  }
}

/** Supprime récursivement un préfixe de Cloud Storage. */
async function supprimerPrefixeStorage(prefixe) {
  try {
    await admin.storage().bucket().deleteFiles({ prefix: prefixe, force: true });
  } catch (err) {
    // Le compte doit disparaître même si un fichier résiste : on trace et on
    // continue plutôt que d'abandonner la suppression à mi-chemin.
    logger.warn(`Storage: échec sur "${prefixe}"`, err);
  }
}

exports.deleteAccount = onCall({ timeoutSeconds: 540 }, async (request) => {
  const uid = request.auth?.uid;
  if (!uid) {
    throw new HttpsError(
      "unauthenticated",
      "Vous devez être connecté pour supprimer votre compte."
    );
  }

  logger.info(`deleteAccount: début pour ${uid}`);
  const compteur = {};

  // 1. Publications de l'utilisateur, et les commentaires qu'elles portent.
  compteur.posts = await supprimerParLots(
    db.collection("posts").where("userId", "==", uid),
    async (doc) => {
      await supprimerParLots(
        db.collection("comments").where("postId", "==", doc.id)
      );
    }
  );

  // 2. Commentaires laissés sous les publications des autres.
  compteur.commentaires = await supprimerParLots(
    db.collection("comments").where("userId", "==", uid)
  );

  // 3. Réactions laissées ailleurs.
  await retirerDesLikes("posts", uid);
  await retirerDesLikes("comments", uid);
  await retirerDesLikes("stories", uid);

  // 4. Stories et lives.
  compteur.stories = await supprimerParLots(
    db.collection("stories").where("userId", "==", uid)
  );
  compteur.lives = await supprimerParLots(
    db.collection("lives").where("hostUid", "==", uid),
    async (doc) => {
      await viderSousCollection(doc.ref.collection("comments"));
    }
  );

  // 5. Appels passés et reçus.
  compteur.appelsEmis = await supprimerParLots(
    db.collection("calls").where("callerId", "==", uid)
  );
  compteur.appelsRecus = await supprimerParLots(
    db.collection("calls").where("calleeId", "==", uid)
  );

  // 6. Conversations. Elles sont supprimées en entier, messages compris :
  // conserver un fil face à un compte effacé laisserait le contenu écrit par
  // l'utilisateur supprimé visible chez son interlocuteur.
  compteur.conversations = await supprimerParLots(
    db.collection("conversations").where("participants", "array-contains", uid),
    async (doc) => {
      await viderSousCollection(doc.ref.collection("messages"));
    }
  );

  // 7. Notifications in-app (sous-collection "items" puis le document parent).
  await viderSousCollection(
    db.collection("notifications").doc(uid).collection("items")
  );
  await db.collection("notifications").doc(uid).delete();

  // 8. Fichiers : médias des publications, puis avatars (nommés
  // avatar_<uid>_<horodatage>.jpg, donc atteignables par préfixe).
  await supprimerPrefixeStorage(`posts/${uid}/`);
  await supprimerPrefixeStorage(`stories/${uid}/`);
  await supprimerPrefixeStorage(`avatars/avatar_${uid}_`);

  // 9. Profil.
  await db.collection("users").doc(uid).delete();

  // 10. L'identité elle-même, en dernier : si une étape précédente échoue,
  // l'utilisateur peut se reconnecter et relancer la suppression. Dans l'ordre
  // inverse, il resterait des données orphelines sans moyen de les atteindre.
  await admin.auth().deleteUser(uid);

  logger.info(
    `deleteAccount: compte ${uid} supprimé — ${JSON.stringify(compteur)}`
  );
  return { success: true, deleted: compteur };
});
