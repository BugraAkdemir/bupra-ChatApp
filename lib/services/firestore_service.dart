import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/chat_model.dart';
import '../models/message_model.dart';
import '../models/friend_request_model.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Users
  Stream<UserModel?> getUserStream(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .snapshots()
        .map((doc) => doc.exists ? UserModel.fromMap(doc.data()!, uid) : null);
  }

  Future<UserModel?> getUser(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    return doc.exists ? UserModel.fromMap(doc.data()!, uid) : null;
  }

  // Get notification preferences
  Future<Map<String, dynamic>?> getNotificationPreferences(String uid) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(uid)
          .collection('preferences')
          .doc('notifications')
          .get();
      return doc.exists ? doc.data() : null;
    } catch (e) {
      return null;
    }
  }

  // Update notification preferences
  Future<void> updateNotificationPreferences(
    String uid, {
    required bool enabled,
    required bool sound,
    required bool vibration,
    required bool preview,
  }) async {
    await _firestore
        .collection('users')
        .doc(uid)
        .collection('preferences')
        .doc('notifications')
        .set({
          'enabled': enabled,
          'sound': sound,
          'vibration': vibration,
          'preview': preview,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
  }

  // Update user profile (username and displayName)
  Future<void> updateUserProfile(
    String uid,
    String newUsername,
    String newDisplayName,
  ) async {
    // Get current user data
    final userDoc = await _firestore.collection('users').doc(uid).get();
    if (!userDoc.exists) {
      throw Exception('Kullanıcı bulunamadı');
    }

    final currentData = userDoc.data()!;
    final oldDisplayName = currentData['displayName'] ?? '';

    // Check if new display name is available (excluding current user)
    if (oldDisplayName != newDisplayName) {
      final normalizedNewDisplayName = newDisplayName.toLowerCase();
      final displayNameDoc = await _firestore
          .collection('displayNames')
          .doc(normalizedNewDisplayName)
          .get();

      if (displayNameDoc.exists) {
        final existingUid = displayNameDoc.data()?['uid'] as String?;
        if (existingUid != uid) {
          throw Exception('Bu kullanıcı adı zaten kullanılıyor');
        }
      }
    }

    // Use transaction to ensure atomicity
    await _firestore.runTransaction((transaction) async {
      final userRef = _firestore.collection('users').doc(uid);
      final userDoc = await transaction.get(userRef);

      if (!userDoc.exists) {
        throw Exception('Kullanıcı bulunamadı');
      }

      // Update user document
      transaction.update(userRef, {
        'username': newUsername,
        'displayName': newDisplayName,
      });

      // Update displayNames collection if displayName changed
      if (oldDisplayName.isNotEmpty && oldDisplayName != newDisplayName) {
        final normalizedOldDisplayName = oldDisplayName.toLowerCase();
        final normalizedNewDisplayName = newDisplayName.toLowerCase();

        // Delete old displayName document
        final oldDisplayNameRef = _firestore
            .collection('displayNames')
            .doc(normalizedOldDisplayName);
        transaction.delete(oldDisplayNameRef);

        // Create new displayName document
        final newDisplayNameRef = _firestore
            .collection('displayNames')
            .doc(normalizedNewDisplayName);
        transaction.set(newDisplayNameRef, {
          'uid': uid,
          'displayName': newDisplayName,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    });
  }

  Future<List<UserModel>> searchUsers(String query) async {
    // Search by displayName (username#number format)
    // This allows searching by both "bugra" and "bugra#1234"
    final snapshot = await _firestore
        .collection('users')
        .where('displayName', isGreaterThanOrEqualTo: query)
        .where('displayName', isLessThanOrEqualTo: '$query\uf8ff')
        .limit(20)
        .get();

    return snapshot.docs
        .map((doc) => UserModel.fromMap(doc.data(), doc.id))
        .toList();
  }

  // Check if email already exists
  Future<bool> emailExists(String email) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();
      return snapshot.docs.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  // Check if username already exists (case-insensitive)
  Future<bool> usernameExists(String username) async {
    try {
      // Normalize username to lowercase for comparison
      final normalizedUsername = username.toLowerCase().trim();

      if (normalizedUsername.isEmpty) {
        return false;
      }

      // Get all users and check case-insensitively
      final snapshot = await _firestore.collection('users').get();

      // Check if any username matches (case-insensitive)
      for (var doc in snapshot.docs) {
        final userData = doc.data();
        final existingUsername =
            userData['username']?.toString().toLowerCase().trim() ?? '';
        if (existingUsername.isNotEmpty &&
            existingUsername == normalizedUsername) {
          return true;
        }
      }

      return false;
    } catch (e) {
      // If query fails, return false
      // In production, you might want to log this to a monitoring service
      return false;
    }
  }

  // Friends
  Future<void> addFriend(String uid, String friendUid) async {
    // Add friend to both users (bidirectional)
    await _firestore
        .collection('friends')
        .doc(uid)
        .collection('friends')
        .doc(friendUid)
        .set({'addedAt': FieldValue.serverTimestamp()});

    await _firestore
        .collection('friends')
        .doc(friendUid)
        .collection('friends')
        .doc(uid)
        .set({'addedAt': FieldValue.serverTimestamp()});
  }

  Stream<List<String>> getFriendsStream(String uid) {
    return _firestore
        .collection('friends')
        .doc(uid)
        .collection('friends')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.id).toList());
  }

  Future<List<UserModel>> getFriends(String uid) async {
    final friendsSnapshot = await _firestore
        .collection('friends')
        .doc(uid)
        .collection('friends')
        .get();

    final friendUids = friendsSnapshot.docs.map((doc) => doc.id).toList();
    if (friendUids.isEmpty) return [];

    final usersSnapshot = await _firestore
        .collection('users')
        .where(FieldPath.documentId, whereIn: friendUids)
        .get();

    return usersSnapshot.docs
        .map((doc) => UserModel.fromMap(doc.data(), doc.id))
        .toList();
  }

  // Chats
  Stream<List<ChatModel>> getChatsStream(String uid) {
    return _firestore
        .collection('chats')
        .where('members', arrayContains: uid)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) {
          // Filter out chats deleted by current user
          return snapshot.docs
              .map((doc) => ChatModel.fromMap(doc.data(), doc.id))
              .where((chat) => !chat.deletedBy.contains(uid))
              .toList();
        });
  }

  Future<String> createOneToOneChat(String uid1, String uid2) async {
    // Check if chat already exists
    final existingChats = await _firestore
        .collection('chats')
        .where('members', arrayContains: uid1)
        .where('isGroup', isEqualTo: false)
        .get();

    for (var doc in existingChats.docs) {
      final chat = ChatModel.fromMap(doc.data(), doc.id);
      if (chat.members.length == 2 &&
          chat.members.contains(uid1) &&
          chat.members.contains(uid2)) {
        return doc.id;
      }
    }

    // Create new chat
    final chatRef = _firestore.collection('chats').doc();
    await chatRef.set({
      'isGroup': false,
      'members': [uid1, uid2],
      'updatedAt': FieldValue.serverTimestamp(),
    });

    return chatRef.id;
  }

  Future<String> createGroupChat(String name, List<String> members) async {
    final chatRef = _firestore.collection('chats').doc();
    await chatRef.set({
      'isGroup': true,
      'name': name,
      'members': members,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    return chatRef.id;
  }

  Stream<ChatModel?> getChatStream(String chatId) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .snapshots()
        .map(
          (doc) => doc.exists ? ChatModel.fromMap(doc.data()!, chatId) : null,
        );
  }

  // Messages
  Stream<List<MessageModel>> getMessagesStream(String chatId) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => MessageModel.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  Future<void> sendMessage(
    String chatId,
    String senderId,
    String? text,
    String? imageUrl,
  ) async {
    // Get chat info to find recipients
    final chatDoc = await _firestore.collection('chats').doc(chatId).get();
    if (!chatDoc.exists) return;

    final chatData = chatDoc.data()!;
    final members = List<String>.from(chatData['members'] ?? []);

    // Get sender info for notification
    final senderDoc = await _firestore.collection('users').doc(senderId).get();
    final senderData = senderDoc.data();
    final senderDisplayName = senderData?['displayName'] ?? 'Someone';

    // Find recipients (all members except sender)
    final recipients = members.where((uid) => uid != senderId).toList();

    final messageRef = _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .doc();

    await messageRef.set({
      'senderId': senderId,
      if (text != null) 'text': text,
      if (imageUrl != null) 'imageUrl': imageUrl,
      'createdAt': FieldValue.serverTimestamp(),
    });

    // Update chat last message
    await _firestore.collection('chats').doc(chatId).update({
      'lastMessage': text ?? 'Image',
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // Send notifications to recipients
    await _sendNotifications(
      chatId: chatId,
      senderId: senderId,
      senderDisplayName: senderDisplayName,
      recipients: recipients,
      messageText: text,
      isImage: imageUrl != null,
    );
  }

  /// Send notifications to recipients
  /// Creates notification documents that Cloud Functions will process
  Future<void> _sendNotifications({
    required String chatId,
    required String senderId,
    required String senderDisplayName,
    required List<String> recipients,
    String? messageText,
    bool isImage = false,
  }) async {
    if (recipients.isEmpty) return;

    // Get chat info to determine if it's a group
    final chatDoc = await _firestore.collection('chats').doc(chatId).get();
    final chatData = chatDoc.data();
    final isGroup = chatData?['isGroup'] ?? false;
    final groupName = chatData?['name'] as String?;

    // Get recipient FCM tokens
    final recipientsSnapshot = await _firestore
        .collection('users')
        .where(FieldPath.documentId, whereIn: recipients)
        .get();

    final batch = _firestore.batch();

    for (var doc in recipientsSnapshot.docs) {
      final userData = doc.data();
      final fcmToken = userData['fcmToken'] as String?;

      if (fcmToken == null || fcmToken.isEmpty) continue;

      // Create notification document for Cloud Function to process
      final notificationRef = _firestore.collection('notifications').doc();

      final notificationTitle = isGroup
          ? (groupName ?? 'Group')
          : senderDisplayName;

      final notificationBody = isImage
          ? '📷 Image'
          : (messageText ?? 'New message');

      batch.set(notificationRef, {
        'recipientToken': fcmToken,
        'recipientId': doc.id,
        'chatId': chatId,
        'senderId': senderId,
        'senderDisplayName': senderDisplayName,
        'title': notificationTitle,
        'body': notificationBody,
        'createdAt': FieldValue.serverTimestamp(),
        'processed': false,
      });
    }

    await batch.commit();
  }

  // Delete chat (one-sided, WhatsApp style)
  // Only removes chat from current user's view, other members still see it
  Future<void> deleteChat(String chatId, String userId) async {
    final chatRef = _firestore.collection('chats').doc(chatId);

    // Get current deletedBy array
    final chatDoc = await chatRef.get();
    if (!chatDoc.exists) return;

    final currentDeletedBy = List<String>.from(
      chatDoc.data()?['deletedBy'] ?? [],
    );

    // Add current user to deletedBy array if not already there
    if (!currentDeletedBy.contains(userId)) {
      currentDeletedBy.add(userId);
      await chatRef.update({'deletedBy': currentDeletedBy});
    }
  }

  // Restore deleted chat (remove from deletedBy array)
  Future<void> restoreChat(String chatId, String userId) async {
    final chatRef = _firestore.collection('chats').doc(chatId);

    // Get current deletedBy array
    final chatDoc = await chatRef.get();
    if (!chatDoc.exists) return;

    final currentDeletedBy = List<String>.from(
      chatDoc.data()?['deletedBy'] ?? [],
    );

    // Remove current user from deletedBy array
    currentDeletedBy.remove(userId);

    await chatRef.update({'deletedBy': currentDeletedBy});
  }

  // Friend Requests
  // Send friend request
  Future<void> sendFriendRequest(String senderId, String receiverId) async {
    // Check if request already exists
    final existingRequest = await _firestore
        .collection('friendRequests')
        .where('senderId', isEqualTo: senderId)
        .where('receiverId', isEqualTo: receiverId)
        .where('status', isEqualTo: 'pending')
        .limit(1)
        .get();

    if (existingRequest.docs.isNotEmpty) {
      throw Exception('Zaten bir arkadaşlık isteği gönderilmiş');
    }

    // Check if already friends
    final friendDoc = await _firestore
        .collection('friends')
        .doc(senderId)
        .collection('friends')
        .doc(receiverId)
        .get();

    if (friendDoc.exists) {
      throw Exception('Zaten arkadaşsınız');
    }

    // Get sender info
    final senderDoc = await _firestore.collection('users').doc(senderId).get();
    final senderData = senderDoc.data();
    final senderDisplayName = senderData?['displayName'] ?? 'Bilinmeyen';
    final senderPhotoUrl = senderData?['photoUrl'];

    // Create friend request
    await _firestore.collection('friendRequests').add({
      'senderId': senderId,
      'receiverId': receiverId,
      'senderDisplayName': senderDisplayName,
      'senderPhotoUrl': senderPhotoUrl,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // Get incoming friend requests (requests sent to current user)
  Stream<List<FriendRequestModel>> getIncomingRequests(String userId) {
    try {
      return _firestore
          .collection('friendRequests')
          .where('receiverId', isEqualTo: userId)
          .where('status', isEqualTo: 'pending')
          .snapshots()
          .map((snapshot) {
            final requests = <FriendRequestModel>[];
            for (var doc in snapshot.docs) {
              try {
                final data = doc.data();
                requests.add(FriendRequestModel.fromMap(data, doc.id));
              } catch (e) {
                // Skip invalid documents
                continue;
              }
            }

            // Sort by createdAt descending (client-side)
            requests.sort((a, b) => b.createdAt.compareTo(a.createdAt));
            return requests;
          })
          .handleError((error) {
            // Return empty list on error instead of crashing
            return <FriendRequestModel>[];
          });
    } catch (e) {
      // Return empty stream on error
      return Stream.value(<FriendRequestModel>[]);
    }
  }

  // Get outgoing friend requests (requests sent by current user)
  Stream<List<FriendRequestModel>> getOutgoingRequests(String userId) {
    try {
      return _firestore
          .collection('friendRequests')
          .where('senderId', isEqualTo: userId)
          .where('status', isEqualTo: 'pending')
          .snapshots()
          .map((snapshot) {
            final requests = <FriendRequestModel>[];
            for (var doc in snapshot.docs) {
              try {
                final data = doc.data();
                requests.add(FriendRequestModel.fromMap(data, doc.id));
              } catch (e) {
                // Skip invalid documents
                continue;
              }
            }

            // Sort by createdAt descending (client-side)
            requests.sort((a, b) => b.createdAt.compareTo(a.createdAt));
            return requests;
          })
          .handleError((error) {
            // Return empty list on error instead of crashing
            return <FriendRequestModel>[];
          });
    } catch (e) {
      // Return empty stream on error
      return Stream.value(<FriendRequestModel>[]);
    }
  }

  // Accept friend request
  Future<void> acceptFriendRequest(String requestId, String receiverId) async {
    final requestDoc = await _firestore
        .collection('friendRequests')
        .doc(requestId)
        .get();

    if (!requestDoc.exists) {
      throw Exception('İstek bulunamadı');
    }

    final requestData = requestDoc.data()!;
    final senderId = requestData['senderId'] as String;
    final status = requestData['status'] as String;

    if (status != 'pending') {
      throw Exception('İstek zaten işlenmiş');
    }

    if (requestData['receiverId'] != receiverId) {
      throw Exception('Bu isteği kabul etme yetkiniz yok');
    }

    // Update request status first
    await requestDoc.reference.update({'status': 'accepted'});

    // Add friend to both users (bidirectional)
    // Note: We add to receiver's collection first (receiver has permission)
    // Then add to sender's collection (receiver can add to sender's collection due to security rules)
    await _firestore
        .collection('friends')
        .doc(receiverId)
        .collection('friends')
        .doc(senderId)
        .set({'addedAt': FieldValue.serverTimestamp()});

    await _firestore
        .collection('friends')
        .doc(senderId)
        .collection('friends')
        .doc(receiverId)
        .set({'addedAt': FieldValue.serverTimestamp()});
  }

  // Reject friend request
  Future<void> rejectFriendRequest(String requestId, String receiverId) async {
    final requestDoc = await _firestore
        .collection('friendRequests')
        .doc(requestId)
        .get();

    if (!requestDoc.exists) {
      throw Exception('İstek bulunamadı');
    }

    final requestData = requestDoc.data()!;
    if (requestData['receiverId'] != receiverId) {
      throw Exception('Bu isteği reddetme yetkiniz yok');
    }

    await requestDoc.reference.update({'status': 'rejected'});
  }

  // Cancel friend request (sender cancels their own request)
  Future<void> cancelFriendRequest(String requestId, String senderId) async {
    final requestDoc = await _firestore
        .collection('friendRequests')
        .doc(requestId)
        .get();

    if (!requestDoc.exists) {
      throw Exception('İstek bulunamadı');
    }

    final requestData = requestDoc.data()!;
    if (requestData['senderId'] != senderId) {
      throw Exception('Bu isteği iptal etme yetkiniz yok');
    }

    final status = requestData['status'] as String;
    if (status != 'pending') {
      throw Exception('İstek zaten işlenmiş');
    }

    await requestDoc.reference.delete();
  }
}
