import 'package:flutter/material.dart';

class AppTheme {
  // Helper method to create theme
  static ThemeData _createTheme({
    required Color primaryColor,
    required Color backgroundColor,
    required Color surfaceColor,
    required Color accentColor,
    required Color textPrimary,
    required Color textSecondary,
    required Color errorColor,
    required Color successColor,
    required Color warningColor,
    required Color receivedMessageColor,
    required Color dividerColor,
    required Color inputBackgroundColor,
    required Brightness brightness,
  }) {
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: brightness == Brightness.dark
          ? ColorScheme.dark(
              primary: primaryColor,
              secondary: accentColor,
              surface: surfaceColor,
              background: backgroundColor,
              error: errorColor,
              onPrimary: textPrimary,
              onSecondary: textPrimary,
              onSurface: textPrimary,
              onBackground: textPrimary,
              onError: textPrimary,
            )
          : ColorScheme.light(
              primary: primaryColor,
              secondary: accentColor,
              surface: surfaceColor,
              background: backgroundColor,
              error: errorColor,
              onPrimary: textPrimary,
              onSecondary: textPrimary,
              onSurface: textPrimary,
              onBackground: textPrimary,
              onError: textPrimary,
            ),
      scaffoldBackgroundColor: backgroundColor,
      appBarTheme: AppBarTheme(
        backgroundColor: surfaceColor,
        foregroundColor: textPrimary,
        elevation: 0,
        centerTitle: false,
        surfaceTintColor: Colors.transparent,
        iconTheme: IconThemeData(color: textPrimary),
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: surfaceColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: inputBackgroundColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: dividerColor, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: errorColor, width: 1),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        hintStyle: TextStyle(color: textSecondary),
        labelStyle: TextStyle(color: textSecondary),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: textPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 0,
          shadowColor: Colors.transparent,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          side: BorderSide(color: dividerColor),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: accentColor,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primaryColor,
        foregroundColor: textPrimary,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: dividerColor,
        thickness: 1,
        space: 1,
      ),
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      textTheme: TextTheme(
        displayLarge: TextStyle(color: textPrimary, fontSize: 32, fontWeight: FontWeight.bold),
        displayMedium: TextStyle(color: textPrimary, fontSize: 28, fontWeight: FontWeight.bold),
        displaySmall: TextStyle(color: textPrimary, fontSize: 24, fontWeight: FontWeight.bold),
        headlineLarge: TextStyle(color: textPrimary, fontSize: 22, fontWeight: FontWeight.w600),
        headlineMedium: TextStyle(color: textPrimary, fontSize: 20, fontWeight: FontWeight.w600),
        headlineSmall: TextStyle(color: textPrimary, fontSize: 18, fontWeight: FontWeight.w600),
        titleLarge: TextStyle(color: textPrimary, fontSize: 16, fontWeight: FontWeight.w600),
        titleMedium: TextStyle(color: textPrimary, fontSize: 14, fontWeight: FontWeight.w600),
        titleSmall: TextStyle(color: textPrimary, fontSize: 12, fontWeight: FontWeight.w600),
        bodyLarge: TextStyle(color: textPrimary, fontSize: 16),
        bodyMedium: TextStyle(color: textPrimary, fontSize: 14),
        bodySmall: TextStyle(color: textSecondary, fontSize: 12),
        labelLarge: TextStyle(color: textPrimary, fontSize: 14, fontWeight: FontWeight.w500),
        labelMedium: TextStyle(color: textSecondary, fontSize: 12),
        labelSmall: TextStyle(color: textSecondary, fontSize: 10),
      ),
    );
  }

  // Dark Theme (Default Purple)
  static ThemeData get darkTheme {
    return _createTheme(
      primaryColor: const Color(0xFF8B5CF6),
      backgroundColor: const Color(0xFF1A1B23),
      surfaceColor: const Color(0xFF252631),
      accentColor: const Color(0xFFA78BFA),
      textPrimary: const Color(0xFFFFFFFF),
      textSecondary: const Color(0xFFB4B4C7),
      errorColor: const Color(0xFFF87171),
      successColor: const Color(0xFF34D399),
      warningColor: const Color(0xFFFBBF24),
      receivedMessageColor: const Color(0xFF2D2E3A),
      dividerColor: const Color(0xFF3A3B47),
      inputBackgroundColor: const Color(0xFF2A2B36),
      brightness: Brightness.dark,
    );
  }

  // Light Theme
  static ThemeData get lightTheme {
    return _createTheme(
      primaryColor: const Color(0xFF8B5CF6),
      backgroundColor: const Color(0xFFF5F5F5),
      surfaceColor: const Color(0xFFFFFFFF),
      accentColor: const Color(0xFFA78BFA),
      textPrimary: const Color(0xFF1A1B23),
      textSecondary: const Color(0xFF6B7280),
      errorColor: const Color(0xFFEF4444),
      successColor: const Color(0xFF10B981),
      warningColor: const Color(0xFFF59E0B),
      receivedMessageColor: const Color(0xFFE5E7EB),
      dividerColor: const Color(0xFFD1D5DB),
      inputBackgroundColor: const Color(0xFFFFFFFF),
      brightness: Brightness.light,
    );
  }

  // Blue Theme
  static ThemeData get blueTheme {
    return _createTheme(
      primaryColor: const Color(0xFF3B82F6),
      backgroundColor: const Color(0xFF1A1B23),
      surfaceColor: const Color(0xFF252631),
      accentColor: const Color(0xFF60A5FA),
      textPrimary: const Color(0xFFFFFFFF),
      textSecondary: const Color(0xFFB4B4C7),
      errorColor: const Color(0xFFF87171),
      successColor: const Color(0xFF34D399),
      warningColor: const Color(0xFFFBBF24),
      receivedMessageColor: const Color(0xFF2D2E3A),
      dividerColor: const Color(0xFF3A3B47),
      inputBackgroundColor: const Color(0xFF2A2B36),
      brightness: Brightness.dark,
    );
  }

  // Pink Theme
  static ThemeData get pinkTheme {
    return _createTheme(
      primaryColor: const Color(0xFFEC4899),
      backgroundColor: const Color(0xFF1A1B23),
      surfaceColor: const Color(0xFF252631),
      accentColor: const Color(0xFFF472B6),
      textPrimary: const Color(0xFFFFFFFF),
      textSecondary: const Color(0xFFB4B4C7),
      errorColor: const Color(0xFFF87171),
      successColor: const Color(0xFF34D399),
      warningColor: const Color(0xFFFBBF24),
      receivedMessageColor: const Color(0xFF2D2E3A),
      dividerColor: const Color(0xFF3A3B47),
      inputBackgroundColor: const Color(0xFF2A2B36),
      brightness: Brightness.dark,
    );
  }

  // Red Theme
  static ThemeData get redTheme {
    return _createTheme(
      primaryColor: const Color(0xFFEF4444),
      backgroundColor: const Color(0xFF1A1B23),
      surfaceColor: const Color(0xFF252631),
      accentColor: const Color(0xFFF87171),
      textPrimary: const Color(0xFFFFFFFF),
      textSecondary: const Color(0xFFB4B4C7),
      errorColor: const Color(0xFFF87171),
      successColor: const Color(0xFF34D399),
      warningColor: const Color(0xFFFBBF24),
      receivedMessageColor: const Color(0xFF2D2E3A),
      dividerColor: const Color(0xFF3A3B47),
      inputBackgroundColor: const Color(0xFF2A2B36),
      brightness: Brightness.dark,
    );
  }

  // Green Theme
  static ThemeData get greenTheme {
    return _createTheme(
      primaryColor: const Color(0xFF10B981),
      backgroundColor: const Color(0xFF1A1B23),
      surfaceColor: const Color(0xFF252631),
      accentColor: const Color(0xFF34D399),
      textPrimary: const Color(0xFFFFFFFF),
      textSecondary: const Color(0xFFB4B4C7),
      errorColor: const Color(0xFFF87171),
      successColor: const Color(0xFF34D399),
      warningColor: const Color(0xFFFBBF24),
      receivedMessageColor: const Color(0xFF2D2E3A),
      dividerColor: const Color(0xFF3A3B47),
      inputBackgroundColor: const Color(0xFF2A2B36),
      brightness: Brightness.dark,
    );
  }

  // Yellow Theme
  static ThemeData get yellowTheme {
    return _createTheme(
      primaryColor: const Color(0xFFFBBF24),
      backgroundColor: const Color(0xFF1A1B23),
      surfaceColor: const Color(0xFF252631),
      accentColor: const Color(0xFFFCD34D),
      textPrimary: const Color(0xFFFFFFFF),
      textSecondary: const Color(0xFFB4B4C7),
      errorColor: const Color(0xFFF87171),
      successColor: const Color(0xFF34D399),
      warningColor: const Color(0xFFFBBF24),
      receivedMessageColor: const Color(0xFF2D2E3A),
      dividerColor: const Color(0xFF3A3B47),
      inputBackgroundColor: const Color(0xFF2A2B36),
      brightness: Brightness.dark,
    );
  }

  // Gray Theme
  static ThemeData get grayTheme {
    return _createTheme(
      primaryColor: const Color(0xFF6B7280),
      backgroundColor: const Color(0xFF1A1B23),
      surfaceColor: const Color(0xFF252631),
      accentColor: const Color(0xFF9CA3AF),
      textPrimary: const Color(0xFFFFFFFF),
      textSecondary: const Color(0xFFB4B4C7),
      errorColor: const Color(0xFFF87171),
      successColor: const Color(0xFF34D399),
      warningColor: const Color(0xFFFBBF24),
      receivedMessageColor: const Color(0xFF2D2E3A),
      dividerColor: const Color(0xFF3A3B47),
      inputBackgroundColor: const Color(0xFF2A2B36),
      brightness: Brightness.dark,
    );
  }

  // Static color constants for backward compatibility (const for use in const widgets)
  static const Color primaryColor = Color(0xFF8B5CF6);
  static const Color backgroundColor = Color(0xFF1A1B23);
  static const Color surfaceColor = Color(0xFF252631);
  static const Color accentColor = Color(0xFFA78BFA);
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB4B4C7);
  static const Color errorColor = Color(0xFFF87171);
  static const Color successColor = Color(0xFF34D399);
  static const Color warningColor = Color(0xFFFBBF24);
  static const Color sentMessageColor = Color(0xFF8B5CF6);
  static const Color receivedMessageColor = Color(0xFF2D2E3A);
  static const Color chatBackgroundColor = Color(0xFF1E1F2A);
  static const Color dividerColor = Color(0xFF3A3B47);
  static const Color inputBackgroundColor = Color(0xFF2A2B36);
}
