import 'dart:convert';
import 'package:app_input/pages/change_password.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../theme/app_theme.dart';
import 'home_page.dart';

// ============================================================
// login_page.dart — Halaman Login Portal Akademik
// ============================================================

const String _baseUrl = 'http://10.10.1.159/flutter_api/';

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
      final response = await http
          .post(
            Uri.parse('${_baseUrl}login.php'),
            body: {
              'username': _usernameCtrl.text.trim(),
              'password': _passwordCtrl.text.trim(),
            },
          )
          .timeout(const Duration(seconds: 15));

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (data['status'] == 'ok') {
        final String userId = data['id'].toString();
        final String nama = data['nama'].toString();
        final String username = data['username'].toString();
        final String role = data['role'].toString();
        final String nim = data['nim']?.toString() ?? '';
        final int mustChange =
            int.tryParse(data['must_change_password'].toString()) ?? 0;

        if (mustChange == 1) {
          // Wajib ganti password dulu
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => ChangePasswordPage(
                userId: userId,
                nama: nama,
                username: username,
                role: role,
                nim: nim,
              ),
            ),
          );
        } else {
          // Langsung ke home
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => HomePage(
                userId: userId,
                nama: nama,
                username: username,
                role: role,
                nim: nim,
              ),
            ),
          );
        }
      } else {
        _showSnackBar(data['message'] ?? 'Login gagal', isError: true);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showSnackBar(
        'Tidak dapat terhubung ke server. Periksa koneksi Anda.',
        isError: true,
      );
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
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 32),
                  _buildFormCard(),
                  const SizedBox(height: 20),
                  _buildFooterInfo(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --- Header: logo + judul ---
  Widget _buildHeader() {
    return Column(
      children: [
        // Logo / Icon Sekolah
        Container(
          width: 84,
          height: 84,
          decoration: BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.3),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: const Icon(
            Icons.school_rounded,
            color: AppColors.white,
            size: 44,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'PORTAL AKADEMIK',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: AppColors.primary,
            letterSpacing: 2.0,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'MAHASISWA',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.primaryMed,
            letterSpacing: 4.0,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 3,
          width: 60,
          decoration: BoxDecoration(
            color: AppColors.primaryMed,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ],
    );
  }

  // --- Form Card ---
  Widget _buildFormCard() {
    return Container(
      decoration: AppDecorations.card(),
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Masuk ke Akun Anda', style: AppTextStyles.heading3),
            const SizedBox(height: 4),
            const Text(
              'Gunakan kredensial yang diberikan oleh administrator',
              style: AppTextStyles.bodySmall,
            ),
            const SizedBox(height: 24),

            // Username
            TextFormField(
              controller: _usernameCtrl,
              decoration: AppDecorations.inputDecoration(
                label: 'Username / NIM',
                hint: 'Masukkan username atau NIM',
                prefixIcon: Icons.person_outline_rounded,
              ),
              keyboardType: TextInputType.text,
              textInputAction: TextInputAction.next,
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Username wajib diisi'
                  : null,
            ),
            const SizedBox(height: 16),

            // Password
            TextFormField(
              controller: _passwordCtrl,
              decoration: AppDecorations.inputDecoration(
                label: 'Password',
                hint: 'Masukkan password',
                prefixIcon: Icons.lock_outline_rounded,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: AppColors.textLight,
                    size: 20,
                  ),
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
              obscureText: _obscurePassword,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _login(),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Password wajib diisi'
                  : null,
            ),
            const SizedBox(height: 28),

            // Tombol LOGIN
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _login,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 2,
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: AppColors.white,
                        ),
                      )
                    : const Text(
                        'MASUK',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.5,
                        ),
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.infoLight,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline_rounded, color: AppColors.info, size: 18),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Akun diberikan oleh administrator. Hubungi bagian akademik jika mengalami masalah.',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.info,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
