# Bupra - Mini Chat Application

Bupra is a minimal, production-ready messaging application built with Flutter and Firebase.

## 🚀 Features

- ✅ **Authentication**: Email/password or anonymous login
- ✅ **Users & Friends**: Username system, search, add friends
- ✅ **One-to-One Chat**: Real-time messaging
- ✅ **Group Chat**: Create groups and group messaging
- ✅ **Image Messaging**: Pick images from gallery and send

## 📋 Requirements

- Flutter SDK (3.10.4 or higher)
- Dart SDK
- Firebase account
- Android Studio / Xcode (for platform-specific development)

## 🔧 Installation

### 1. Clone the Project

```bash
git clone <repository-url>
cd bupra
```

### 2. Install Dependencies

```bash
flutter pub get
```

### 3. Firebase Setup

For detailed Firebase setup instructions, see [FIREBASE_SETUP.md](FIREBASE_SETUP.md).

**Quick Start:**

1. Create a new project in Firebase Console
2. Install FlutterFire CLI:
   ```bash
   dart pub global activate flutterfire_cli
   ```
3. Connect Firebase to your project:
   ```bash
   flutterfire configure
   ```
4. Enable Firebase services:
   - Authentication (Email/Password and Anonymous)
   - Cloud Firestore
   - Firebase Storage

### 4. Run the Application

```bash
flutter run
```

## 📱 Platform Configuration

### Android

- **Package Name**: `com.akdbt.bupra`
- Minimum SDK: 21
- Target SDK: 34

### iOS

- **Bundle Identifier**: `com.akdbt.bupra` (set in Xcode)
- Minimum iOS: 12.0

## 🏗️ Project Structure

```
lib/
├── main.dart                    # Application entry point
├── models/                      # Data models
│   ├── user_model.dart
│   ├── chat_model.dart
│   └── message_model.dart
├── services/                    # Firebase services
│   ├── auth_service.dart
│   ├── firestore_service.dart
│   └── storage_service.dart
├── screens/                     # Screens
│   ├── login_screen.dart
│   ├── home_screen.dart
│   ├── friends_screen.dart
│   ├── chat_screen.dart
│   └── create_group_screen.dart
└── widgets/                     # Widgets
    └── message_bubble.dart
```

## 🔐 Firebase Security Rules

### Firestore Rules

Add the following rules in Firebase Console > Firestore Database > Rules:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && request.auth.uid == userId;
    }

    match /chats/{chatId} {
      allow read, write: if request.auth != null &&
        request.auth.uid in resource.data.members;
    }

    match /chats/{chatId}/messages/{messageId} {
      allow read, write: if request.auth != null;
    }

    match /friends/{userId}/friends/{friendId} {
      allow read, write: if request.auth != null &&
        request.auth.uid == userId;
    }
  }
}
```

### Storage Rules

Add the following rules in Firebase Console > Storage > Rules:

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /chats/{chatId}/{fileName} {
      allow read, write: if request.auth != null;
    }
  }
}
```

## 📊 Data Model

### Users Collection
```
users/{uid}
  - username: string
  - email: string
  - photoUrl: string (optional)
```

### Friends Collection
```
friends/{uid}/friends/{friendUid}
  - addedAt: timestamp
```

### Chats Collection
```
chats/{chatId}
  - isGroup: boolean
  - name: string (optional, for groups)
  - members: array[string]
  - lastMessage: string (optional)
  - updatedAt: timestamp
```

### Messages Subcollection
```
chats/{chatId}/messages/{messageId}
  - senderId: string
  - text: string (optional)
  - imageUrl: string (optional)
  - createdAt: timestamp
```

## 🛠️ Development

### Code Structure

- **Services**: All Firebase operations are organized in service classes
- **Models**: Type-safe data models with Firestore serialization
- **Screens**: Each screen in its own file
- **Widgets**: Reusable UI components

### Testing

```bash
flutter test
```

## 📝 License

This is a private project.

## 🤝 Contributing

Contributions are welcome! Please test your changes before submitting a pull request.

## 📞 Contact

You can open an issue for questions.

---

**Note**: This application is for educational and development purposes. Review security settings before using in production.

