# Friend Request Debug Rehberi

## Sorun: İstekler Görünmüyor

Eğer istek gönderildiğini söylüyor ama istekler görünmüyorsa, şu adımları kontrol edin:

## 1. Firestore Console'da Kontrol

1. Firebase Console > Firestore Database > Data
2. `friendRequests` collection'ını kontrol edin
3. Yeni istek gönderildiğinde document oluşuyor mu?
4. Document'te şu field'lar var mı?
   - `senderId`
   - `receiverId`
   - `status: "pending"`
   - `createdAt` (timestamp)
   - `senderDisplayName`

## 2. Firestore Security Rules Kontrolü

Firebase Console > Firestore Database > Rules bölümünde şu kurallar olmalı:

```javascript
match /friendRequests/{requestId} {
  allow create: if request.auth != null &&
                   request.auth.uid == request.resource.data.senderId &&
                   request.resource.data.receiverId is string &&
                   request.resource.data.status == 'pending';

  allow read: if request.auth != null &&
                 (resource.data.senderId == request.auth.uid ||
                  resource.data.receiverId == request.auth.uid);

  // ... diğer kurallar
}
```

## 3. Test Adımları

1. **İstek Gönder:**
   - Kullanıcı arayın
   - "İstek Gönder" butonuna tıklayın
   - "Arkadaşlık isteği gönderildi" mesajını görün

2. **Firestore'da Kontrol:**
   - Firebase Console > Firestore > Data
   - `friendRequests` collection'ında yeni document var mı?
   - Document'in field'larını kontrol edin

3. **İstekler Sekmesinde Kontrol:**
   - "İstekler" sekmesine gidin
   - "Gelen İstekler" ve "Giden İstekler" alt sekmelerini kontrol edin
   - Hata mesajı var mı?

## 4. Olası Sorunlar ve Çözümler

### Sorun 1: Security Rules Hatası
**Belirti:** Console'da permission denied hatası
**Çözüm:** Security Rules'ı güncelleyin (yukarıdaki kuralları ekleyin)

### Sorun 2: createdAt Null
**Belirti:** Document oluşuyor ama createdAt null
**Çözüm:** Birkaç saniye bekleyin, serverTimestamp otomatik set edilecek

### Sorun 3: Query Hatası
**Belirti:** Console'da index hatası
**Çözüm:** Hata mesajındaki linke tıklayarak index oluşturun

### Sorun 4: Status Yanlış
**Belirti:** Document'te status "pending" değil
**Çözüm:** İstek gönderme kodunu kontrol edin

## 5. Debug Kodu

Eğer hala çalışmıyorsa, şu debug kodunu ekleyin:

```dart
// FriendsScreen'de _buildRequestsTab içinde
StreamBuilder<List<FriendRequestModel>>(
  stream: _firestoreService.getIncomingRequests(currentUserId),
  builder: (context, snapshot) {
    // Debug: Tüm snapshot'ı yazdır
    if (snapshot.hasData) {
      print('Incoming requests count: ${snapshot.data!.length}');
      for (var req in snapshot.data!) {
        print('Request: ${req.requestId}, Sender: ${req.senderDisplayName}');
      }
    }
    if (snapshot.hasError) {
      print('Error: ${snapshot.error}');
    }
    // ... geri kalan kod
  },
)
```

## 6. Manuel Test

Firebase Console'dan manuel olarak test edin:

1. Firestore > Data > friendRequests
2. "Add document" butonuna tıklayın
3. Şu field'ları ekleyin:
   - `senderId`: "test-sender-id"
   - `receiverId`: "mevcut-kullanıcı-id"
   - `status`: "pending"
   - `senderDisplayName`: "Test User"
   - `createdAt`: Timestamp (şu anki zaman)
4. Uygulamada "İstekler" sekmesine gidin
5. İstek görünüyor mu?

## 7. Hızlı Çözüm

Eğer hiçbir şey çalışmıyorsa, query'leri daha da basitleştirin:

```dart
// Tüm istekleri oku, client-side filtrele
Stream<List<FriendRequestModel>> getAllRequests(String userId) {
  return _firestore
      .collection('friendRequests')
      .snapshots()
      .map((snapshot) {
        return snapshot.docs
            .map((doc) => FriendRequestModel.fromMap(doc.data(), doc.id))
            .where((req) =>
                (req.receiverId == userId || req.senderId == userId) &&
                req.status == 'pending'
            )
            .toList();
      });
}
```

---

**Not:** Eğer hala çalışmıyorsa, Firebase Console'dan `friendRequests` collection'ındaki document'leri kontrol edin ve field'ların doğru olduğundan emin olun.

