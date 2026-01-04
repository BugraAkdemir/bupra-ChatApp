import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_card.dart';
import '../widgets/custom_snackbar.dart';
import 'login_screen.dart';

class PrivacyScreen extends StatefulWidget {
  const PrivacyScreen({super.key});

  @override
  State<PrivacyScreen> createState() => _PrivacyScreenState();
}

class _PrivacyScreenState extends State<PrivacyScreen> {
  final _authService = AuthService();
  bool _isChangingPassword = false;
  bool _isDeletingAccount = false;

  Future<void> _changePassword() async {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => _ChangePasswordDialog(
        currentPasswordController: currentPasswordController,
        newPasswordController: newPasswordController,
        confirmPasswordController: confirmPasswordController,
      ),
    );

    if (result != true) return;

    setState(() => _isChangingPassword = true);

    try {
      final currentPassword = currentPasswordController.text;
      final newPassword = newPasswordController.text;

      // Re-authenticate user
      final user = _authService.currentUser;
      if (user?.email == null) {
        throw Exception('Email bulunamadı');
      }

      final credential = await _authService.reauthenticateWithEmail(
        user!.email!,
        currentPassword,
      );

      if (credential == null) {
        throw Exception('Mevcut şifre yanlış');
      }

      // Update password
      await user.updatePassword(newPassword);

      if (mounted) {
        CustomSnackBar.showSuccess(context, 'Şifre başarıyla değiştirildi');
      }
    } catch (e) {
      if (mounted) {
        CustomSnackBar.showError(
          context,
          e.toString().replaceFirst('Exception: ', ''),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isChangingPassword = false);
      }
    }
  }

  Future<void> _deleteAccount() async {
    final confirmController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => _DeleteAccountDialog(
        confirmController: confirmController,
      ),
    );

    if (result != true) return;

    setState(() => _isDeletingAccount = true);

    try {
      final user = _authService.currentUser;
      if (user?.email == null) {
        throw Exception('Kullanıcı bulunamadı');
      }

      // Get password for re-authentication
      final passwordController = TextEditingController();
      final passwordResult = await showDialog<String>(
        context: context,
        builder: (context) => _PasswordDialog(
          passwordController: passwordController,
        ),
      );

      if (passwordResult != 'confirmed') {
        setState(() => _isDeletingAccount = false);
        return;
      }

      // Re-authenticate
      final credential = await _authService.reauthenticateWithEmail(
        user!.email!,
        passwordController.text,
      );

      if (credential == null) {
        throw Exception('Şifre yanlış');
      }

      // Delete user account
      await _authService.deleteAccount();

      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
        CustomSnackBar.showInfo(context, 'Hesabınız silindi');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isDeletingAccount = false);
        CustomSnackBar.showError(
          context,
          e.toString().replaceFirst('Exception: ', ''),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Gizlilik'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 16),
            // Change Password
            CustomCard(
              onTap: _isChangingPassword ? null : _changePassword,
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.lock_outline_rounded,
                      color: AppTheme.primaryColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Şifre Değiştir',
                          style: TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Hesap şifrenizi güncelleyin',
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_isChangingPassword)
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppTheme.primaryColor,
                        ),
                      ),
                    )
                  else
                    Icon(
                      Icons.chevron_right_rounded,
                      color: AppTheme.textSecondary,
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Delete Account
            CustomCard(
              onTap: _isDeletingAccount ? null : _deleteAccount,
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppTheme.errorColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.delete_outline_rounded,
                      color: AppTheme.errorColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hesabı Sil',
                          style: TextStyle(
                            color: AppTheme.errorColor,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Hesabınızı kalıcı olarak silin',
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_isDeletingAccount)
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppTheme.errorColor,
                        ),
                      ),
                    )
                  else
                    Icon(
                      Icons.chevron_right_rounded,
                      color: AppTheme.textSecondary,
                    ),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _ChangePasswordDialog extends StatefulWidget {
  final TextEditingController currentPasswordController;
  final TextEditingController newPasswordController;
  final TextEditingController confirmPasswordController;

  const _ChangePasswordDialog({
    required this.currentPasswordController,
    required this.newPasswordController,
    required this.confirmPasswordController,
  });

  @override
  State<_ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<_ChangePasswordDialog> {
  final _formKey = GlobalKey<FormState>();
  bool _obscureCurrentPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    widget.currentPasswordController.dispose();
    widget.newPasswordController.dispose();
    widget.confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppTheme.surfaceColor,
      title: const Text(
        'Şifre Değiştir',
        style: TextStyle(color: AppTheme.textPrimary),
      ),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: widget.currentPasswordController,
                obscureText: _obscureCurrentPassword,
                style: const TextStyle(color: AppTheme.textPrimary),
                decoration: InputDecoration(
                  labelText: 'Mevcut Şifre',
                  prefixIcon: const Icon(Icons.lock_outline),
                  prefixIconColor: AppTheme.textSecondary,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureCurrentPassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: AppTheme.textSecondary,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureCurrentPassword = !_obscureCurrentPassword;
                      });
                    },
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Lütfen mevcut şifrenizi girin';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: widget.newPasswordController,
                obscureText: _obscureNewPassword,
                style: const TextStyle(color: AppTheme.textPrimary),
                decoration: InputDecoration(
                  labelText: 'Yeni Şifre',
                  prefixIcon: const Icon(Icons.lock_outline),
                  prefixIconColor: AppTheme.textSecondary,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureNewPassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: AppTheme.textSecondary,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureNewPassword = !_obscureNewPassword;
                      });
                    },
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Lütfen yeni şifre girin';
                  }
                  if (value.length < 6) {
                    return 'Şifre en az 6 karakter olmalı';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: widget.confirmPasswordController,
                obscureText: _obscureConfirmPassword,
                style: const TextStyle(color: AppTheme.textPrimary),
                decoration: InputDecoration(
                  labelText: 'Yeni Şifre (Tekrar)',
                  prefixIcon: const Icon(Icons.lock_outline),
                  prefixIconColor: AppTheme.textSecondary,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirmPassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: AppTheme.textSecondary,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureConfirmPassword = !_obscureConfirmPassword;
                      });
                    },
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Lütfen şifreyi tekrar girin';
                  }
                  if (value != widget.newPasswordController.text) {
                    return 'Şifreler eşleşmiyor';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text(
            'İptal',
            style: TextStyle(color: AppTheme.textSecondary),
          ),
        ),
        TextButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              Navigator.pop(context, true);
            }
          },
          child: const Text(
            'Değiştir',
            style: TextStyle(color: AppTheme.primaryColor),
          ),
        ),
      ],
    );
  }
}

class _DeleteAccountDialog extends StatelessWidget {
  final TextEditingController confirmController;

  const _DeleteAccountDialog({required this.confirmController});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppTheme.surfaceColor,
      title: const Text(
        'Hesabı Sil',
        style: TextStyle(color: AppTheme.errorColor),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Hesabınızı silmek istediğinize emin misiniz? Bu işlem geri alınamaz.',
            style: TextStyle(color: AppTheme.textPrimary),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: confirmController,
            style: const TextStyle(color: AppTheme.textPrimary),
            decoration: InputDecoration(
              labelText: 'Silmek için "SİL" yazın',
              hintText: 'SİL',
              hintStyle: const TextStyle(color: AppTheme.textSecondary),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text(
            'İptal',
            style: TextStyle(color: AppTheme.textSecondary),
          ),
        ),
        TextButton(
          onPressed: () {
            if (confirmController.text.trim().toUpperCase() == 'SİL') {
              Navigator.pop(context, true);
            }
          },
          style: TextButton.styleFrom(
            foregroundColor: AppTheme.errorColor,
          ),
          child: const Text('Sil'),
        ),
      ],
    );
  }
}

class _PasswordDialog extends StatefulWidget {
  final TextEditingController passwordController;

  const _PasswordDialog({required this.passwordController});

  @override
  State<_PasswordDialog> createState() => _PasswordDialogState();
}

class _PasswordDialogState extends State<_PasswordDialog> {
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppTheme.surfaceColor,
      title: const Text(
        'Şifre Onayı',
        style: TextStyle(color: AppTheme.textPrimary),
      ),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: widget.passwordController,
          obscureText: _obscurePassword,
          style: const TextStyle(color: AppTheme.textPrimary),
          decoration: InputDecoration(
            labelText: 'Şifre',
            prefixIcon: const Icon(Icons.lock_outline),
            prefixIconColor: AppTheme.textSecondary,
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                color: AppTheme.textSecondary,
              ),
              onPressed: () {
                setState(() {
                  _obscurePassword = !_obscurePassword;
                });
              },
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Lütfen şifrenizi girin';
            }
            return null;
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, 'cancelled'),
          child: const Text(
            'İptal',
            style: TextStyle(color: AppTheme.textSecondary),
          ),
        ),
        TextButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              Navigator.pop(context, 'confirmed');
            }
          },
          child: const Text(
            'Onayla',
            style: TextStyle(color: AppTheme.errorColor),
          ),
        ),
      ],
    );
  }
}

