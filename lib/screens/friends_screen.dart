import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../models/user_model.dart';
import '../models/friend_request_model.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_card.dart';
import '../widgets/custom_snackbar.dart';
import 'chat_screen.dart';

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> with SingleTickerProviderStateMixin {
  final _searchController = TextEditingController();
  final _firestoreService = FirestoreService();
  final _authService = AuthService();
  List<UserModel> _searchResults = [];
  bool _isSearching = false;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _searchUsers() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() => _isSearching = true);

    try {
      final results = await _firestoreService.searchUsers(query);
      final currentUserId = _authService.currentUser?.uid;

      setState(() {
        _searchResults = results
            .where((user) => user.uid != currentUserId)
            .toList();
        _isSearching = false;
      });
    } catch (e) {
      setState(() => _isSearching = false);
      // Silently handle errors
    }
  }

  Future<void> _sendFriendRequest(String receiverUid) async {
    final currentUserId = _authService.currentUser?.uid;
    if (currentUserId == null || currentUserId.isEmpty) return;

    try {
      await _firestoreService.sendFriendRequest(currentUserId, receiverUid);
      if (mounted) {
        CustomSnackBar.showSuccess(context, 'Arkadaşlık isteği gönderildi');
      }
    } catch (e) {
      // Silently handle errors
    }
  }

  Future<void> _startChat(String friendUid) async {
    final currentUserId = _authService.currentUser?.uid;
    if (currentUserId == null || currentUserId.isEmpty) return;

    try {
      final chatId = await _firestoreService.createOneToOneChat(
        currentUserId,
        friendUid,
      );

      if (mounted) {
        Navigator.push(
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
        title: const Text('Arkadaşlar'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Arkadaşlar'),
            Tab(text: 'İstekler'),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: AppTheme.textPrimary),
              decoration: InputDecoration(
                labelText: 'Kullanıcı adı ile ara',
                prefixIcon: const Icon(Icons.search_rounded),
                prefixIconColor: AppTheme.textSecondary,
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        color: AppTheme.textSecondary,
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchResults = [];
                          });
                        },
                      )
                    : null,
              ),
              onSubmitted: (_) => _searchUsers(),
              onChanged: (value) {
                setState(() {});
              },
            ),
          ),
          if (_isSearching)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
              ),
            )
          else if (_searchResults.isNotEmpty)
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: _searchResults.length,
                itemBuilder: (context, index) {
                  final user = _searchResults[index];
                  return CustomCard(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Center(
                            child: Text(
                              user.username.isNotEmpty
                                  ? user.username[0].toUpperCase()
                                  : 'U',
                              style: const TextStyle(
                                color: AppTheme.primaryColor,
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
                                user.displayName.isNotEmpty ? user.displayName : 'Bilinmeyen',
                                style: const TextStyle(
                                  color: AppTheme.textPrimary,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                user.email.isNotEmpty ? user.email : 'Email yok',
                                style: const TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color: AppTheme.backgroundColor,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: IconButton(
                                icon: const Icon(Icons.chat_bubble_outline_rounded),
                                color: AppTheme.primaryColor,
                                onPressed: () => _startChat(user.uid),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              decoration: BoxDecoration(
                                color: AppTheme.backgroundColor,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: IconButton(
                                icon: const Icon(Icons.person_add_outlined),
                                color: AppTheme.accentColor,
                                onPressed: () => _sendFriendRequest(user.uid),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            )
          else
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Friends Tab
                  _buildFriendsTab(currentUserId),
                  // Requests Tab
                  _buildRequestsTab(currentUserId),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFriendsTab(String? currentUserId) {
    return StreamBuilder<List<String>>(
      stream: currentUserId != null && currentUserId.isNotEmpty
          ? _firestoreService.getFriendsStream(currentUserId)
          : null,
      builder: (context, friendsSnapshot) {
                  if (friendsSnapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                      ),
                    );
                  }

                  final friendUids = friendsSnapshot.data ?? [];

                  if (friendUids.isEmpty) {
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
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 48),
                            child: Text(
                              'Yukarıdan arama yaparak arkadaş ekleyin',
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

                  return FutureBuilder<List<UserModel>>(
                    future: _firestoreService.getFriends(currentUserId!),
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

                      return ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: friends.length,
                        itemBuilder: (context, index) {
                          final friend = friends[index];
                          return CustomCard(
                            onTap: () => _startChat(friend.uid),
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Container(
                                  width: 56,
                                  height: 56,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        AppTheme.primaryColor,
                                        AppTheme.accentColor,
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Center(
                                    child: Text(
                                      friend.username.isNotEmpty
                                          ? friend.username[0].toUpperCase()
                                          : 'U',
                                      style: const TextStyle(
                                        color: AppTheme.textPrimary,
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
                                  decoration: BoxDecoration(
                                    color: AppTheme.backgroundColor,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: IconButton(
                                    icon: const Icon(Icons.chat_bubble_outline_rounded),
                                    color: AppTheme.primaryColor,
                                    onPressed: () => _startChat(friend.uid),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              );
  }

  Widget _buildRequestsTab(String? currentUserId) {
    if (currentUserId == null || currentUserId.isEmpty) {
      return const Center(
        child: Text(
          'Giriş yapmanız gerekiyor',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
      );
    }

    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          TabBar(
            tabs: const [
              Tab(text: 'Gelen İstekler'),
              Tab(text: 'Giden İstekler'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                // Incoming Requests
                StreamBuilder<List<FriendRequestModel>>(
                  stream: _firestoreService.getIncomingRequests(currentUserId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                        ),
                      );
                    }

                    if (snapshot.hasError) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.error_outline,
                              size: 48,
                              color: AppTheme.errorColor,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Hata: ${snapshot.error}',
                              style: const TextStyle(color: AppTheme.textSecondary),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            TextButton(
                              onPressed: () {
                                // Retry by rebuilding
                                setState(() {});
                              },
                              child: const Text('Tekrar Dene'),
                            ),
                          ],
                        ),
                      );
                    }

                    final requests = snapshot.data ?? [];

                    if (requests.isEmpty) {
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
                                Icons.person_add_outlined,
                                size: 40,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 24),
                            const Text(
                              'Gelen istek yok',
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

                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: requests.length,
                      itemBuilder: (context, index) {
                        final request = requests[index];
                        return CustomCard(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryColor.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Center(
                                  child: Text(
                                    request.senderDisplayName.isNotEmpty
                                        ? request.senderDisplayName[0].toUpperCase()
                                        : 'U',
                                    style: const TextStyle(
                                      color: AppTheme.primaryColor,
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
                                      request.senderDisplayName,
                                      style: const TextStyle(
                                        color: AppTheme.textPrimary,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    const Text(
                                      'Arkadaşlık isteği gönderdi',
                                      style: TextStyle(
                                        color: AppTheme.textSecondary,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                      color: AppTheme.successColor.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: IconButton(
                                      icon: const Icon(Icons.check_rounded),
                                      color: AppTheme.successColor,
                                      onPressed: () => _acceptRequest(request.requestId, currentUserId),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    decoration: BoxDecoration(
                                      color: AppTheme.errorColor.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: IconButton(
                                      icon: const Icon(Icons.close_rounded),
                                      color: AppTheme.errorColor,
                                      onPressed: () => _rejectRequest(request.requestId, currentUserId),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
                // Outgoing Requests
                StreamBuilder<List<FriendRequestModel>>(
                  stream: _firestoreService.getOutgoingRequests(currentUserId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                        ),
                      );
                    }

                    if (snapshot.hasError) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.error_outline,
                              size: 48,
                              color: AppTheme.errorColor,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Hata: ${snapshot.error}',
                              style: const TextStyle(color: AppTheme.textSecondary),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            TextButton(
                              onPressed: () {
                                // Retry by rebuilding
                                setState(() {});
                              },
                              child: const Text('Tekrar Dene'),
                            ),
                          ],
                        ),
                      );
                    }

                    final requests = snapshot.data ?? [];

                    if (requests.isEmpty) {
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
                                Icons.send_outlined,
                                size: 40,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 24),
                            const Text(
                              'Giden istek yok',
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

                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: requests.length,
                      itemBuilder: (context, index) {
                        final request = requests[index];
                        return CustomCard(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryColor.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Center(
                                  child: FutureBuilder<UserModel?>(
                                    future: _firestoreService.getUser(request.receiverId),
                                    builder: (context, userSnapshot) {
                                      final displayName = userSnapshot.data?.displayName ?? 'Bilinmeyen';
                                      return Text(
                                        displayName.isNotEmpty
                                            ? displayName[0].toUpperCase()
                                            : 'U',
                                        style: const TextStyle(
                                          color: AppTheme.primaryColor,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 20,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    FutureBuilder<UserModel?>(
                                      future: _firestoreService.getUser(request.receiverId),
                                      builder: (context, userSnapshot) {
                                        final displayName = userSnapshot.data?.displayName ?? 'Bilinmeyen';
                                        return Text(
                                          displayName,
                                          style: const TextStyle(
                                            color: AppTheme.textPrimary,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        );
                                      },
                                    ),
                                    const SizedBox(height: 4),
                                    const Text(
                                      'Beklemede',
                                      style: TextStyle(
                                        color: AppTheme.textSecondary,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                decoration: BoxDecoration(
                                  color: AppTheme.errorColor.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: IconButton(
                                  icon: const Icon(Icons.cancel_outlined),
                                  color: AppTheme.errorColor,
                                  onPressed: () => _cancelRequest(request.requestId, currentUserId),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _acceptRequest(String requestId, String userId) async {
    try {
      await _firestoreService.acceptFriendRequest(requestId, userId);
      if (mounted) {
        CustomSnackBar.showSuccess(context, 'Arkadaşlık isteği kabul edildi');
      }
    } catch (e) {
      // Silently handle errors
    }
  }

  Future<void> _rejectRequest(String requestId, String userId) async {
    try {
      await _firestoreService.rejectFriendRequest(requestId, userId);
      if (mounted) {
        CustomSnackBar.showInfo(context, 'Arkadaşlık isteği reddedildi');
      }
    } catch (e) {
      // Silently handle errors
    }
  }

  Future<void> _cancelRequest(String requestId, String userId) async {
    try {
      await _firestoreService.cancelFriendRequest(requestId, userId);
      if (mounted) {
        CustomSnackBar.showInfo(context, 'Arkadaşlık isteği iptal edildi');
      }
    } catch (e) {
      // Silently handle errors
    }
  }
}
