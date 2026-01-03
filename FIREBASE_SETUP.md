# Firebase Kurulum Rehberi

Bu doküman, Bupra uygulaması için Firebase'in nasıl kurulacağını adım adım açıklar.

## 📋 İçindekiler

1. [Firebase Projesi Oluşturma](#1-firebase-projesi-oluşturma)
2. [FlutterFire CLI Kurulumu](#2-flutterfire-cli-kurulumu)
3. [Firebase'i Projeye Bağlama](#3-firebasei-projeye-bağlama)
4. [Firebase Servislerini Etkinleştirme](#4-firebase-servislerini-etkinleştirme)
5. [Güvenlik Kurallarını Ayarlama](#5-güvenlik-kurallarını-ayarlama)
6. [Platform Özel Ayarlar](#6-platform-özel-ayarlar)

---

## 1. Firebase Projesi Oluşturma

### Adım 1: Firebase Console'a Giriş

1. [Firebase Console](https://console.firebase.google.com/) adresine gidin
2. Google hesabınızla giriş yapın
3. "Add project" (Proje Ekle) butonuna tıklayın

### Adım 2: Proje Bilgilerini Girin

1. **Proje adı**: `Bupra` (veya istediğiniz bir isim)
2. **Google Analytics**: İsteğe bağlı (önerilir)
3. "Create project" (Proje Oluştur) butonuna tıklayın
4. Proje oluşturulana kadar bekleyin (birkaç saniye sürebilir)
5. "Continue" (Devam Et) butonuna tıklayın

---

## 2. FlutterFire CLI Kurulumu

FlutterFire CLI, Firebase'i Flutter projenize otomatik olarak bağlamanızı sağlar.

### Adım 1: FlutterFire CLI'ı Yükleyin

```bash
dart pub global activate flutterfire_cli
```

### Adım 2: Firebase'e Giriş Yapın

```bash
firebase login
```

Bu komut tarayıcınızı açacak ve Firebase hesabınıza giriş yapmanızı isteyecektir.

---

## 3. Firebase'i Projeye Bağlama

### Adım 1: FlutterFire Configure

Proje dizininde şu komutu çalıştırın:

```bash
flutterfire configure
```

### Adım 2: İnteraktif Kurulum

CLI size şu soruları soracak:

1. **Firebase projesini seçin**: Listeden oluşturduğunuz projeyi seçin
2. **Platformları seçin**:
   - ✅ Android
   - ✅ iOS (Mac'teyseniz)
   - ✅ Web (isteğe bağlı)

### Adım 3: Dosyaların Oluşturulması

CLI şu dosyaları otomatik olarak oluşturacak:

- `lib/firebase_options.dart` - Firebase yapılandırma dosyası
- `android/app/google-services.json` - Android yapılandırması
- `ios/Runner/GoogleService-Info.plist` - iOS yapılandırması (iOS seçildiyse)

### Adım 4: main.dart'ı Güncelleyin

`lib/main.dart` dosyasını kontrol edin. Şu şekilde olmalı:

```dart
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}
```

**Not**: Eğer `firebase_options.dart` import edilmediyse, ekleyin.

---

## 4. Firebase Servislerini Etkinleştirme

### 4.1 Authentication (Kimlik Doğrulama)

1. Firebase Console'da sol menüden **Authentication** seçin
2. "Get started" (Başlayın) butonuna tıklayın
3. **Sign-in method** (Giriş yöntemi) sekmesine gidin
4. Şu yöntemleri etkinleştirin:
   - ✅ **Email/Password**: "Enable" (Etkinleştir) butonuna tıklayın ve kaydedin
   - ✅ **Anonymous**: "Enable" (Etkinleştir) butonuna tıklayın ve kaydedin

### 4.2 Cloud Firestore

1. Sol menüden **Firestore Database** seçin
2. "Create database" (Veritabanı oluştur) butonuna tıklayın
3. **Production mode** (Üretim modu) seçin (güvenlik kurallarını sonra ayarlayacağız)
4. **Location** (Konum) seçin: En yakın bölgeyi seçin (örn: `europe-west`)
5. "Enable" (Etkinleştir) butonuna tıklayın

### 4.3 Firebase Storage

1. Sol menüden **Storage** seçin
2. "Get started" (Başlayın) butonuna tıklayın
3. **Production mode** seçin
4. **Location** seçin: Firestore ile aynı bölgeyi seçin
5. "Done" (Tamam) butonuna tıklayın

---

## 5. Güvenlik Kurallarını Ayarlama

### 5.1 Firestore Güvenlik Kuralları

1. Firebase Console > **Firestore Database** > **Rules** sekmesine gidin
2. Aşağıdaki kuralları yapıştırın:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users collection
    match /users/{userId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && request.auth.uid == userId;
    }

    // Chats collection
    match /chats/{chatId} {
      allow read, write: if request.auth != null &&
        request.auth.uid in resource.data.members;
      allow create: if request.auth != null &&
        request.auth.uid in request.resource.data.members;
    }

    // Messages subcollection
    match /chats/{chatId}/messages/{messageId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null;
      allow update, delete: if request.auth != null &&
        request.auth.uid == resource.data.senderId;
    }

    // Friends collection
    match /friends/{userId}/friends/{friendId} {
      allow read, write: if request.auth != null &&
        request.auth.uid == userId;
    }
  }
}
```

3. "Publish" (Yayınla) butonuna tıklayın

### 5.2 Storage Güvenlik Kuralları

1. Firebase Console > **Storage** > **Rules** sekmesine gidin
2. Aşağıdaki kuralları yapıştırın:

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    // Chat images
    match /chats/{chatId}/{fileName} {
      allow read: if request.auth != null;
      allow write: if request.auth != null;
    }
  }
}
```

3. "Publish" (Yayınla) butonuna tıklayın

---

## 6. Platform Özel Ayarlar

### 6.1 Android Ayarları

#### google-services.json Kontrolü

`android/app/google-services.json` dosyasının mevcut olduğundan emin olun. FlutterFire CLI bu dosyayı otomatik oluşturur.

#### build.gradle Kontrolü

`android/build.gradle` dosyasında Google Services plugin'inin eklendiğinden emin olun:

```gradle
dependencies {
    classpath 'com.google.gms:google-services:4.4.0'
}
```

`android/app/build.gradle` dosyasının sonunda şu satır olmalı:

```gradle
apply plugin: 'com.google.gms.google-services'
```

### 6.2 iOS Ayarları

#### GoogleService-Info.plist Kontrolü

`ios/Runner/GoogleService-Info.plist` dosyasının mevcut olduğundan emin olun.

#### Podfile Güncelleme

`ios/Podfile` dosyasını açın ve minimum iOS versiyonunu kontrol edin:

```ruby
platform :ios, '12.0'
```

#### Pods Yükleme

```bash
cd ios
pod install
cd ..
```

---

## 7. Test Etme

### Adım 1: Uygulamayı Çalıştırın

```bash
flutter run
```

### Adım 2: İlk Kullanıcı Oluşturun

1. Uygulamayı açın
2. "Sign Up" (Kayıt Ol) seçeneğini seçin
3. Bir kullanıcı adı, email ve şifre girin
4. Kayıt olun

### Adım 3: Firebase Console'da Kontrol Edin

1. Firebase Console > **Authentication** > **Users** sekmesine gidin
2. Yeni oluşturduğunuz kullanıcıyı görmelisiniz

3. Firebase Console > **Firestore Database** > **Data** sekmesine gidin
4. `users` koleksiyonunda kullanıcı verilerini görmelisiniz

---

## 🔧 Sorun Giderme

### Sorun: "FirebaseApp not initialized"

**Çözüm**: `main.dart` dosyasında `Firebase.initializeApp()` çağrısının olduğundan ve `firebase_options.dart` import edildiğinden emin olun.

### Sorun: "Permission denied" hatası

**Çözüm**: Firestore ve Storage güvenlik kurallarını kontrol edin. Test için geçici olarak şu kuralları kullanabilirsiniz (sadece geliştirme için):

```javascript
// Firestore - SADECE GELİŞTİRME İÇİN
match /{document=**} {
  allow read, write: if request.auth != null;
}
```

### Sorun: Android build hatası

**Çözüm**:
1. `flutter clean` çalıştırın
2. `flutter pub get` çalıştırın
3. `android/app/google-services.json` dosyasının mevcut olduğundan emin olun

### Sorun: iOS build hatası

**Çözüm**:
1. `cd ios && pod install && cd ..` çalıştırın
2. `ios/Runner/GoogleService-Info.plist` dosyasının mevcut olduğundan emin olun
3. Xcode'da projeyi açın ve "Signing & Capabilities" ayarlarını kontrol edin

---

## 📚 Ek Kaynaklar

- [FlutterFire Dokümantasyonu](https://firebase.flutter.dev/)
- [Firebase Console](https://console.firebase.google.com/)
- [FlutterFire CLI Dokümantasyonu](https://firebase.flutter.dev/docs/cli/)

---

## ✅ Kontrol Listesi

Kurulumun tamamlandığından emin olmak için:

- [ ] Firebase projesi oluşturuldu
- [ ] FlutterFire CLI yüklendi ve yapılandırıldı
- [ ] `firebase_options.dart` dosyası oluşturuldu
- [ ] Authentication etkinleştirildi (Email/Password ve Anonymous)
- [ ] Firestore Database oluşturuldu
- [ ] Firebase Storage etkinleştirildi
- [ ] Firestore güvenlik kuralları ayarlandı
- [ ] Storage güvenlik kuralları ayarlandı
- [ ] Android `google-services.json` dosyası mevcut
- [ ] iOS `GoogleService-Info.plist` dosyası mevcut (iOS için)
- [ ] Uygulama başarıyla çalışıyor
- [ ] İlk kullanıcı oluşturuldu ve Firebase'de görünüyor

---

**Not**: Üretim ortamında kullanmadan önce güvenlik kurallarını gözden geçirin ve test edin.

