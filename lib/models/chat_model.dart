import 'package:cloud_firestore/cloud_firestore.dart';

class ChatModel {
  final String chatId;
  final bool isGroup;
  final String? name; // For group chats
  final List<String> members;
  final String? lastMessage;
  final DateTime updatedAt;

  ChatModel({
    required this.chatId,
    required this.isGroup,
    this.name,
    required this.members,
    this.lastMessage,
    required this.updatedAt,
  });

  factory ChatModel.fromMap(Map<String, dynamic> map, String chatId) {
    return ChatModel(
      chatId: chatId,
      isGroup: map['isGroup'] ?? false,
      name: map['name'],
      members: List<String>.from(map['members'] ?? []),
      lastMessage: map['lastMessage'],
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'isGroup': isGroup,
      if (name != null) 'name': name,
      'members': members,
      if (lastMessage != null) 'lastMessage': lastMessage,
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}

