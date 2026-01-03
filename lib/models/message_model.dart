import 'package:cloud_firestore/cloud_firestore.dart';

class MessageModel {
  final String messageId;
  final String senderId;
  final String? text;
  final String? imageUrl;
  final DateTime createdAt;

  MessageModel({
    required this.messageId,
    required this.senderId,
    this.text,
    this.imageUrl,
    required this.createdAt,
  });

  factory MessageModel.fromMap(Map<String, dynamic> map, String messageId) {
    return MessageModel(
      messageId: messageId,
      senderId: map['senderId'] ?? '',
      text: map['text'],
      imageUrl: map['imageUrl'],
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      if (text != null) 'text': text,
      if (imageUrl != null) 'imageUrl': imageUrl,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}

