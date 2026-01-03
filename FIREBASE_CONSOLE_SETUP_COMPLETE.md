# ✅ Firebase Console Kurulumu Tamamlandı

## Durum Kontrolü

✅ **google-services.json** dosyası mevcut ve doğru konumda:
- Konum: `android/app/google-services.json`
- Package Name: `com.akdbt.bupra` ✓

## Sonraki Adımlar

### 1. Firebase Servislerini Etkinleştirin

Firebase Console'da ([console.firebase.google.com](https://console.firebase.google.com/)):

#### Authentication
1. Sol menüden **Authentication** seçin
2. "Get started" (Başlayın) butonuna tıklayın
3. **Sign-in method** sekmesine gidin
4. Şu yöntemleri etkinleştirin:
   - ✅ **Email/Password** → "Enable" → Kaydet
   - ✅ **Anonymous** → "Enable" → Kaydet

#### Cloud Firestore
1. Sol menüden **Firestore Database** seçin
2. "Create database" (Veritabanı oluştur) butonuna tıklayın
3. **Production mode** seçin
4. **Location** seçin (örn: `europe-west`)
5. "Enable" (Etkinleştir) butonuna tıklayın

#### Firebase Storage
1. Sol menüden **Storage** seçin
2. "Get started" (Başlayın) butonuna tıklayın
3. **Production mode** seçin
4. **Location** seçin (Firestore ile aynı)
5. "Done" (Tamam) butonuna tıklayın

### 2. Güvenlik Kurallarını Ayarlayın

#### Firestore Rules

Firebase Console > **Firestore Database** > **Rules** sekmesine gidin ve şu kuralları yapıştırın:

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
      allow create: if request.auth != null &&
        request.auth.uid in request.resource.data.members;
    }

    match /chats/{chatId}/messages/{messageId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null;
      allow update, delete: if request.auth != null &&
        request.auth.uid == resource.data.senderId;
    }

    match /friends/{userId}/friends/{friendId} {
      allow read, write: if request.auth != null &&
        request.auth.uid == userId;
    }
  }
}
```

**"Publish" (Yayınla)** butonuna tıklayın.

#### Storage Rules

Firebase Console > **Storage** > **Rules** sekmesine gidin ve şu kuralları yapıştırın:

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /chats/{chatId}/{fileName} {
      allow read: if request.auth != null;
      allow write: if request.auth != null;
    }
  }
}
```

**"Publish" (Yayınla)** butonuna tıklayın.

### 3. Android build.gradle Kontrolü

`android/app/build.gradle.kts` dosyasının sonunda şu satır olmalı:

```kotlin
plugins {
    // ... diğer plugin'ler
    id("com.google.gms.google-services")  // Bu satır olmalı
}
```

Eğer yoksa, `android/build.gradle.kts` dosyasına ekleyin:

```kotlin
buildscript {
    dependencies {
        classpath("com.google.gms:google-services:4.4.0")
    }
}
```

### 4. Uygulamayı Test Edin

```bash
flutter clean
flutter pub get
flutter run
```

## ✅ Kontrol Listesi

- [x] Firebase projesi oluşturuldu
- [x] Android uygulaması eklendi
- [x] google-services.json indirildi ve doğru konumda
- [ ] Authentication etkinleştirildi (Email/Password + Anonymous)
- [ ] Firestore Database oluşturuldu
- [ ] Firebase Storage etkinleştirildi
- [ ] Firestore güvenlik kuralları ayarlandı
- [ ] Storage güvenlik kuralları ayarlandı
- [ ] Uygulama başarıyla çalışıyor

## 📝 Notlar

- **google-services.json** dosyası zaten mevcut ve doğru yapılandırılmış
- Package name (`com.akdbt.bupra`) doğru
- Firebase Console üzerinden manuel kurulum tamamlandı
- CLI kullanılmadı (isteğe bağlı)

## 🐛 Sorun Giderme

Eğer "Object ProgressEvent" hatası aldıysanız, [FIREBASE_CONSOLE_TROUBLESHOOTING.md](FIREBASE_CONSOLE_TROUBLESHOOTING.md) dosyasına bakın.

---

**Hazırsınız!** Artık Firebase servislerini etkinleştirip güvenlik kurallarını ayarlayabilirsiniz.

