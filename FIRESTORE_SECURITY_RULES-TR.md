# Firestore Güvenlik Kuralları - Görünür Ad Benzersizliği Zorunluluğu

## KRİTİK: Görünür Ad Benzersizlik Kuralları

Aşağıdaki Firestore güvenlik kuralları görünür ad (display name) benzersizliğini **veritabanı seviyesinde** zorunlu kılar. Bu sistem:
- Birden fazla kullanıcının aynı base username'i seçmesine izin verir (Discord-style: bugra#1234, bugra#1256)
- Her görünür adın (username#number) unique olmasını garanti eder
- Race condition'ları önler
- Client-side kod bypass denemelerini engeller

## Tam Firestore Kuralları

Bu kuralları Firebase Console > Firestore Database > Rules bölümüne kopyalayıp yapıştırın:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    // ============================================
    // GÖRÜNÜR AD BENZERSİZLİK ZORUNLULUĞU
    // ============================================
    // 'displayNames' collection'ı görünür ad -> uid eşleştirmelerini saklar
    // Görünür ad formatı: username#number (örn., bugra#1234)
    // Bu collection veritabanı seviyesinde benzersizliği ZORUNLU KILAR
    match /displayNames/{normalizedDisplayName} {
      // Sadece document yoksa oluşturmaya izin ver
      // Bu, race condition durumlarında bile duplicate görünür adları önler
      allow create: if request.auth != null &&
                       !exists(/databases/$(database)/documents/displayNames/$(normalizedDisplayName)) &&
                       request.resource.data.uid == request.auth.uid &&
                       request.resource.data.displayName is string &&
                       request.resource.data.displayName.matches('.*#[0-9]{4}');

      // Tüm authenticated kullanıcılar okuyabilir (müsaitlik kontrolleri ve transaction'lar için gerekli)
      allow read: if request.auth != null;

      // Görünür ad document'leri client tarafından güncellenmemeli veya silinmemeli
      allow update, delete: if false;
    }

    // ============================================
    // KULLANICILAR COLLECTION'I
    // ============================================
    match /users/{userId} {
      allow read: if request.auth != null;

      // Kullanıcılar sadece kendi document'lerini oluşturabilir/güncelleyebilir
      // Görünür ad username#number formatında olmalı
      allow create: if request.auth != null &&
                       request.auth.uid == userId &&
                       request.resource.data.username is string &&
                       request.resource.data.username.size() >= 3 &&
                       request.resource.data.username.size() <= 20 &&
                       request.resource.data.displayName is string &&
                       request.resource.data.displayName.matches('.*#[0-9]{4}');

      allow update: if request.auth != null &&
                       request.auth.uid == userId;

      allow delete: if false; // Client üzerinden kullanıcı silmeyi engelle

      // Kullanıcı tercihleri alt collection'ı
      match /preferences/{preferenceId} {
        allow read, write: if request.auth != null &&
                              request.auth.uid == userId;
      }
    }

    // ============================================
    // SOHBETLER COLLECTION'I
    // ============================================
    match /chats/{chatId} {
      allow read, write: if request.auth != null &&
        request.auth.uid in resource.data.members;
      allow create: if request.auth != null &&
        request.auth.uid in request.resource.data.members;
      // deletedBy field'ını güncellemek için izin ver (üyeler için)
      allow update: if request.auth != null &&
        request.auth.uid in resource.data.members &&
        request.resource.data.diff(resource.data).affectedKeys().hasOnly(['deletedBy']);
    }

    // ============================================
    // MESAJLAR ALT COLLECTION'I
    // ============================================
    match /chats/{chatId}/messages/{messageId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null;
      allow update, delete: if request.auth != null &&
        request.auth.uid == resource.data.senderId;
    }

    // ============================================
    // ARKADAŞLAR COLLECTION'I
    // ============================================
    match /friends/{userId}/friends/{friendId} {
      allow read: if request.auth != null &&
        request.auth.uid == userId;

      // Kullanıcılar kendi collection'larına arkadaş ekleyebilir
      // Ayrıca istek kabul edildiğinde karşı tarafın collection'ına da ekleme izni (karşılıklı)
      allow create: if request.auth != null &&
                       (request.auth.uid == userId ||
                        request.auth.uid == friendId);

      allow update, delete: if request.auth != null &&
        request.auth.uid == userId;
    }

    // ============================================
    // ARKADAŞLIK İSTEKLERİ COLLECTION
    // ============================================
    match /friendRequests/{requestId} {
      // Kullanıcılar istek oluşturabilir (gönderme)
      allow create: if request.auth != null &&
                       request.auth.uid == request.resource.data.senderId &&
                       request.resource.data.receiverId is string &&
                       request.resource.data.status == 'pending';

      // Kullanıcılar kendi gelen veya giden isteklerini okuyabilir
      // Not: Query'ler için resource.data mevcut olmayabilir, bu yüzden her ikisini de kontrol ediyoruz
      allow read: if request.auth != null &&
                     (!resource.exists ||
                      resource.data.senderId == request.auth.uid ||
                      resource.data.receiverId == request.auth.uid);

      // Alıcılar status'u güncelleyebilir (kabul/reddet)
      // Ayrıca senderDisplayName ve senderPhotoUrl güncellemesine izin ver (görüntüleme amaçlı)
      allow update: if request.auth != null &&
                       resource.data.receiverId == request.auth.uid &&
                       (request.resource.data.diff(resource.data).affectedKeys().hasOnly(['status']) ||
                        request.resource.data.diff(resource.data).affectedKeys().hasOnly(['status', 'senderDisplayName', 'senderPhotoUrl']));

      // Gönderenler kendi pending isteklerini silebilir (iptal)
      allow delete: if request.auth != null &&
                       resource.data.senderId == request.auth.uid &&
                       resource.data.status == 'pending';
    }

    // ============================================
    // BİLDİRİMLER COLLECTION
    // ============================================
    // Bu collection push notification kuyruğu için kullanılır
    // Sadece authenticated kullanıcılar bildirim oluşturabilir
    // Cloud Functions bunları işleyip silecek
    match /notifications/{notificationId} {
      allow create: if request.auth != null;
      allow read, update, delete: if false; // Sadece Cloud Functions değiştirebilir
    }
  }
}
```

## Nasıl Çalışır

### 1. Görünür Ad Rezervasyon Sistemi

`displayNames` collection'ı bir rezervasyon sistemi gibi çalışır:
- Document ID: Normalize edilmiş (küçük harf) görünür ad (örn., "bugra#1234")
- Document Verisi: `{ uid, displayName (orijinal büyük/küçük harf), createdAt }`
- Format: `username#number` formatında, number 4 haneli (1000-9999)

### 2. Atomik Transaction

Bir kullanıcı kayıt olduğunda:
1. Kullanıcı base username girer (örn., "bugra")
2. Firebase Auth kullanıcısı oluşturulur
3. Sistem unique görünür ad oluşturur (örn., "bugra#1234")
4. **Transaction başlar**
5. `displayNames/{normalizedDisplayName}` var mı kontrol edilir
6. Varsa → **Transaction başarısız** → Auth kullanıcısı silinir → Yeni sayı oluşturulur → Tekrar dener
7. Yoksa → `displayNames/{normalizedDisplayName}` oluşturulur → `users/{uid}` oluşturulur → **Transaction commit edilir**

### 3. Race Condition Güvenliği

İki kullanıcı aynı anda "bugra" kaydı yapmaya çalışırsa:
- Kullanıcı A: Sistem "bugra#1234" oluşturur → Transaction rezerve eder
- Kullanıcı B: Sistem "bugra#5678" oluşturur → Transaction rezerve eder
- Her ikisi de başarılı olur, farklı görünür adlarla!

Eğer iki kullanıcı aynı sayıyı alırsa (çok nadir):
- Kullanıcı A: Transaction kontrol eder → görünür ad yok → rezerve eder
- Kullanıcı B: Transaction kontrol eder → görünür ad **artık var** → **Transaction başarısız** → Sistem yeni sayı oluşturur

Firestore transaction'ları **atomik**dir - sadece biri başarılı olabilir.

### 4. Güvenlik Kuralları Zorunluluğu

Birisi client kodunu bypass etse bile:
- Kural: `!exists(/databases/$(database)/documents/displayNames/$(normalizedDisplayName))`
- Bu kural, zaten varsa görünür ad document'i oluşturmayı **engeller**
- Veritabanı seviyesinde zorunluluk = **%100 garanti**

## Veritabanı Yapısı

```
displayNames/
  {normalizedDisplayName}/  (örn., "bugra#1234", "bugra#1256")
    - uid: "user123"
    - displayName: "bugra#1234"
    - createdAt: timestamp

users/
  {uid}/
    - username: "bugra" (base username, #number olmadan)
    - displayName: "bugra#1234" (tam görünür ad)
    - email: "user@example.com"
    - photoUrl: "https://..."
```

## Önemli Notlar

1. **Görünür ad document'lerini asla manuel silmeyin** - Benzersizlik için tutulmalılar
2. **Görünür ad büyük/küçük harf duyarsızdır** - "bugra#1234" ve "Bugra#1234" aynıdır
3. **Birden fazla kullanıcı aynı base username'e sahip olabilir** - Sistem unique sayı atar (bugra#1234, bugra#1256)
4. **Görünür ad formatı zorunludur** - "username#number" formatında olmalı, number 4 haneli
5. **Transaction zorunludur** - Doğrudan yazmalar benzersizlik kontrollerini bypass eder

## Test Etme

Görünür ad benzersizliğini test etmek için:

1. "testuser" ile kayıt olmayı deneyin - Başarılı olmalı (örn: "testuser#1234")
2. "testuser" ile tekrar kayıt olmayı deneyin - Başarılı olmalı farklı sayı ile (örn: "testuser#5678")
3. Birden fazla kullanıcı aynı base username'i seçebilir - Her biri unique sayı alır
4. Görünür adlar benzersizdir - "testuser#1234" sadece bir kez kullanılabilir

## Migration (Geçiş)

Eğer mevcut kullanıcılarınız varsa, migration yapmanız gerekir:

1. Tüm mevcut kullanıcılar için `displayNames` document'leri oluşturun
2. Her kullanıcı için unique görünür ad oluşturun (username#number)
3. Kullanıcı document'lerini displayName field'ı ile güncelleyin

Örnek migration script'i (bir kez çalıştırın):

```javascript
// Firebase Console > Firestore > Data içinde çalıştırın
// Veya Cloud Function kullanın
const users = await db.collection('users').get();
const batch = db.batch();
const usedNumbers = new Set();

users.forEach(userDoc => {
  const data = userDoc.data();
  const baseUsername = data.username || 'user';

  // Unique sayı oluştur
  let number;
  do {
    number = 1000 + Math.floor(Math.random() * 9000);
  } while (usedNumbers.has(number));
  usedNumbers.add(number);

  const displayName = `${baseUsername}#${number}`;
  const normalizedDisplayName = displayName.toLowerCase();

  // displayName document'i oluştur
  const displayNameRef = db.collection('displayNames').doc(normalizedDisplayName);
  batch.set(displayNameRef, {
    uid: userDoc.id,
    displayName: displayName,
    createdAt: FieldValue.serverTimestamp()
  });

  // Kullanıcı document'ini displayName ile güncelle
  batch.update(db.collection('users').doc(userDoc.id), {
    displayName: displayName
  });
});

await batch.commit();
```

