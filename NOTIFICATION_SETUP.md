# Bildirim Sistemi Kurulum Rehberi

Bupra uygulamasında Firebase Cloud Messaging (FCM) kullanarak push notification sistemi kurulmuştur.

## 📋 Özellikler

- ✅ Mesaj gönderildiğinde alıcıya bildirim gönderilir
- ✅ Grup sohbetlerinde grup adı gösterilir
- ✅ Birebir sohbetlerde gönderenin adı gösterilir
- ✅ Resim mesajları için özel bildirim
- ✅ Background ve foreground bildirim desteği

## 🔧 Kurulum

### 1. Firebase Console'da FCM Ayarları

1. Firebase Console'a gidin: https://console.firebase.google.com
2. Projenizi seçin
3. **Project Settings** > **Cloud Messaging** sekmesine gidin
4. **Cloud Messaging API (V1)** etkin olduğundan emin olun

### 2. Android Yapılandırması

Android için ek bir yapılandırma gerekmez. `AndroidManifest.xml` dosyasına gerekli izinler eklenmiştir.

**Not:** Android 13+ için bildirim izni runtime'da istenecektir. `firebase_messaging` paketi bunu otomatik olarak yönetir.

### 3. iOS Yapılandırması (Gelecek)

iOS için bildirim yapılandırması eklenecektir.

### 4. Cloud Functions Kurulumu

Bildirimlerin gönderilmesi için Cloud Functions gereklidir.

#### Adım 1: Firebase CLI Kurulumu

```bash
npm install -g firebase-tools
firebase login
```

#### Adım 2: Functions Klasörünü Oluştur

```bash
cd cloud_functions
npm install
```

#### Adım 3: Firebase Projesini Başlat

```bash
firebase init functions
```

Seçenekler:
- **Language:** JavaScript
- **ESLint:** Yes (optional)
- **Install dependencies:** Yes

#### Adım 4: Functions'ı Deploy Et

```bash
firebase deploy --only functions
```

### 5. Firestore Security Rules Güncellemesi

Firestore Security Rules'a `notifications` collection için kurallar ekleyin:

```javascript
match /notifications/{notificationId} {
  allow create: if request.auth != null;
  allow read, update, delete: if false; // Only Cloud Functions can modify
}
```

## 📱 Kullanım

### FCM Token Yönetimi

FCM token'ları otomatik olarak yönetilir:
- Kullanıcı giriş yaptığında token alınır
- Token Firestore'da `users/{uid}/fcmToken` olarak saklanır
- Token yenilendiğinde otomatik olarak güncellenir

### Bildirim Gönderme

Mesaj gönderildiğinde:
1. `FirestoreService.sendMessage()` çağrılır
2. Alıcıların FCM token'ları alınır
3. `notifications` collection'ında yeni document oluşturulur
4. Cloud Function tetiklenir ve bildirim gönderilir

### Bildirim Formatı

**Birebir Sohbet:**
- **Title:** Gönderenin display name (örn: bugra#1234)
- **Body:** Mesaj metni veya "📷 Image"

**Grup Sohbeti:**
- **Title:** Grup adı
- **Body:** Gönderen adı: Mesaj metni (örn: bugra#1234: Merhaba!)

## 🐛 Sorun Giderme

### Bildirimler Gelmiyor

1. **FCM Token Kontrolü:**
   - Firebase Console > Firestore > Data
   - `users/{uid}` document'inde `fcmToken` field'ının olduğundan emin olun

2. **Cloud Function Kontrolü:**
   - Firebase Console > Functions
   - `sendNotification` function'ının deploy edildiğinden emin olun
   - Function logs'ları kontrol edin

3. **Bildirim İzni:**
   - Android 13+ için bildirim izni verildiğinden emin olun
   - Uygulama ayarlarından bildirim izinlerini kontrol edin

4. **Firestore Rules:**
   - `notifications` collection için kuralların doğru olduğundan emin olun

### Cloud Function Hataları

Firebase Console > Functions > Logs bölümünden hataları kontrol edin.

Yaygın hatalar:
- **Missing FCM token:** Alıcının token'ı yok
- **Invalid token:** Token geçersiz veya süresi dolmuş
- **Permission denied:** Firestore rules hatası

## 📚 Daha Fazla Bilgi

- [Firebase Cloud Messaging](https://firebase.google.com/docs/cloud-messaging)
- [Cloud Functions](https://firebase.google.com/docs/functions)
- [FCM REST API](https://firebase.google.com/docs/cloud-messaging/send-message)

---

**Not:** Cloud Functions kullanmadan bildirim göndermek için server key gereklidir, ancak bu güvenlik riski oluşturur. Cloud Functions kullanımı önerilir.

