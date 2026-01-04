import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../models/user_model.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_snackbar.dart';

class EditProfileScreen extends StatefulWidget {
  final UserModel user;

  const EditProfileScreen({super.key, required this.user});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _firestoreService = FirestoreService();
  final _authService = AuthService();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Extract base username from displayName (bugra#1234 -> bugra)
    final baseUsername = widget.user.displayName.contains('#')
        ? widget.user.displayName.split('#')[0]
        : widget.user.username;
    _usernameController.text = baseUsername;
  }

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final newUsername = _usernameController.text.trim();
    final currentBaseUsername = widget.user.displayName.contains('#')
        ? widget.user.displayName.split('#')[0]
        : widget.user.username;

    // Check if username actually changed
    if (newUsername.toLowerCase() == currentBaseUsername.toLowerCase()) {
      if (mounted) {
        Navigator.pop(context);
      }
      return;
    }

    setState(() => _isLoading = true);

    try {
      final currentUserId = _authService.currentUser?.uid;
      if (currentUserId == null) {
        throw Exception('Kullanıcı kimliği bulunamadı');
      }

      // Generate new display name with same number
      final currentNumber = widget.user.displayName.contains('#')
          ? widget.user.displayName.split('#')[1]
          : '';
      final newDisplayName = currentNumber.isNotEmpty
          ? '$newUsername#$currentNumber'
          : newUsername;

      // Update user document (includes displayName availability check)
      await _firestoreService.updateUserProfile(
        currentUserId,
        newUsername,
        newDisplayName,
      );

      if (mounted) {
        CustomSnackBar.showSuccess(context, 'Profil güncellendi');
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        CustomSnackBar.showError(context, e.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Bilgilerimi Düzenle'),
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                ),
              ),
            )
          else
            TextButton(
              onPressed: _saveProfile,
              child: const Text(
                'Kaydet',
                style: TextStyle(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              // Display Name (Read-only)
              TextFormField(
                initialValue: widget.user.displayName,
                style: const TextStyle(color: AppTheme.textSecondary),
                decoration: InputDecoration(
                  labelText: 'Görünen Ad',
                  labelStyle: const TextStyle(color: AppTheme.textSecondary),
                  prefixIcon: const Icon(Icons.badge_outlined),
                  prefixIconColor: AppTheme.textSecondary,
                  enabled: false,
                  helperText: 'Görünen ad otomatik olarak oluşturulur',
                  helperStyle: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                ),
              ),
              const SizedBox(height: 24),
              // Email (Read-only)
              TextFormField(
                initialValue: widget.user.email,
                style: const TextStyle(color: AppTheme.textSecondary),
                decoration: InputDecoration(
                  labelText: 'Email',
                  labelStyle: const TextStyle(color: AppTheme.textSecondary),
                  prefixIcon: const Icon(Icons.email_outlined),
                  prefixIconColor: AppTheme.textSecondary,
                  enabled: false,
                  helperText: 'Email adresi değiştirilemez',
                  helperStyle: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                ),
              ),
              const SizedBox(height: 24),
              // Username (Editable)
              TextFormField(
                controller: _usernameController,
                style: const TextStyle(color: AppTheme.textPrimary),
                decoration: InputDecoration(
                  labelText: 'Kullanıcı Adı',
                  prefixIcon: const Icon(Icons.person_outline),
                  prefixIconColor: AppTheme.textSecondary,
                  helperText: 'Kullanıcı adınızı değiştirebilirsiniz. Sistem otomatik olarak unique sayı ekleyecek.',
                  helperStyle: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                ),
                onChanged: (value) {
                  // Clear previous error when user types
                  if (_formKey.currentState != null) {
                    _formKey.currentState!.validate();
                  }
                },
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Lütfen kullanıcı adı girin';
                  }
                  final trimmed = value.trim();
                  if (trimmed.length < 3) {
                    return 'Kullanıcı adı en az 3 karakter olmalı';
                  }
                  if (trimmed.length > 20) {
                    return 'Kullanıcı adı en fazla 20 karakter olabilir';
                  }
                  // Check for valid characters (alphanumeric and underscore, no #)
                  if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(trimmed)) {
                    return 'Kullanıcı adı sadece harf, rakam ve alt çizgi içerebilir';
                  }
                  if (trimmed.contains('#')) {
                    return 'Kullanıcı adı # karakteri içeremez (sayı otomatik eklenir)';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),
              // Save Button
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(AppTheme.textPrimary),
                          ),
                        )
                      : const Text(
                          'Değişiklikleri Kaydet',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

