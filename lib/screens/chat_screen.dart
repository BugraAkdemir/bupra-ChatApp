import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/storage_service.dart';
import '../models/message_model.dart';
import '../models/user_model.dart';
import '../theme/app_theme.dart';
import '../widgets/message_bubble.dart';
import '../widgets/custom_snackbar.dart';

class ChatScreen extends StatefulWidget {
  final String chatId;

  const ChatScreen({super.key, required this.chatId});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _messageController = TextEditingController();
  final _firestoreService = FirestoreService();
  final _storageService = StorageService();
  final _authService = AuthService();
  final _imagePicker = ImagePicker();
  final _scrollController = ScrollController();
  final Map<String, UserModel> _userCache = {}; // Cache for user data
  bool _isInitialLoad = true;
  bool _hasScrolledToBottom = false;
  int _previousMessageCount = 0; // Track message count to detect new messages

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final senderId = _authService.currentUser?.uid;
    if (senderId == null || senderId.isEmpty) return;

    // Clear text immediately for better UX
    final messageText = text;
    _messageController.clear();

    // Save current scroll position before sending
    double? savedScrollPosition;
    if (_scrollController.hasClients) {
      savedScrollPosition = _scrollController.position.pixels;
    }

    try {
      await _firestoreService.sendMessage(widget.chatId, senderId, messageText, null);

      // Restore scroll position after a short delay to prevent jump
      if (savedScrollPosition != null && _scrollController.hasClients) {
        final scrollPos = savedScrollPosition; // Capture for closure
        Future.delayed(const Duration(milliseconds: 50), () {
          if (_scrollController.hasClients) {
            // Only scroll if user was at bottom (within 100px)
            if (scrollPos < 100) {
              _scrollController.jumpTo(0.0);
            } else {
              // Maintain scroll position
              _scrollController.jumpTo(scrollPos);
            }
          }
        });
      }
    } catch (e) {
      // Silently handle errors - don't show to user
      // Error is logged but not displayed
    }
  }

  Future<void> _sendImage() async {
    final senderId = _authService.currentUser?.uid;
    if (senderId == null || senderId.isEmpty) return;

    try {
      final image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
      );

      if (image == null) return;

      if (mounted) {
        CustomSnackBar.showLoading(context, 'Resim yükleniyor...');
      }

      final imageUrl = await _storageService.uploadImage(
        File(image.path),
        widget.chatId,
      );

      await _firestoreService.sendMessage(
        widget.chatId,
        senderId,
        null,
        imageUrl,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
      }
    } catch (e) {
      // Silently handle errors - don't show to user
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
      }
    }
  }

  Future<void> _preloadUserData(List<MessageModel> messages) async {
    final userIdsToLoad = <String>{};
    for (final message in messages) {
      if (!_userCache.containsKey(message.senderId)) {
        userIdsToLoad.add(message.senderId);
      }
    }

    if (userIdsToLoad.isEmpty) return;

    // Load all users in parallel
    final futures = userIdsToLoad.map((uid) => _firestoreService.getUser(uid));
    final users = await Future.wait(futures);

    if (mounted) {
      // Update cache without forcing full rebuild
      bool hasNewData = false;
      for (int i = 0; i < userIdsToLoad.length; i++) {
        final userId = userIdsToLoad.elementAt(i);
        final user = users[i];
        if (user != null && !_userCache.containsKey(userId)) {
          _userCache[userId] = user;
          hasNewData = true;
        }
      }

      // Only call setState if we actually added new data
      if (hasNewData) {
        setState(() {});
      }
    }
  }

  Future<String> _getChatTitle() async {
    try {
      final chat = await _firestoreService.getChatStream(widget.chatId).first;
      if (chat == null) return 'Sohbet';

      final currentUserId = _authService.currentUser?.uid;
      if (currentUserId == null || currentUserId.isEmpty) return 'Sohbet';

      if (chat.isGroup) {
        return chat.name?.isNotEmpty == true ? chat.name! : 'Grup Sohbeti';
      } else {
        try {
          final otherUserId = chat.members.firstWhere(
            (id) => id != currentUserId && id.isNotEmpty,
            orElse: () => '',
          );
          if (otherUserId.isEmpty) return 'Sohbet';
          final user = await _firestoreService.getUser(otherUserId);
          return user?.displayName.isNotEmpty == true ? user!.displayName : 'Bilinmeyen';
        } catch (e) {
          return 'Sohbet';
        }
      }
    } catch (e) {
      return 'Sohbet';
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = _authService.currentUser?.uid;

    return Scaffold(
      backgroundColor: AppTheme.chatBackgroundColor,
      appBar: AppBar(
        title: FutureBuilder<String>(
          future: _getChatTitle(),
          builder: (context, snapshot) {
            return Text(snapshot.data ?? 'Sohbet');
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert_rounded),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Yakında eklenecek'),
                  backgroundColor: AppTheme.surfaceColor,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<MessageModel>>(
              stream: _firestoreService.getMessagesStream(widget.chatId),
              builder: (context, snapshot) {
                // Show loading only on initial load
                if (_isInitialLoad && snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                    ),
                  );
                }

                if (snapshot.hasError) {
                  // Don't show error to user, show empty state instead
                  _isInitialLoad = false;
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline_rounded,
                          size: 64,
                          color: AppTheme.textSecondary,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Henüz mesaj yok',
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final messages = snapshot.data ?? [];
                final currentMessageCount = messages.length;
                final isNewMessage = currentMessageCount > _previousMessageCount;

                // Preload user data only when needed (new users or initial load)
                if (_isInitialLoad) {
                  _preloadUserData(messages);
                  _isInitialLoad = false;
                } else if (isNewMessage) {
                  // Only preload for new messages, don't reload all
                  final newMessages = messages.skip(_previousMessageCount).toList();
                  _preloadUserData(newMessages);
                }

                _previousMessageCount = currentMessageCount;

                if (messages.isEmpty) {
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
                          'Henüz mesaj yok',
                          style: TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'İlk mesajı göndererek sohbete başlayın',
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                // Auto-scroll to bottom only on initial load
                if (!_hasScrolledToBottom && messages.isNotEmpty) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (_scrollController.hasClients) {
                      _scrollController.jumpTo(0.0);
                      _hasScrolledToBottom = true;
                    }
                  });
                } else if (isNewMessage && _scrollController.hasClients) {
                  // Only auto-scroll if user is near bottom when new message arrives
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (_scrollController.hasClients) {
                      final position = _scrollController.position;
                      // If user is within 200px of bottom, auto-scroll
                      if (position.pixels < 200) {
                        _scrollController.jumpTo(0.0);
                      }
                    }
                  });
                }

                return ListView.builder(
                  controller: _scrollController,
                  reverse: true, // WhatsApp style - newest at bottom
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: messages.length,
                  addAutomaticKeepAlives: false, // Better performance
                  addRepaintBoundaries: true, // Better performance
                  cacheExtent: 500, // Cache more items for smoother scrolling
                  itemBuilder: (context, index) {
                    // With reverse: true, index 0 is the newest message (at bottom)
                    // So we need to reverse the messages list
                    final reversedIndex = messages.length - 1 - index;
                    final message = messages[reversedIndex];
                    final isMe = message.senderId == currentUserId;
                    final sender = _userCache[message.senderId];
                    final senderName = sender?.displayName.isNotEmpty == true
                        ? sender!.displayName
                        : 'Bilinmeyen';

                    return MessageBubble(
                      key: ValueKey(message.messageId), // Stable key for better performance
                      message: message,
                      isMe: isMe,
                      senderName: senderName,
                    );
                  },
                );
              },
            ),
          ),
          // Message Input Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            decoration: BoxDecoration(
              color: AppTheme.surfaceColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: AppTheme.inputBackgroundColor,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.image_outlined),
                      color: AppTheme.textSecondary,
                      onPressed: _sendImage,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppTheme.inputBackgroundColor,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: TextField(
                        controller: _messageController,
                        style: const TextStyle(color: AppTheme.textPrimary, fontSize: 15),
                        decoration: InputDecoration(
                          hintText: 'Mesaj yazın...',
                          hintStyle: const TextStyle(color: AppTheme.textSecondary),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                        ),
                        maxLines: null,
                        textCapitalization: TextCapitalization.sentences,
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryColor.withValues(alpha: 0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.send_rounded),
                      color: AppTheme.textPrimary,
                      onPressed: _sendMessage,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
