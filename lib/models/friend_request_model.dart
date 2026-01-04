import 'package:cloud_firestore/cloud_firestore.dart';

class FriendRequestModel {
  final String requestId;
  final String senderId;
  final String receiverId;
  final String senderDisplayName;
  final String? senderPhotoUrl;
  final DateTime createdAt;
  final String status; // 'pending', 'accepted', 'rejected'

  FriendRequestModel({
    required this.requestId,
    required this.senderId,
    required this.receiverId,
    required this.senderDisplayName,
    this.senderPhotoUrl,
    required this.createdAt,
    this.status = 'pending',
  });

  factory FriendRequestModel.fromMap(Map<String, dynamic> map, String requestId) {
    // Handle createdAt - it might be null if serverTimestamp hasn't been set yet
    DateTime createdAt;
    if (map['createdAt'] != null) {
      if (map['createdAt'] is Timestamp) {
        createdAt = (map['createdAt'] as Timestamp).toDate();
      } else {
        createdAt = DateTime.now();
      }
    } else {
      createdAt = DateTime.now();
    }

    return FriendRequestModel(
      requestId: requestId,
      senderId: map['senderId'] ?? '',
      receiverId: map['receiverId'] ?? '',
      senderDisplayName: map['senderDisplayName'] ?? '',
      senderPhotoUrl: map['senderPhotoUrl'],
      createdAt: createdAt,
      status: map['status'] ?? 'pending',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'receiverId': receiverId,
      'senderDisplayName': senderDisplayName,
      if (senderPhotoUrl != null) 'senderPhotoUrl': senderPhotoUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'status': status,
    };
  }
}

