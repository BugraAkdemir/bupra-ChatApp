import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/chat_model.dart';
import '../models/message_model.dart';

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

  Future<List<UserModel>> searchUsers(String query) async {
    final snapshot = await _firestore
        .collection('users')
        .where('username', isGreaterThanOrEqualTo: query)
        .where('username', isLessThanOrEqualTo: '$query\uf8ff')
        .limit(20)
        .get();

    return snapshot.docs
        .map((doc) => UserModel.fromMap(doc.data(), doc.id))
        .toList();
  }

  // Friends
  Future<void> addFriend(String uid, String friendUid) async {
    await _firestore
        .collection('friends')
        .doc(uid)
        .collection('friends')
        .doc(friendUid)
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
        .map((snapshot) => snapshot.docs
            .map((doc) => ChatModel.fromMap(doc.data(), doc.id))
            .toList());
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
        .map((doc) => doc.exists ? ChatModel.fromMap(doc.data()!, chatId) : null);
  }

  // Messages
  Stream<List<MessageModel>> getMessagesStream(String chatId) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MessageModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  Future<void> sendMessage(
    String chatId,
    String senderId,
    String? text,
    String? imageUrl,
  ) async {
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
  }
}

