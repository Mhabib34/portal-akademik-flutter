import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../services/token_service.dart';
import 'login_page.dart';
import 'change_password.dart';
import 'home_router.dart';

// ============================================================
// splash_page.dart — Cek sesi tersimpan saat app dibuka
//   Kalau ada sesi valid (token ada & belum expired), langsung
//   arahkan ke home sesuai role tanpa perlu login ulang.
//   Kalau tidak ada / sudah expired, arahkan ke LoginPage.
// ============================================================

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession() async {
    // Kasih jeda kecil biar splash tidak "kedip" sekilas.
    await Future.delayed(const Duration(milliseconds: 400));

    final session = await TokenService.getSession();
    final expired = await TokenService.isTokenExpired();

    if (!mounted) return;

    if (session == null || session.token.isEmpty || expired) {
      if (session != null) {
        // Sesi ada tapi sudah kedaluwarsa -> bersihkan biar konsisten.
        await TokenService.clearSession();
      }
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
      return;
    }

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
      return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => buildHomePageForRole(
          role: session.role,
          userId: session.id,
          nama: session.nama,
          username: session.username,
          nim: session.nim,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: AppColorsSoft.backgroundGradient),
        child: const Center(
          child: CircularProgressIndicator(color: AppColorsSoft.navy),
        ),
      ),
    );
  }
}
