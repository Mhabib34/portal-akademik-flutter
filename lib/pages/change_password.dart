import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../services/auth_service.dart';
import '../services/api_client.dart';
import 'home_router.dart';

// ============================================================
// change_password.dart
// Halaman ganti password — WAJIB saat pertama login
// Tidak bisa di-back (PopScope)
// ============================================================

class ChangePasswordPage extends StatefulWidget {
  final String userId;
  final String nama;
  final String username;
  final String role;
  final String nim;

  const ChangePasswordPage({
    super.key,
    required this.userId,
    required this.nama,
    required this.username,
    required this.role,
    required this.nim,
  });

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _pwBaruCtrl = TextEditingController();
  final _pwKonfirmCtrl = TextEditingController();

  bool _isLoading = false;
  bool _obscureBaru = true;
  bool _obscureKonfirm = true;

  @override
  void dispose() {
    _pwBaruCtrl.dispose();
    _pwKonfirmCtrl.dispose();
    super.dispose();
  }

  // --- Kirim ganti password ---
  Future<void> _gantiPassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await AuthService.changePassword(_pwBaruCtrl.text.trim());

      if (!mounted) return;
      setState(() => _isLoading = false);

      _showSnackBar(
        'Password berhasil diubah! Selamat datang.',
        isError: false,
      );

      await Future.delayed(const Duration(milliseconds: 500));
      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => buildHomePageForRole(
            role: widget.role,
            userId: widget.userId,
            nama: widget.nama,
            username: widget.username,
            nim: widget.nim,
          ),
        ),
        (route) => false,
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showSnackBar(e.message, isError: true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showSnackBar('Tidak dapat terhubung ke server.', isError: true);
    }
  }

  void _showSnackBar(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? AppColors.danger : AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  // ----------------------------------------------------------------
  // BUILD
  // ----------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    // PopScope: cegah back button
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (!didPop) {
          _showSnackBar(
            'Anda harus mengubah password terlebih dahulu sebelum melanjutkan.',
            isError: true,
          );
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Ganti Password'),
          automaticallyImplyLeading: false,
          backgroundColor: AppColors.primary,
        ),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  children: [
                    _buildInfoBanner(),
                    const SizedBox(height: 24),
                    _buildFormCard(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --- Banner informasi wajib ganti password ---
  Widget _buildInfoBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.warningLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.warning.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                color: AppColors.warning,
                size: 22,
              ),
              const SizedBox(width: 8),
              Text(
                'Halo, ${widget.nama}!',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.warning,
                  fontSize: 15,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Ini adalah login pertama Anda. Demi keamanan, Anda diwajibkan mengganti password sebelum dapat mengakses portal.',
            style: TextStyle(
              color: AppColors.textMedium,
              fontSize: 13,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  // --- Form ganti password ---
  Widget _buildFormCard() {
    return Container(
      decoration: AppDecorations.card(),
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Buat Password Baru', style: AppTextStyles.heading3),
            const SizedBox(height: 4),
            const Text(
              'Minimal 6 karakter. Jangan gunakan NIM sebagai password baru.',
              style: AppTextStyles.bodySmall,
            ),
            const SizedBox(height: 24),

            TextFormField(
              controller: _pwBaruCtrl,
              decoration: AppDecorations.inputDecoration(
                label: 'Password Baru',
                hint: 'Minimal 6 karakter',
                prefixIcon: Icons.lock_outline_rounded,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureBaru
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: AppColors.textLight,
                    size: 20,
                  ),
                  onPressed: () => setState(() => _obscureBaru = !_obscureBaru),
                ),
              ),
              obscureText: _obscureBaru,
              textInputAction: TextInputAction.next,
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'Password baru wajib diisi';
                }
                if (v.trim().length < 6) return 'Password minimal 6 karakter';
                return null;
              },
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _pwKonfirmCtrl,
              decoration: AppDecorations.inputDecoration(
                label: 'Konfirmasi Password',
                hint: 'Ulangi password baru',
                prefixIcon: Icons.lock_reset_rounded,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureKonfirm
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: AppColors.textLight,
                    size: 20,
                  ),
                  onPressed: () =>
                      setState(() => _obscureKonfirm = !_obscureKonfirm),
                ),
              ),
              obscureText: _obscureKonfirm,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _gantiPassword(),
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'Konfirmasi password wajib diisi';
                }
                if (v.trim() != _pwBaruCtrl.text.trim()) {
                  return 'Password tidak cocok';
                }
                return null;
              },
            ),
            const SizedBox(height: 28),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _gantiPassword,
                icon: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: AppColors.white,
                        ),
                      )
                    : const Icon(Icons.check_circle_outline_rounded, size: 20),
                label: Text(
                  _isLoading ? 'Menyimpan...' : 'SIMPAN PASSWORD BARU',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  textStyle: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
