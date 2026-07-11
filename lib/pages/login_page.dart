import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../services/auth_service.dart';
import '../services/api_client.dart';
import 'change_password.dart';
import 'home_page.dart';

// ============================================================
// login_page.dart — Halaman Login Portal Akademik
//   Desain: soft pastel glassmorphism (sesuai referensi Stitch)
// ============================================================

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  // --- Proses Login ---
  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final session = await AuthService.login(
        _usernameCtrl.text.trim(),
        _passwordCtrl.text.trim(),
      );

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (session.mustChangePassword == 1) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ChangePasswordPage(
              userId: session.id,
              nama: session.nama,
              username: session.username,
              role: session.role,
              nim: session.nim,
            ),
          ),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => HomePage(
              userId: session.id,
              nama: session.nama,
              username: session.username,
              role: session.role,
              nim: session.nim,
            ),
          ),
        );
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showSnackBar(e.message, isError: true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showSnackBar('Tidak dapat terhubung ke server. Periksa koneksi Anda.', isError: true);
    }
  }

  void _showSnackBar(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? const Color(0xFFE05252) : const Color(0xFF3BAA6B),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _handleLupaPassword() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Lupa Password?'),
        content: const Text(
          'Reset password hanya bisa dilakukan oleh Admin Fakultas. '
          'Silakan hubungi Admin melalui email/WhatsApp resmi kampus.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Mengerti'),
          ),
        ],
      ),
    );
  }

  // ----------------------------------------------------------------
  // BUILD
  // ----------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: AppColorsSoft.backgroundGradient),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 28),
                    _buildFormCard(),
                    const SizedBox(height: 24),
                    _buildFooterInfo(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --- Header: ilustrasi mascot + judul ---
  Widget _buildHeader() {
    return Column(
      children: [
        SizedBox(
          height: 160,
          child: Image.asset(
            'assets/images/mascot_wisuda.png',
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) => Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppColorsSoft.cardWhite,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColorsSoft.navy.withOpacity(0.08),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: const Icon(
                Icons.school_rounded,
                color: AppColorsSoft.navy,
                size: 56,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Portal Akademik',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: AppColorsSoft.navy,
          ),
        ),
        const SizedBox(height: 2),
        const Text(
          'Mahasiswa',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: AppColorsSoft.textGray,
          ),
        ),
      ],
    );
  }

  // --- Form Card ---
  Widget _buildFormCard() {
    return Container(
      width: double.infinity,
      decoration: AppColorsSoft.card(),
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Username / NIM',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColorsSoft.navy,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _usernameCtrl,
              decoration: AppColorsSoft.fieldDecoration(
                hint: 'Masukkan NIM Anda',
                prefixIcon: Icons.person_outline_rounded,
              ),
              keyboardType: TextInputType.text,
              textInputAction: TextInputAction.next,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Username wajib diisi' : null,
            ),
            const SizedBox(height: 18),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Password',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColorsSoft.navy,
                  ),
                ),
                GestureDetector(
                  onTap: _handleLupaPassword,
                  child: const Text(
                    'Lupa Password?',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: AppColorsSoft.linkAccent,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _passwordCtrl,
              decoration: AppColorsSoft.fieldDecoration(
                hint: 'Masukkan Password',
                prefixIcon: Icons.lock_outline_rounded,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: AppColorsSoft.textGray,
                    size: 20,
                  ),
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
              obscureText: _obscurePassword,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _login(),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Password wajib diisi' : null,
            ),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _login,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColorsSoft.navy,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(26),
                  ),
                  elevation: 0,
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'MASUK',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.0,
                            ),
                          ),
                          SizedBox(width: 8),
                          Icon(Icons.arrow_forward_rounded, size: 18),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Footer info ---
  Widget _buildFooterInfo() {
    return const Text(
      'Gunakan akun Sistem Informasi Mahasiswa.\n'
      'Kendala login hubungi Admin Fakultas melalui\nemail/WhatsApp resmi.',
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 12.5,
        color: AppColorsSoft.textGray,
        height: 1.6,
      ),
    );
  }
}
