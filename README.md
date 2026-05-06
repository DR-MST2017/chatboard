# ChatBoard — Flutter + Firebase

Application de messagerie communautaire en temps réel.

## Stack technique
- **Flutter** — Framework UI cross-platform
- **Firebase Auth** — Authentification Email/Password avec pseudo
- **Cloud Firestore** — Base de données NoSQL temps réel

## Architecture

```
lib/
├── main.dart                    # Firebase init, AuthGate, MaterialApp
├── firebase_options.dart        # Généré par flutterfire configure (à ne pas commiter)
├── models/
│   └── message.dart             # Classe Message (fromFirestore, toMap)
├── screens/
│   ├── auth_screen.dart         # Inscription + Connexion
│   └── chat_screen.dart         # Liste messages + envoi + filtre
└── services/
    ├── auth_service.dart        # Firebase Auth (register, login, logout)
    └── firestore_service.dart   # Firestore CRUD + requêtes
```

## Structure Firestore

```
Collection : messages
  Document : {auto-id}
    text        : String    — contenu du message
    uid         : String    — UID Firebase Auth de l'auteur
    displayName : String    — pseudo de l'auteur
    createdAt   : Timestamp — horodatage serveur
```

## Installation

```bash
# 1. Cloner le projet
git clone <repo>
cd chatboard

# 2. Installer les dépendances Flutter
flutter pub get

# 3. Configurer Firebase (créer un projet Firebase en amont)
dart pub global activate flutterfire_cli
flutterfire configure

# 4. Lancer l'app
flutter run
```

## Fonctionnalités

| Étape | Fonctionnalité |
|-------|---------------|
| 0 | Configuration Firebase + initialisation |
| 1 | Auth Email/Password avec pseudo, AuthGate |
| 2 | Affichage temps réel (StreamBuilder + snapshots) |
| 3 | Envoi de messages (.add + serverTimestamp) |
| 4 | Modification et suppression de ses messages |
| 5 | Filtres Firestore (orderBy, where, limit) |

## Security Rules Firestore (recommandées en production)

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /messages/{docId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null;
      allow update, delete: if request.auth.uid == resource.data.uid;
    }
  }
}
```

## Index Firestore requis

Pour `getMyMessages()` (where + orderBy), créer un index composite :
- Collection : `messages`
- Champs : `uid` (Ascending) + `createdAt` (Descending)

L'URL de création apparaît automatiquement dans la console Flutter au premier appel.
