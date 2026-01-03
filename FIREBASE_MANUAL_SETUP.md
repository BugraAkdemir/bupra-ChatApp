# Firebase Manuel Kurulum Rehberi (CLI Olmadan)

Bu rehber, Firebase CLI veya flutterfire kullanmadan, sadece Firebase Console ve manuel dosya düzenlemeleri ile Firebase kurulumunu açıklar.

## 📋 Gereksinimler

- Firebase hesabı (Google hesabı ile giriş)
- Flutter projesi hazır
- Android Studio veya metin editörü

---

## 1. Firebase Projesi Oluşturma (Firebase Console)

### Adım 1: Firebase Console'a Giriş

1. Tarayıcınızda şu adrese gidin: `https://console.firebase.google.com`
2. Google hesabınızla giriş yapın

### Adım 2: Yeni Proje Oluştur

1. Ana sayfada **"Add project"** (Proje ekle) butonuna tıklayın
2. **Proje adı** girin: `Bupra` (veya istediğiniz isim)
3. **"Continue"** (Devam et) butonuna tıklayın
4. **Google Analytics** seçeneğini belirleyin (isteğe bağlı)
5. **"Continue"** butonuna tıklayın
6. Proje oluşturulana kadar bekleyin (30-60 saniye)
7. **"Continue"** butonuna tıklayın

---

## 2. Android Uygulaması Ekleme (Firebase Console)

### Adım 1: Android Uygulamasını Projeye Ekle

1. Firebase Console'da proje panosunda **Android ikonu** (🤖) üzerine tıklayın
2. Veya sol menüden **Project Settings** (Proje ayarları) → **Your apps** → **Add app** → **Android**

### Adım 2: Uygulama Bilgilerini Girin

Açılan formda şu bilgileri girin:

- **Android package name:** `com.akdbt.bupra`
- **App nickname (optional):** `Bupra`
- **Debug signing certificate SHA-1 (optional):** Boş bırakabilirsiniz (geliştirme için gerekli değil)

### Adım 3: Uygulamayı Kaydet

1. **"Register app"** (Uygulamayı kaydet) butonuna tıklayın
2. Bir sonraki ekranda **"Download google-services.json"** butonuna tıklayın
3. Dosya indirilecek

### Adım 4: google-services.json Dosyasını Yerleştir

1. İndirilen `google-services.json` dosyasını bulun
2. Dosyayı şu konuma kopyalayın:
   ```
   android/app/google-services.json
   ```
3. Dosyanın doğru konumda olduğundan emin olun

**Not:** Dosya zaten mevcutsa, yeni indirdiğiniz dosya ile değiştirin.

---

## 3. Android Gradle Yapılandırması

### Adım 1: Proje Seviyesi build.gradle (android/build.gradle.kts)

Dosya: `android/build.gradle.kts`

Bu dosyada değişiklik yapmanıza gerek yok. Sadece kontrol edin:

```kotlin
allprojects {
    repositories {
        google()  // Bu satır olmalı
        mavenCentral()
    }
}
```

### Adım 2: settings.gradle.kts Güncelleme

Dosya: `android/settings.gradle.kts`

Bu dosyada Google Services plugin'ini ekleyin:

```kotlin
plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    id("com.android.application") version "8.11.1" apply false
    id("org.jetbrains.kotlin.android") version "2.2.20" apply false
    id("com.google.gms.google-services") version "4.4.0" apply false  // Bu satırı ekleyin
}
```

### Adım 3: Uygulama Seviyesi build.gradle (android/app/build.gradle.kts)

Dosya: `android/app/build.gradle.kts`

`plugins` bloğuna Google Services plugin'ini ekleyin:

```kotlin
plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")  // Bu satırı ekleyin
}
```

**Tam dosya örneği:**

```kotlin
plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

android {
    namespace = "com.akdbt.bupra"
    compileSdk = flutter.compileSdkVersion
    // ... diğer ayarlar
}
```

---

## 4. Flutter Paketlerini Ekleme (pubspec.yaml)

Dosya: `pubspec.yaml`

`dependencies` bölümüne şu paketleri ekleyin:

```yaml
dependencies:
  flutter:
    sdk: flutter

  cupertino_icons: ^1.0.8

  # Firebase paketleri
  firebase_core: ^3.6.0
  firebase_auth: ^5.3.1
  cloud_firestore: ^5.4.3
  firebase_storage: ^12.3.2

  # Image picker
  image_picker: ^1.1.2

  # Time formatting
  intl: ^0.19.0
```

**Paketleri yüklemek için:**

Terminal'de (proje klasöründe):
```bash
flutter pub get
```

---

## 5. Firebase'i main.dart'ta Başlatma

Dosya: `lib/main.dart`

Firebase'i uygulama başlangıcında başlatın:

```dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'services/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bupra',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const AuthWrapper(),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const HomeScreen(),
      },
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();

    return StreamBuilder(
      stream: authService.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasData) {
          return const HomeScreen();
        }

        return const LoginScreen();
      },
    );
  }
}
```

**Önemli:** `Firebase.initializeApp()` çağrısı `runApp()` öncesinde olmalıdır.

---

## 6. Firebase Servislerini Etkinleştirme (Firebase Console)

### 6.1 Authentication (Kimlik Doğrulama)

1. Firebase Console'da sol menüden **Authentication** seçin
2. **"Get started"** (Başlayın) butonuna tıklayın
3. Üst menüden **"Sign-in method"** (Giriş yöntemi) sekmesine gidin
4. Şu yöntemleri etkinleştirin:

   **Email/Password:**
   - **Email/Password** satırına tıklayın
   - Üstteki toggle'ı **"Enable"** (Etkinleştir) konumuna getirin
   - **"Save"** (Kaydet) butonuna tıklayın

   **Anonymous:**
   - **Anonymous** satırına tıklayın
   - Üstteki toggle'ı **"Enable"** (Etkinleştir) konumuna getirin
   - **"Save"** (Kaydet) butonuna tıklayın

### 6.2 Cloud Firestore (Veritabanı)

1. Firebase Console'da sol menüden **Firestore Database** seçin
2. **"Create database"** (Veritabanı oluştur) butonuna tıklayın
3. **"Start in production mode"** (Üretim modunda başlat) seçeneğini seçin
4. **"Next"** (İleri) butonuna tıklayın
5. **Location** (Konum) seçin:
   - En yakın bölgeyi seçin (örn: `europe-west`, `us-central`)
   - **"Enable"** (Etkinleştir) butonuna tıklayın
6. Veritabanı oluşturulana kadar bekleyin (30-60 saniye)

### 6.3 Firebase Storage (Dosya Depolama)

1. Firebase Console'da sol menüden **Storage** seçin
2. **"Get started"** (Başlayın) butonuna tıklayın
3. **"Start in production mode"** (Üretim modunda başlat) seçeneğini seçin
4. **"Next"** (İleri) butonuna tıklayın
5. **Location** (Konum) seçin:
   - Firestore ile aynı bölgeyi seçin (önerilir)
   - **"Done"** (Tamam) butonuna tıklayın

---

## 7. Firestore Güvenlik Kuralları

Firebase Console > **Firestore Database** > **Rules** sekmesine gidin.

Aşağıdaki kuralları yapıştırın:

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

**"Publish"** (Yayınla) butonuna tıklayın.

---

## 8. Storage Güvenlik Kuralları

Firebase Console > **Storage** > **Rules** sekmesine gidin.

Aşağıdaki kuralları yapıştırın:

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

**"Publish"** (Yayınla) butonuna tıklayın.

---

## 9. Test ve Doğrulama

### Adım 1: Projeyi Temizle ve Yeniden Derle

Terminal'de:
```bash
flutter clean
flutter pub get
```

### Adım 2: Uygulamayı Çalıştır

```bash
flutter run
```

### Adım 3: İlk Kullanıcı Oluştur

1. Uygulamayı açın
2. "Sign Up" (Kayıt Ol) seçeneğini seçin
3. Kullanıcı adı, email ve şifre girin
4. Kayıt olun

### Adım 4: Firebase Console'da Kontrol Et

1. **Authentication** > **Users**: Yeni kullanıcıyı görmelisiniz
2. **Firestore Database** > **Data**: `users` koleksiyonunda kullanıcı verilerini görmelisiniz

---

## ✅ Kontrol Listesi

- [ ] Firebase projesi oluşturuldu (Firebase Console)
- [ ] Android uygulaması eklendi (Package: com.akdbt.bupra)
- [ ] google-services.json indirildi ve `android/app/` klasörüne yerleştirildi
- [ ] `android/settings.gradle.kts` güncellendi (Google Services plugin eklendi)
- [ ] `android/app/build.gradle.kts` güncellendi (Google Services plugin eklendi)
- [ ] `pubspec.yaml` güncellendi (Firebase paketleri eklendi)
- [ ] `flutter pub get` çalıştırıldı
- [ ] `lib/main.dart` güncellendi (Firebase.initializeApp() eklendi)
- [ ] Authentication etkinleştirildi (Email/Password + Anonymous)
- [ ] Firestore Database oluşturuldu
- [ ] Firebase Storage etkinleştirildi
- [ ] Firestore güvenlik kuralları ayarlandı
- [ ] Storage güvenlik kuralları ayarlandı
- [ ] Uygulama başarıyla çalışıyor
- [ ] İlk kullanıcı oluşturuldu ve Firebase'de görünüyor

---

## 🐛 Sorun Giderme

### Hata: "FirebaseApp not initialized"

**Çözüm:** `main.dart` dosyasında `Firebase.initializeApp()` çağrısının `runApp()` öncesinde olduğundan emin olun.

### Hata: "google-services.json not found"

**Çözüm:** Dosyanın `android/app/google-services.json` konumunda olduğundan emin olun.

### Hata: "Plugin with id 'com.google.gms.google-services' not found"

**Çözüm:** `android/settings.gradle.kts` dosyasında plugin tanımının eklendiğinden emin olun.

### Hata: "Permission denied" (Firestore)

**Çözüm:** Firestore güvenlik kurallarını kontrol edin ve yayınladığınızdan emin olun.

### Hata: Build hatası

**Çözüm:**
```bash
flutter clean
cd android
./gradlew clean
cd ..
flutter pub get
flutter run
```

---

## 📝 Önemli Notlar

1. **google-services.json** dosyasını asla Git'e commit etmeyin (güvenlik riski). `.gitignore` dosyasına ekleyin:
   ```
   android/app/google-services.json
   ```

2. **Package name** değiştirilirse, Firebase Console'da yeni bir Android uygulaması eklemeniz ve yeni `google-services.json` indirmeniz gerekir.

3. **Güvenlik kuralları** üretim ortamında kullanmadan önce gözden geçirin ve test edin.

4. **Firebase Console** üzerinden tüm işlemler yapılmalıdır. CLI kullanılmamalıdır.

---

**Kurulum tamamlandı!** Artık Firebase servislerini kullanabilirsiniz.

