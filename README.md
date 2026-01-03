# Bupra - Mini Chat Uygulaması

Bupra, Flutter ve Firebase kullanılarak geliştirilmiş minimal ve üretim için hazır bir mesajlaşma uygulamasıdır.

## 🚀 Özellikler

- ✅ **Kimlik Doğrulama**: Email/şifre veya anonim giriş
- ✅ **Kullanıcılar ve Arkadaşlar**: Kullanıcı adı sistemi, arama, arkadaş ekleme
- ✅ **Birebir Sohbet**: Gerçek zamanlı mesajlaşma
- ✅ **Grup Sohbeti**: Grup oluşturma ve grup mesajlaşması
- ✅ **Resim Mesajlaşması**: Galeriden resim seçme ve gönderme

## 📋 Gereksinimler

- Flutter SDK (3.10.4 veya üzeri)
- Dart SDK
- Firebase hesabı
- Android Studio / Xcode (platform bağımlı geliştirme için)

## 🔧 Kurulum

### 1. Projeyi Klonlayın

```bash
git clone <repository-url>
cd bupra
```

### 2. Bağımlılıkları Yükleyin

```bash
flutter pub get
```

### 3. Firebase Kurulumu

Detaylı Firebase kurulum talimatları için [FIREBASE_SETUP.md](FIREBASE_SETUP.md) dosyasına bakın.

**Hızlı Başlangıç:**

1. Firebase Console'da yeni bir proje oluşturun
2. FlutterFire CLI'ı yükleyin:
   ```bash
   dart pub global activate flutterfire_cli
   ```
3. Firebase'i projeye bağlayın:
   ```bash
   flutterfire configure
   ```
4. Firebase servislerini etkinleştirin:
   - Authentication (Email/Password ve Anonymous)
   - Cloud Firestore
   - Firebase Storage

### 4. Uygulamayı Çalıştırın

```bash
flutter run
```

## 📱 Platform Yapılandırması

### Android

- **Package Name**: `com.akdbt.bupra`
- Minimum SDK: 21
- Target SDK: 34

### iOS

- **Bundle Identifier**: `com.akdbt.bupra` (Xcode'da ayarlayın)
- Minimum iOS: 12.0

## 🏗️ Proje Yapısı

```
lib/
├── main.dart                    # Uygulama giriş noktası
├── models/                      # Veri modelleri
│   ├── user_model.dart
│   ├── chat_model.dart
│   └── message_model.dart
├── services/                    # Firebase servisleri
│   ├── auth_service.dart
│   ├── firestore_service.dart
│   └── storage_service.dart
├── screens/                     # Ekranlar
│   ├── login_screen.dart
│   ├── home_screen.dart
│   ├── friends_screen.dart
│   ├── chat_screen.dart
│   └── create_group_screen.dart
└── widgets/                     # Widget'lar
    └── message_bubble.dart
```

## 🔐 Firebase Güvenlik Kuralları

### Firestore Kuralları

Firebase Console > Firestore Database > Rules bölümüne aşağıdaki kuralları ekleyin:

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

### Storage Kuralları

Firebase Console > Storage > Rules bölümüne aşağıdaki kuralları ekleyin:

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

## 📊 Veri Modeli

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

## 🛠️ Geliştirme

### Kod Yapısı

- **Services**: Tüm Firebase işlemleri servis sınıflarında toplanmıştır
- **Models**: Type-safe veri modelleri Firestore serileştirmesi ile
- **Screens**: Her ekran kendi dosyasında
- **Widgets**: Yeniden kullanılabilir UI bileşenleri

### Test Etme

```bash
flutter test
```

## 📝 Lisans

Bu proje özel bir projedir.

## 🤝 Katkıda Bulunma

Katkılarınızı bekliyoruz! Lütfen pull request göndermeden önce değişikliklerinizi test edin.

## 📞 İletişim

Sorularınız için issue açabilirsiniz.

---

**Not**: Bu uygulama eğitim ve geliştirme amaçlıdır. Üretim ortamında kullanmadan önce güvenlik ayarlarını gözden geçirin.
