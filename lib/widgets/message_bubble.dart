import 'package:flutter/material.dart';
import '../models/message_model.dart';
import '../theme/app_theme.dart';
import 'package:intl/intl.dart';

class MessageBubble extends StatefulWidget {
  final MessageModel message;
  final bool isMe;
  final String senderName; // Display name (username#number)

  const MessageBubble({
    super.key,
    required this.message,
    required this.isMe,
    required this.senderName,
  });

  @override
  State<MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<MessageBubble>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: Offset(widget.isMe ? 0.3 : -0.3, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    // Start animation
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // Extract base username from display name (bugra#1234 -> bugra)
  String _getBaseUsername(String displayName) {
    if (displayName.contains('#')) {
      return displayName.split('#')[0];
    }
    return displayName;
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            mainAxisAlignment:
                widget.isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!widget.isMe) ...[
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Text(
                      widget.senderName.isNotEmpty
                          ? _getBaseUsername(widget.senderName)[0].toUpperCase()
                          : 'U',
                      style: const TextStyle(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 280),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: widget.isMe
                        ? LinearGradient(
                            colors: [
                              AppTheme.primaryColor,
                              AppTheme.primaryColor.withValues(alpha: 0.8),
                            ],
                          )
                        : null,
                    color: widget.isMe ? null : AppTheme.receivedMessageColor,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(widget.isMe ? 16 : 4),
                      bottomRight: Radius.circular(widget.isMe ? 4 : 16),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment:
                        widget.isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                    children: [
                      if (!widget.isMe && widget.senderName.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Text(
                            widget.senderName,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.accentColor,
                            ),
                          ),
                        ),
                      if (widget.message.imageUrl != null && widget.message.imageUrl!.isNotEmpty)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            widget.message.imageUrl!,
                            width: 200,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Container(
                                width: 200,
                                height: 200,
                                color: AppTheme.surfaceColor,
                                child: const Center(
                                  child: CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        AppTheme.primaryColor),
                                  ),
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                width: 200,
                                height: 200,
                                color: AppTheme.surfaceColor,
                                child: const Icon(
                                  Icons.broken_image_rounded,
                                  color: AppTheme.textSecondary,
                                  size: 48,
                                ),
                              );
                            },
                          ),
                        ),
                      if (widget.message.text != null && widget.message.text!.isNotEmpty) ...[
                        if (widget.message.imageUrl != null && widget.message.imageUrl!.isNotEmpty)
                          const SizedBox(height: 8),
                        Text(
                          widget.message.text!,
                          style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 15,
                            height: 1.4,
                          ),
                        ),
                      ],
                      if ((widget.message.text == null || widget.message.text!.isEmpty) &&
                          (widget.message.imageUrl == null || widget.message.imageUrl!.isEmpty))
                        const Text(
                          'Mesaj',
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 14,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('HH:mm').format(widget.message.createdAt),
                        style: TextStyle(
                          fontSize: 11,
                          color: widget.isMe
                              ? AppTheme.textPrimary.withValues(alpha: 0.7)
                              : AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (widget.isMe) ...[
                const SizedBox(width: 8),
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.primaryColor,
                        AppTheme.accentColor,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Text(
                      widget.senderName.isNotEmpty
                          ? _getBaseUsername(widget.senderName)[0].toUpperCase()
                          : 'U',
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
