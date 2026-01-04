import 'package:flutter/material.dart';
import '../models/theme_model.dart';
import '../services/theme_service.dart';
import '../widgets/custom_card.dart';

class ThemeSettingsScreen extends StatefulWidget {
  const ThemeSettingsScreen({super.key});

  @override
  State<ThemeSettingsScreen> createState() => _ThemeSettingsScreenState();
}

class _ThemeSettingsScreenState extends State<ThemeSettingsScreen> {
  late final ThemeService _themeService;
  AppThemeMode _selectedTheme = AppThemeMode.system;

  @override
  void initState() {
    super.initState();
    _themeService = ThemeService(); // Singleton, aynı instance döner
    _selectedTheme = _themeService.currentTheme;
    _themeService.addListener(_onThemeChanged);
  }

  @override
  void dispose() {
    _themeService.removeListener(_onThemeChanged);
    super.dispose();
  }

  void _onThemeChanged() {
    setState(() {
      _selectedTheme = _themeService.currentTheme;
    });
  }

  Future<void> _selectTheme(AppThemeMode theme) async {
    await _themeService.setTheme(theme);
  }

  Color _getThemeColor(AppThemeMode theme) {
    switch (theme) {
      case AppThemeMode.system:
        return Colors.grey;
      case AppThemeMode.light:
        return Colors.white;
      case AppThemeMode.dark:
        return const Color(0xFF8B5CF6);
      case AppThemeMode.blue:
        return const Color(0xFF3B82F6);
      case AppThemeMode.pink:
        return const Color(0xFFEC4899);
      case AppThemeMode.red:
        return const Color(0xFFEF4444);
      case AppThemeMode.green:
        return const Color(0xFF10B981);
      case AppThemeMode.yellow:
        return const Color(0xFFFBBF24);
      case AppThemeMode.gray:
        return const Color(0xFF6B7280);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final backgroundColor = theme.scaffoldBackgroundColor;
    final surfaceColor = theme.cardTheme.color ?? theme.colorScheme.surface;
    final textPrimary = theme.colorScheme.onSurface;
    final textSecondary = theme.colorScheme.onSurface.withOpacity(0.6);
    final primaryColor = theme.colorScheme.primary;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text('Tema Ayarları'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 16),
            // System Theme
            _buildThemeOption(
              theme: AppThemeMode.system,
              icon: Icons.brightness_auto_rounded,
              backgroundColor: backgroundColor,
              surfaceColor: surfaceColor,
              textPrimary: textPrimary,
              textSecondary: textSecondary,
              primaryColor: primaryColor,
            ),
            const SizedBox(height: 8),
            // Light Theme
            _buildThemeOption(
              theme: AppThemeMode.light,
              icon: Icons.light_mode_rounded,
              backgroundColor: backgroundColor,
              surfaceColor: surfaceColor,
              textPrimary: textPrimary,
              textSecondary: textSecondary,
              primaryColor: primaryColor,
            ),
            const SizedBox(height: 8),
            // Dark Theme
            _buildThemeOption(
              theme: AppThemeMode.dark,
              icon: Icons.dark_mode_rounded,
              backgroundColor: backgroundColor,
              surfaceColor: surfaceColor,
              textPrimary: textPrimary,
              textSecondary: textSecondary,
              primaryColor: primaryColor,
            ),
            const SizedBox(height: 24),
            // Custom Themes Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Harici Temalar',
                style: TextStyle(
                  color: textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            const SizedBox(height: 8),
            // Blue Theme
            _buildThemeOption(
              theme: AppThemeMode.blue,
              icon: Icons.palette_rounded,
              backgroundColor: backgroundColor,
              surfaceColor: surfaceColor,
              textPrimary: textPrimary,
              textSecondary: textSecondary,
              primaryColor: primaryColor,
            ),
            const SizedBox(height: 8),
            // Pink Theme
            _buildThemeOption(
              theme: AppThemeMode.pink,
              icon: Icons.palette_rounded,
              backgroundColor: backgroundColor,
              surfaceColor: surfaceColor,
              textPrimary: textPrimary,
              textSecondary: textSecondary,
              primaryColor: primaryColor,
            ),
            const SizedBox(height: 8),
            // Red Theme
            _buildThemeOption(
              theme: AppThemeMode.red,
              icon: Icons.palette_rounded,
              backgroundColor: backgroundColor,
              surfaceColor: surfaceColor,
              textPrimary: textPrimary,
              textSecondary: textSecondary,
              primaryColor: primaryColor,
            ),
            const SizedBox(height: 8),
            // Green Theme
            _buildThemeOption(
              theme: AppThemeMode.green,
              icon: Icons.palette_rounded,
              backgroundColor: backgroundColor,
              surfaceColor: surfaceColor,
              textPrimary: textPrimary,
              textSecondary: textSecondary,
              primaryColor: primaryColor,
            ),
            const SizedBox(height: 8),
            // Yellow Theme
            _buildThemeOption(
              theme: AppThemeMode.yellow,
              icon: Icons.palette_rounded,
              backgroundColor: backgroundColor,
              surfaceColor: surfaceColor,
              textPrimary: textPrimary,
              textSecondary: textSecondary,
              primaryColor: primaryColor,
            ),
            const SizedBox(height: 8),
            // Gray Theme
            _buildThemeOption(
              theme: AppThemeMode.gray,
              icon: Icons.palette_rounded,
              backgroundColor: backgroundColor,
              surfaceColor: surfaceColor,
              textPrimary: textPrimary,
              textSecondary: textSecondary,
              primaryColor: primaryColor,
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeOption({
    required AppThemeMode theme,
    required IconData icon,
    required Color backgroundColor,
    required Color surfaceColor,
    required Color textPrimary,
    required Color textSecondary,
    required Color primaryColor,
  }) {
    final isSelected = _selectedTheme == theme;
    final themeColor = _getThemeColor(theme);

    return CustomCard(
      onTap: () => _selectTheme(theme),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: themeColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: themeColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  theme.name,
                  style: TextStyle(
                    color: textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  _getThemeDescription(theme),
                  style: TextStyle(
                    color: textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          if (isSelected)
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: primaryColor,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check,
                color: Colors.white,
                size: 16,
              ),
            ),
        ],
      ),
    );
  }

  String _getThemeDescription(AppThemeMode theme) {
    switch (theme) {
      case AppThemeMode.system:
        return 'Cihaz ayarlarını kullan';
      case AppThemeMode.light:
        return 'Açık renk teması';
      case AppThemeMode.dark:
        return 'Karanlık renk teması';
      case AppThemeMode.blue:
        return 'Mavi renk teması';
      case AppThemeMode.pink:
        return 'Pembe renk teması';
      case AppThemeMode.red:
        return 'Kırmızı renk teması';
      case AppThemeMode.green:
        return 'Yeşil renk teması';
      case AppThemeMode.yellow:
        return 'Sarı renk teması';
      case AppThemeMode.gray:
        return 'Gri renk teması';
    }
  }
}

