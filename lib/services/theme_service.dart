import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/theme_model.dart';
import '../theme/app_theme.dart';

class ThemeService extends ChangeNotifier {
  static ThemeService? _instance;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  AppThemeMode _currentTheme = AppThemeMode.system;
  ThemeData? _currentThemeData;

  AppThemeMode get currentTheme => _currentTheme;
  ThemeData get themeData => _currentThemeData ?? AppTheme.darkTheme;

  // Singleton pattern
  factory ThemeService() {
    _instance ??= ThemeService._internal();
    return _instance!;
  }

  ThemeService._internal() {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        _applyTheme(AppThemeMode.system);
        return;
      }

      final prefsDoc = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('preferences')
          .doc('theme')
          .get();

      if (prefsDoc.exists) {
        final themeValue = prefsDoc.data()?['theme'] as String?;
        if (themeValue != null) {
          _currentTheme = AppThemeModeExtension.fromString(themeValue);
        }
      }

      _applyTheme(_currentTheme);
    } catch (e) {
      _applyTheme(AppThemeMode.system);
    }
  }

  Future<void> setTheme(AppThemeMode theme) async {
    if (_currentTheme == theme) return;

    _currentTheme = theme;
    _applyTheme(theme);

    try {
      final user = _auth.currentUser;
      if (user != null) {
        await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('preferences')
            .doc('theme')
            .set({
          'theme': theme.value,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
    } catch (e) {
      // Silently handle errors
    }

    notifyListeners();
  }

  void _applyTheme(AppThemeMode theme) {
    _currentThemeData = _getThemeData(theme);
    notifyListeners();
  }

  ThemeData _getThemeData(AppThemeMode theme) {
    switch (theme) {
      case AppThemeMode.system:
        // Sistem teması için varsayılan olarak karanlık tema kullan
        return AppTheme.darkTheme;
      case AppThemeMode.light:
        return AppTheme.lightTheme;
      case AppThemeMode.dark:
        return AppTheme.darkTheme;
      case AppThemeMode.blue:
        return AppTheme.blueTheme;
      case AppThemeMode.pink:
        return AppTheme.pinkTheme;
      case AppThemeMode.red:
        return AppTheme.redTheme;
      case AppThemeMode.green:
        return AppTheme.greenTheme;
      case AppThemeMode.yellow:
        return AppTheme.yellowTheme;
      case AppThemeMode.gray:
        return AppTheme.grayTheme;
    }
  }
}

