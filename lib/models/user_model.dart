class UserModel {
  final String uid;
  final String username;
  final String email;
  final String? photoUrl;

  UserModel({
    required this.uid,
    required this.username,
    required this.email,
    this.photoUrl,
  });

  factory UserModel.fromMap(Map<String, dynamic> map, String uid) {
    return UserModel(
      uid: uid,
      username: map['username'] ?? '',
      email: map['email'] ?? '',
      photoUrl: map['photoUrl'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'username': username,
      'email': email,
      if (photoUrl != null) 'photoUrl': photoUrl,
    };
  }
}

