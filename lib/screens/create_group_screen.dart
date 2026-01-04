import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../models/user_model.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_card.dart';
import '../widgets/custom_snackbar.dart';
import 'chat_screen.dart';

class CreateGroupScreen extends StatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final _nameController = TextEditingController();
  final _firestoreService = FirestoreService();
  final _authService = AuthService();
  final Set<String> _selectedFriends = {};

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _createGroup() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      CustomSnackBar.showError(context, 'Lütfen grup adı girin');
      return;
    }

    if (_selectedFriends.isEmpty) {
      CustomSnackBar.showError(context, 'Lütfen en az bir arkadaş seçin');
      return;
    }

    final currentUserId = _authService.currentUser?.uid;
    if (currentUserId == null || currentUserId.isEmpty) return;

    try {
      final members = [currentUserId, ..._selectedFriends];
      final chatId = await _firestoreService.createGroupChat(name, members);

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ChatScreen(chatId: chatId),
          ),
        );
      }
    } catch (e) {
      // Silently handle errors
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = _authService.currentUser?.uid;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Grup Oluştur'),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.primaryColor,
                  AppTheme.accentColor,
                ],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(Icons.check_rounded),
              onPressed: _createGroup,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _nameController,
              style: const TextStyle(color: AppTheme.textPrimary),
              decoration: InputDecoration(
                labelText: 'Grup Adı',
                prefixIcon: const Icon(Icons.group_rounded),
                prefixIconColor: AppTheme.textSecondary,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Arkadaş Seç',
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          Expanded(
            child: currentUserId == null || currentUserId.isEmpty
                ? const Center(
                    child: Text(
                      'Not authenticated',
                      style: TextStyle(color: AppTheme.textPrimary),
                    ),
                  )
                : FutureBuilder<List<UserModel>>(
                    future: _firestoreService.getFriends(currentUserId),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                          ),
                        );
                      }

                      final friends = snapshot.data ?? [];

                      if (friends.isEmpty) {
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
                                  Icons.people_outline_rounded,
                                  size: 40,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 24),
                              const Text(
                                'Henüz arkadaş yok',
                                style: TextStyle(
                                  color: AppTheme.textPrimary,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Önce arkadaş ekleyin',
                                style: TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: friends.length,
                        itemBuilder: (context, index) {
                          final friend = friends[index];
                          final isSelected = _selectedFriends.contains(friend.uid);

                          return CustomCard(
                            onTap: () {
                              setState(() {
                                if (isSelected) {
                                  _selectedFriends.remove(friend.uid);
                                } else {
                                  _selectedFriends.add(friend.uid);
                                }
                              });
                            },
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Container(
                                  width: 56,
                                  height: 56,
                                  decoration: BoxDecoration(
                                    gradient: isSelected
                                        ? LinearGradient(
                                            colors: [
                                              AppTheme.primaryColor,
                                              AppTheme.accentColor,
                                            ],
                                          )
                                        : null,
                                    color: isSelected
                                        ? null
                                        : AppTheme.primaryColor.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Center(
                                    child: Text(
                                      friend.username.isNotEmpty
                                          ? friend.username[0].toUpperCase()
                                          : 'U',
                                      style: TextStyle(
                                        color: isSelected
                                            ? AppTheme.textPrimary
                                            : AppTheme.primaryColor,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 20,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        friend.displayName.isNotEmpty
                                            ? friend.displayName
                                            : 'Bilinmeyen',
                                        style: const TextStyle(
                                          color: AppTheme.textPrimary,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        friend.email.isNotEmpty
                                            ? friend.email
                                            : 'Email yok',
                                        style: const TextStyle(
                                          color: AppTheme.textSecondary,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: isSelected
                                          ? AppTheme.primaryColor
                                          : AppTheme.dividerColor,
                                      width: 2,
                                    ),
                                    color: isSelected
                                        ? AppTheme.primaryColor
                                        : Colors.transparent,
                                  ),
                                  child: isSelected
                                      ? const Icon(
                                          Icons.check_rounded,
                                          size: 16,
                                          color: AppTheme.textPrimary,
                                        )
                                      : null,
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
