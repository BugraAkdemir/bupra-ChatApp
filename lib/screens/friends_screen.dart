import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../models/user_model.dart';
import 'chat_screen.dart';

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> {
  final _searchController = TextEditingController();
  final _firestoreService = FirestoreService();
  final _authService = AuthService();
  List<UserModel> _searchResults = [];
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Search failed: $e')),
        );
      }
    }
  }

  Future<void> _addFriend(String friendUid) async {
    final currentUserId = _authService.currentUser?.uid;
    if (currentUserId == null) return;

    try {
      await _firestoreService.addFriend(currentUserId, friendUid);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Friend added')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add friend: $e')),
        );
      }
    }
  }

  Future<void> _startChat(String friendUid) async {
    final currentUserId = _authService.currentUser?.uid;
    if (currentUserId == null) return;

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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to start chat: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = _authService.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Friends'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search by username',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: _searchUsers,
                ),
              ),
              onSubmitted: (_) => _searchUsers(),
            ),
          ),
          if (_isSearching)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(),
            )
          else if (_searchResults.isNotEmpty)
            Expanded(
              child: ListView.builder(
                itemCount: _searchResults.length,
                itemBuilder: (context, index) {
                  final user = _searchResults[index];
                  return ListTile(
                    leading: CircleAvatar(
                      child: Text(user.username[0].toUpperCase()),
                    ),
                    title: Text(user.username),
                    subtitle: Text(user.email),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.chat),
                          onPressed: () => _startChat(user.uid),
                        ),
                        IconButton(
                          icon: const Icon(Icons.person_add),
                          onPressed: () => _addFriend(user.uid),
                        ),
                      ],
                    ),
                  );
                },
              ),
            )
          else
            Expanded(
              child: StreamBuilder<List<String>>(
                stream: currentUserId != null
                    ? _firestoreService.getFriendsStream(currentUserId)
                    : null,
                builder: (context, friendsSnapshot) {
                  if (friendsSnapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final friendUids = friendsSnapshot.data ?? [];

                  if (friendUids.isEmpty) {
                    return const Center(
                      child: Text('No friends yet. Search to add friends.'),
                    );
                  }

                  return FutureBuilder<List<UserModel>>(
                    future: _firestoreService.getFriends(currentUserId!),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final friends = snapshot.data ?? [];

                      return ListView.builder(
                        itemCount: friends.length,
                        itemBuilder: (context, index) {
                          final friend = friends[index];
                          return ListTile(
                            leading: CircleAvatar(
                              child: Text(friend.username[0].toUpperCase()),
                            ),
                            title: Text(friend.username),
                            subtitle: Text(friend.email),
                            trailing: IconButton(
                              icon: const Icon(Icons.chat),
                              onPressed: () => _startChat(friend.uid),
                            ),
                          );
                        },
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

