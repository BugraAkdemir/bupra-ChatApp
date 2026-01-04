import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../models/chat_model.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_card.dart';
import '../widgets/custom_snackbar.dart';
import 'chat_screen.dart';
import 'create_group_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    final firestoreService = FirestoreService();
    final currentUserId = authService.currentUser?.uid;

    if (currentUserId == null) {
      return Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        body: const Center(
          child: Text(
            'Not authenticated',
            style: TextStyle(color: AppTheme.textPrimary),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Sohbetler'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded),
            onPressed: () {
              CustomSnackBar.showInfo(context, 'Arama yakında eklenecek');
            },
          ),
        ],
      ),
      body: StreamBuilder<List<ChatModel>>(
        stream: firestoreService.getChatsStream(currentUserId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
              ),
            );
          }

          if (snapshot.hasError) {
            // Don't show error, show empty state instead
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.chat_bubble_outline_rounded,
                      size: 40,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Henüz sohbet yok',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            );
          }

          final chats = snapshot.data ?? [];

          if (chats.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.chat_bubble_outline_rounded,
                      size: 40,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Henüz sohbet yok',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 48),
                    child: Text(
                      'Arkadaşlar sekmesinden arkadaş ekleyerek\nsohbet başlatabilirsiniz',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: chats.length,
            itemBuilder: (context, index) {
              final chat = chats[index];
              return _ChatListItem(chat: chat, currentUserId: currentUserId);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CreateGroupScreen()),
          );
        },
        child: const Icon(Icons.group_add_rounded),
      ),
    );
  }
}

class _ChatListItem extends StatelessWidget {
  final ChatModel chat;
  final String currentUserId;

  const _ChatListItem({
    required this.chat,
    required this.currentUserId,
  });

  Future<String> _getChatTitle(FirestoreService firestoreService) async {
    if (chat.isGroup) {
      return chat.name?.isNotEmpty == true ? chat.name! : 'Grup';
    } else {
      try {
        final otherUserId = chat.members.firstWhere(
          (id) => id != currentUserId && id.isNotEmpty,
          orElse: () => '',
        );
        if (otherUserId.isEmpty) return 'Bilinmeyen';
        final user = await firestoreService.getUser(otherUserId);
        return user?.displayName.isNotEmpty == true ? user!.displayName : 'Bilinmeyen';
      } catch (e) {
        return 'Bilinmeyen';
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final firestoreService = FirestoreService();

    return FutureBuilder<String>(
      future: _getChatTitle(firestoreService),
      builder: (context, snapshot) {
        final title = snapshot.data ?? 'Yükleniyor...';

        return CustomCard(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ChatScreen(chatId: chat.chatId),
              ),
            );
          },
          onLongPress: () {
            _ChatListItem._showDeleteDialog(context, chat.chatId, currentUserId);
          },
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: chat.isGroup
                      ? LinearGradient(
                          colors: [
                            AppTheme.primaryColor,
                            AppTheme.accentColor,
                          ],
                        )
                      : null,
                  color: chat.isGroup ? null : AppTheme.primaryColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  chat.isGroup ? Icons.group_rounded : Icons.person_rounded,
                  color: chat.isGroup ? AppTheme.textPrimary : AppTheme.primaryColor,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      chat.lastMessage?.isNotEmpty == true
                          ? chat.lastMessage!
                          : 'Henüz mesaj yok',
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _formatTime(chat.updatedAt),
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}g';
    } else {
      return '${dateTime.day}/${dateTime.month}';
    }
  }

  static void _showDeleteDialog(BuildContext context, String chatId, String userId) {
    final firestoreService = FirestoreService();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceColor,
        title: const Text(
          'Sohbeti Sil',
          style: TextStyle(color: AppTheme.textPrimary),
        ),
        content: const Text(
          'Bu sohbeti silmek istediğinize emin misiniz? Sohbet karşı tarafta görünmeye devam edecektir.',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'İptal',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await firestoreService.deleteChat(chatId, userId);
                if (context.mounted) {
                  CustomSnackBar.showSuccess(context, 'Sohbet silindi');
                }
              } catch (e) {
                // Silently handle errors
              }
            },
            child: const Text(
              'Sil',
              style: TextStyle(color: AppTheme.errorColor),
            ),
          ),
        ],
      ),
    );
  }
}
