# 🚀 Hızlı Başlangıç Rehberi

Bupra uygulamasını hızlıca çalıştırmak için bu adımları takip edin.

## ⚡ 5 Dakikada Başlayın

### 1. Bağımlılıkları Yükleyin

```bash
flutter pub get
```

### 2. Firebase CLI'ı Yükleyin

```bash
dart pub global activate flutterfire_cli
```

### 3. Firebase'e Giriş Yapın

```bash
firebase login
```

### 4. Firebase'i Yapılandırın

```bash
flutterfire configure
```

Bu komut sırasında:
- Firebase projenizi seçin (yoksa önce [Firebase Console](https://console.firebase.google.com/)'da oluşturun)
- Android ve iOS platformlarını seçin

### 5. Firebase Servislerini Etkinleştirin

Firebase Console'da ([console.firebase.google.com](https://console.firebase.google.com/)):

1. **Authentication** > **Sign-in method**:
   - ✅ Email/Password → Enable
   - ✅ Anonymous → Enable

2. **Firestore Database**:
   - Create database → Production mode → Location seçin → Enable

3. **Storage**:
   - Get started → Production mode → Location seçin → Done

### 6. Güvenlik Kurallarını Ayarlayın

Detaylı kurallar için [FIREBASE_SETUP.md](FIREBASE_SETUP.md) dosyasına bakın.

**Firestore Rules** (Firestore Database > Rules):
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

**Storage Rules** (Storage > Rules):
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

### 7. main.dart'ı Güncelleyin

`lib/main.dart` dosyasını açın ve yorum satırlarını kaldırın:

```dart
import 'firebase_options.dart';  // Yorumu kaldırın

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,  // Yorumu kaldırın
  );
  runApp(const MyApp());
}
```

### 8. Uygulamayı Çalıştırın

```bash
flutter run
```

## ✅ Kontrol Listesi

- [ ] `flutter pub get` çalıştırıldı
- [ ] FlutterFire CLI yüklendi
- [ ] `flutterfire configure` çalıştırıldı
- [ ] Firebase Authentication etkinleştirildi
- [ ] Firestore Database oluşturuldu
- [ ] Firebase Storage etkinleştirildi
- [ ] Güvenlik kuralları ayarlandı
- [ ] `main.dart` güncellendi
- [ ] Uygulama çalışıyor

## 🐛 Sorun mu Yaşıyorsunuz?

- **"FirebaseApp not initialized"**: `main.dart`'da `firebase_options.dart` import edildiğinden emin olun
- **"Permission denied"**: Güvenlik kurallarını kontrol edin
- **Build hatası**: `flutter clean && flutter pub get` çalıştırın

Detaylı sorun giderme için [FIREBASE_SETUP.md](FIREBASE_SETUP.md) dosyasına bakın.

## 📚 Daha Fazla Bilgi

- [README.md](README.md) - Genel proje bilgileri
- [FIREBASE_SETUP.md](FIREBASE_SETUP.md) - Detaylı Firebase kurulum rehberi

---

**Hazırsınız!** 🎉 Artık Bupra uygulamanızı kullanmaya başlayabilirsiniz.

