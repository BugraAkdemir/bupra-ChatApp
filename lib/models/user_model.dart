class UserModel {
  final String uid;
  final String username; // Base username (without #number)
  final String displayName; // Full display name (username#number)
  final String email;
  final String? photoUrl;
  final String? fcmToken; // Firebase Cloud Messaging token

  UserModel({
    required this.uid,
    required this.username,
    required this.displayName,
    required this.email,
    this.photoUrl,
    this.fcmToken,
  });

  factory UserModel.fromMap(Map<String, dynamic> map, String uid) {
    // Backward compatibility: if displayName doesn't exist, use username
    final displayName = map['displayName'] ?? map['username'] ?? '';
    return UserModel(
      uid: uid,
      username: map['username'] ?? '',
      displayName: displayName,
      email: map['email'] ?? '',
      photoUrl: map['photoUrl'],
      fcmToken: map['fcmToken'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'username': username,
      'displayName': displayName,
      'email': email,
      if (photoUrl != null) 'photoUrl': photoUrl,
      if (fcmToken != null) 'fcmToken': fcmToken,
    };
  }
}

