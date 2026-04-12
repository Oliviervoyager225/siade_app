# 🔥 Firestore Database - ERREUR CRITIQUE

## ❌ Problème

Votre base de données Firestore **n'existe PAS** :

```
Status{code=NOT_FOUND, description=The database (default) does not exist for project siade-2026
Please visit https://console.cloud.google.com/datastore/setup?project=siade-2026
```

**Impact** : 
- ❌ Messages ne fonctionnent pas
- ❌ Live streaming ne peut pas sauvegarder les données
- ❌ Aucune donnée ne peut être stockée

---

## ✅ Solution : Créer la Database Firestore

### Option 1 : Via Console Firebase (RAPIDE - 2 minutes)

1. **Aller sur Firebase Console** :
   ```
   https://console.firebase.google.com/project/siade-2026/firestore
   ```

2. **Cliquez sur "Create Database"**

3. **Choisir le mode** :
   - ✅ **Production mode** (recommandé pour la prod)
   - ⚠️ Test mode (pour développement uniquement - non sécurisé)

4. **Choisir la localisation** :
   - Recommandé : `europe-west1` (Belgique) ou `europe-west3` (Frankfurt)
   - Proche de vos utilisateurs

5. **Confirmer** → Database créée en ~30 secondes

---

### Option 2 : Via Firebase CLI

```powershell
# 1. Installer Firebase CLI (si pas déjà fait)
npm install -g firebase-tools

# 2. Se connecter
firebase login

# 3. Créer Firestore
firebase firestore:databases:create --project siade-2026
```

---

## 🛡️ Règles de Sécurité

Après création, **configurez les règles de sécurité** :

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Utilisateurs : lecture publique, écriture authentifiée
    match /users/{userId} {
      allow read: if true;
      allow write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Conversations : accès limité aux participants
    match /conversations/{convId} {
      allow read: if request.auth != null && 
                     request.auth.uid in resource.data.participants;
      allow create: if request.auth != null;
      allow update: if request.auth != null && 
                       request.auth.uid in resource.data.participants;
      
      // Messages dans une conversation
      match /messages/{messageId} {
        allow read: if request.auth != null;
        allow create: if request.auth != null;
      }
    }
    
    // Lives : lecture publique, écriture pour l'hôte
    match /lives/{liveId} {
      allow read: if true;
      allow create: if request.auth != null;
      allow update, delete: if request.auth != null && 
                               request.auth.uid == resource.data.hostUid;
      
      // Commentaires du live
      match /comments/{commentId} {
        allow read: if true;
        allow create: if request.auth != null;
      }
    }
  }
}
```

**Déployer les règles** :
```powershell
firebase deploy --only firestore:rules --project siade-2026
```

---

## ✅ Vérification

Après création, testez dans votre app :

```dart
import 'package:cloud_firestore/cloud_firestore.dart';

void testFirestore() async {
  try {
    await FirebaseFirestore.instance.collection('test').add({
      'message': 'Hello Firestore!',
      'timestamp': FieldValue.serverTimestamp(),
    });
    print('✅ Firestore fonctionne !');
  } catch (e) {
    print('❌ Erreur : $e');
  }
}
```

---

## 📊 Structure de Données

Votre app utilise ces collections :

```
/users/{uid}
  - firebaseUid: string
  - email: string
  - displayName: string
  - photoURL: string
  - isOnline: bool

/conversations/{convId}
  - participants: array<string>
  - lastMessage: string
  - lastMessageTime: timestamp
  
  /messages/{msgId}
    - senderId: string
    - text: string
    - timestamp: timestamp

/lives/{liveId}
  - hostUid: string
  - hostName: string
  - title: string
  - channelName: string
  - isLive: bool
  - viewerCount: number
  - startedAt: timestamp
  
  /comments/{commentId}
    - userId: string
    - userName: string
    - text: string
    - timestamp: timestamp
```

---

## 🚨 Important

**AVANT** de créer Firestore, choisissez bien :
- ✅ **Localisation** : Ne peut PAS être changée après
- ✅ **Mode** : Production (sécurisé) ou Test (dev uniquement)

Après création, **attendez 30-60 secondes** avant de relancer votre app.

---

## 🔗 Liens Utiles

- Console Firebase : https://console.firebase.google.com/project/siade-2026
- Documentation : https://firebase.google.com/docs/firestore/quickstart
- Règles de sécurité : https://firebase.google.com/docs/firestore/security/get-started

---

**STATUS** : 🔴 BLOQUANT - À faire IMMÉDIATEMENT

**TEMPS ESTIMÉ** : 2-5 minutes

**PROCHAINE ACTION** : Créer la database via console.firebase.google.com
