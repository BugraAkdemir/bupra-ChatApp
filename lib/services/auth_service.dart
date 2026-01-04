import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Random _random = Random();

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Auth state stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign in with email and password
  Future<UserModel?> signInWithEmail(String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final userModel = await _getUserData(credential.user!.uid);

      // FCM token will be saved by NotificationService after initialization
      // No need to save it here as it's handled in main.dart

      return userModel;
    } catch (e) {
      throw Exception('Sign in failed: $e');
    }
  }

  // Sign up with email and password
  // Discord-style: Username can be duplicate, system assigns unique number
  // Format: username#1234 (e.g., bugra#1234, bugra#1256)
  Future<UserModel?> signUpWithEmail(
    String email,
    String password,
    String username,
  ) async {
    UserCredential? credential;

    try {
      // Trim and validate username
      final trimmedUsername = username.trim();
      if (trimmedUsername.isEmpty) {
        throw Exception('Kullanıcı adı boş olamaz');
      }

      // Validate username format (no # allowed in base username)
      if (trimmedUsername.length < 3) {
        throw Exception('Kullanıcı adı en az 3 karakter olmalı');
      }
      if (trimmedUsername.length > 20) {
        throw Exception('Kullanıcı adı en fazla 20 karakter olabilir');
      }
      if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(trimmedUsername)) {
        throw Exception('Kullanıcı adı sadece harf, rakam ve alt çizgi içerebilir');
      }
      if (trimmedUsername.contains('#')) {
        throw Exception('Kullanıcı adı # karakteri içeremez');
      }

      // Check if email already exists
      final emailExists = await _checkEmailExists(email);
      if (emailExists) {
        throw Exception('Bu email adresi zaten kullanılıyor');
      }

      // Create Firebase Auth user FIRST (needed for Firestore permissions)
      credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final uid = credential.user!.uid;

      // Generate unique display name AFTER Auth user is created
      // Now request.auth != null, so we can read displayNames collection
      final displayName = await _generateUniqueDisplayName(trimmedUsername);
      if (displayName == null) {
        // If we can't generate a display name, delete the Auth user
        await credential.user?.delete();
        throw Exception('Kullanıcı adı oluşturulamadı. Lütfen tekrar deneyin.');
      }

      // Use Firestore Transaction to atomically create user
      await _firestore.runTransaction((transaction) async {
        // Check if display name is still available (race condition protection)
        final displayNameRef = _firestore
            .collection('displayNames')
            .doc(displayName.toLowerCase());

        final displayNameDoc = await transaction.get(displayNameRef);

        // If display name document exists, it means it was taken between check and transaction
        // This is very rare but possible in race conditions
        if (displayNameDoc.exists) {
          // Delete the Firebase Auth user we just created
          await credential?.user?.delete();
          throw Exception('Kullanıcı adı oluşturulamadı. Lütfen tekrar deneyin.');
        }

        // Display name is available - reserve it atomically
        transaction.set(displayNameRef, {
          'uid': uid,
          'displayName': displayName,
          'createdAt': FieldValue.serverTimestamp(),
        });

        // Create user document
        final userRef = _firestore.collection('users').doc(uid);
        final userModel = UserModel(
          uid: uid,
          username: trimmedUsername,
          displayName: displayName,
          email: email.trim(),
        );
        transaction.set(userRef, userModel.toMap());
      });

      // Return user model
      return UserModel(
        uid: uid,
        username: trimmedUsername,
        displayName: displayName,
        email: email.trim(),
      );
    } on FirebaseAuthException catch (e) {
      // If Auth user was created but something failed, delete it
      if (credential?.user != null) {
        try {
          await credential!.user?.delete();
        } catch (_) {
          // Ignore deletion errors
        }
      }

      if (e.code == 'email-already-in-use') {
        throw Exception('Bu email adresi zaten kullanılıyor');
      }
      throw Exception('Kayıt başarısız: ${e.message}');
    } catch (e) {
      // If Auth user was created but something failed, delete it
      if (credential?.user != null) {
        try {
          await credential!.user?.delete();
        } catch (_) {
          // Ignore deletion errors
        }
      }

      // Re-throw if it's already our custom exception
      if (e.toString().contains('kullanıcı adı') ||
          e.toString().contains('email adresi')) {
        rethrow;
      }
      throw Exception('Kayıt başarısız: $e');
    }
  }

  // Generate unique display name (username#number)
  // Tries up to 10 times to find an available number
  Future<String?> _generateUniqueDisplayName(String baseUsername) async {
    const maxAttempts = 10;

    for (int attempt = 0; attempt < maxAttempts; attempt++) {
      // Generate random 4-digit number (1000-9999)
      final number = 1000 + _random.nextInt(9000);
      final displayName = '$baseUsername#$number';
      final normalizedDisplayName = displayName.toLowerCase();

      // Check if this display name is available
      final displayNameDoc = await _firestore
          .collection('displayNames')
          .doc(normalizedDisplayName)
          .get();

      if (!displayNameDoc.exists) {
        return displayName;
      }
    }

    // If we couldn't find an available number after max attempts, return null
    return null;
  }

  // Check if email exists in Firestore
  Future<bool> _checkEmailExists(String email) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .where('email', isEqualTo: email.trim())
          .limit(1)
          .get();
      return snapshot.docs.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  // Get user data
  Future<UserModel?> _getUserData(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return UserModel.fromMap(doc.data()!, uid);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get user data: $e');
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Re-authenticate user with email and password
  Future<UserCredential?> reauthenticateWithEmail(
    String email,
    String password,
  ) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('Kullanıcı bulunamadı');
      }

      // Create credential
      final credential = EmailAuthProvider.credential(
        email: email,
        password: password,
      );

      // Re-authenticate
      final result = await user.reauthenticateWithCredential(credential);
      return result;
    } catch (e) {
      if (e is FirebaseAuthException) {
        if (e.code == 'wrong-password') {
          throw Exception('Şifre yanlış');
        } else if (e.code == 'user-mismatch') {
          throw Exception('Kullanıcı eşleşmiyor');
        } else if (e.code == 'user-not-found') {
          throw Exception('Kullanıcı bulunamadı');
        } else if (e.code == 'invalid-credential') {
          throw Exception('Geçersiz kimlik bilgileri');
        }
      }
      throw Exception('Kimlik doğrulama başarısız: $e');
    }
  }

  // Delete user account
  Future<void> deleteAccount() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('Kullanıcı bulunamadı');
      }

      final uid = user.uid;

      // Delete user data from Firestore
      await _deleteUserData(uid);

      // Delete Firebase Auth user
      await user.delete();
    } catch (e) {
      if (e is FirebaseAuthException) {
        if (e.code == 'requires-recent-login') {
          throw Exception('Bu işlem için tekrar giriş yapmanız gerekiyor');
        }
      }
      throw Exception('Hesap silme başarısız: $e');
    }
  }

  // Delete all user data from Firestore
  Future<void> _deleteUserData(String uid) async {
    try {
      // Get user document to find displayName
      final userDoc = await _firestore.collection('users').doc(uid).get();
      if (userDoc.exists) {
        final userData = userDoc.data();
        final displayName = userData?['displayName'] as String?;

        // Delete displayName document if exists
        if (displayName != null && displayName.isNotEmpty) {
          final normalizedDisplayName = displayName.toLowerCase();
          await _firestore
              .collection('displayNames')
              .doc(normalizedDisplayName)
              .delete();
        }

        // Delete user document
        await _firestore.collection('users').doc(uid).delete();
      }

      // Delete user's friends collection
      final friendsSnapshot = await _firestore
          .collection('friends')
          .doc(uid)
          .collection('friends')
          .get();

      final batch = _firestore.batch();
      for (var doc in friendsSnapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      // Delete friends collection document
      await _firestore.collection('friends').doc(uid).delete();

      // Note: We don't delete chats and messages as they might be needed by other users
      // The user will be removed from chat members, but chat history remains
    } catch (e) {
      // Log error but don't throw - we still want to delete Auth user
      // In production, you might want to log this to a monitoring service
    }
  }
}
