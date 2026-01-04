enum AppThemeMode {
  system, // Sistem teması
  light, // Açık tema
  dark, // Karanlık tema
  blue, // Mavi tema
  pink, // Pembe tema
  red, // Kırmızı tema
  green, // Yeşil tema
  yellow, // Sarı tema
  gray, // Gri tema
}

extension AppThemeModeExtension on AppThemeMode {
  String get name {
    switch (this) {
      case AppThemeMode.system:
        return 'Sistem Teması';
      case AppThemeMode.light:
        return 'Açık Tema';
      case AppThemeMode.dark:
        return 'Karanlık Tema';
      case AppThemeMode.blue:
        return 'Mavi Tema';
      case AppThemeMode.pink:
        return 'Pembe Tema';
      case AppThemeMode.red:
        return 'Kırmızı Tema';
      case AppThemeMode.green:
        return 'Yeşil Tema';
      case AppThemeMode.yellow:
        return 'Sarı Tema';
      case AppThemeMode.gray:
        return 'Gri Tema';
    }
  }

  String get value {
    switch (this) {
      case AppThemeMode.system:
        return 'system';
      case AppThemeMode.light:
        return 'light';
      case AppThemeMode.dark:
        return 'dark';
      case AppThemeMode.blue:
        return 'blue';
      case AppThemeMode.pink:
        return 'pink';
      case AppThemeMode.red:
        return 'red';
      case AppThemeMode.green:
        return 'green';
      case AppThemeMode.yellow:
        return 'yellow';
      case AppThemeMode.gray:
        return 'gray';
    }
  }

  static AppThemeMode fromString(String value) {
    switch (value) {
      case 'system':
        return AppThemeMode.system;
      case 'light':
        return AppThemeMode.light;
      case 'dark':
        return AppThemeMode.dark;
      case 'blue':
        return AppThemeMode.blue;
      case 'pink':
        return AppThemeMode.pink;
      case 'red':
        return AppThemeMode.red;
      case 'green':
        return AppThemeMode.green;
      case 'yellow':
        return AppThemeMode.yellow;
      case 'gray':
        return AppThemeMode.gray;
      default:
        return AppThemeMode.system;
    }
  }
}

