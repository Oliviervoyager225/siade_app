# 🚨 ACTION URGENTE - Live Streaming

## ❌ Votre problème

Le live Agora se déconnecte immédiatement car :

1. **Firestore n'existe pas** → Impossible de sauvegarder les lives
2. **Cycle de vie incorrect** → L'engine Agora se détruit trop tôt

---

## ✅ Solution RAPIDE (10 min)

### Étape 1 : Créer Firestore (2 min) - OBLIGATOIRE

1. Ouvrir : https://console.firebase.google.com/project/siade-2026/firestore

2. Cliquer **"Create Database"**

3. Choisir :
   - Mode : **Production**
   - Localisation : **europe-west1**

4. Confirmer → **Attendre 60 secondes**

5. Aller dans "Rules" et coller :
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read: if true;
      allow write: if request.auth != null && request.auth.uid == userId;
    }
    match /conversations/{convId} {
      allow read: if request.auth != null && request.auth.uid in resource.data.participants;
      allow create: if request.auth != null;
      allow update: if request.auth != null && request.auth.uid in resource.data.participants;
      match /messages/{messageId} {
        allow read, create: if request.auth != null;
      }
    }
    match /lives/{liveId} {
      allow read: if true;
      allow create: if request.auth != null;
      allow update, delete: if request.auth != null && request.auth.uid == resource.data.hostUid;
      match /comments/{commentId} {
        allow read: if true;
        allow create: if request.auth != null;
      }
    }
  }
}
```

6. Cliquer **"Publish"**

---

### Étape 2 : Tester (5 min)

```powershell
flutter run
```

**Test** :
1. Ouvrir la page de broadcaster
2. Cliquer "Démarrer le live"
3. ✅ Vérifier que le live **ne se déconnecte PAS**
4. Arrêter manuellement

**Logs attendus** :
```
✅ Agora engine initialisé avec succès
✅ Agora Broadcaster joined: live_xxxxx
[Le live reste actif]
```

**Logs INCORRECTS** (si problème) :
```
❌ RtcEngine_leaveChannel  ← Trop rapide
❌ RtcEngine_release       ← Trop rapide
```

---

## 📋 Corrections Appliquées

### ✅ Fichiers Modifiés

1. **live_broadcaster_page.dart** → Dispose conditionnel
2. **live.dart** → Dispose asynchrone
3. **agora_service.dart** → Meilleure gestion d'erreur

### ✅ Changements Clés

**Avant** ❌ :
```dart
dispose() {
  _agora.disposeEngine(); // Détruit tout !
}
```

**Après** ✅ :
```dart
dispose() {
  if (!_isLive) {
    _agora.disposeEngine();
  } else {
    _stopLive().then((_) => _agora.disposeEngine());
  }
}
```

---

## 🎯 Résultat Attendu

### Broadcaster

- ✅ Le live **démarre** et **reste actif**
- ✅ La caméra fonctionne
- ✅ Le live ne se coupe **que si on clique "Arrêter"**
- ✅ Les spectateurs peuvent rejoindre

### Spectateur

- ✅ Voit la vidéo du broadcaster
- ✅ Peut envoyer des commentaires
- ✅ Le compteur de viewers fonctionne

---

## 🛠️ Dépannage Express

| Problème | Solution |
|----------|----------|
| "Firestore NOT_FOUND" | Créer database (Étape 1) |
| Live se déconnecte | Vérifier dispose() modifié |
| Spectateur ne voit rien | Vérifier token + réseau |
| Freeze ou crash | Redémarrer app + device |

---

## 📚 Documentation Détaillée

- **Agora Fix Complet** : [AGORA_LIVE_FIX.md](AGORA_LIVE_FIX.md)
- **Firestore Setup** : [FIRESTORE_SETUP_URGENT.md](FIRESTORE_SETUP_URGENT.md)
- **Optimisation Assets** : [ASSET_OPTIMIZATION_README.md](ASSET_OPTIMIZATION_README.md)

---

**STATUT** : ✅ Code corrigé | 🔴 Firestore à créer

**PROCHAINE ACTION** : Créer Firestore (lien ci-dessus) ⬆️

**TEMPS** : 2 minutes pour Firestore + 5 min de test = **7 minutes total**
