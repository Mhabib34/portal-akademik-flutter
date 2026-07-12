import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../services/auth_service.dart';
import '../services/api_client.dart';
import 'home_router.dart';

// ============================================================
// change_password.dart
// Halaman ganti password — WAJIB saat pertama login
// Tidak bisa di-back (PopScope)
// Desain selaras dengan tema soft-pastel portal akademik
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

class _ChangePasswordPageState extends State<ChangePasswordPage>
    with SingleTickerProviderStateMixin {
  final _pwBaruCtrl = TextEditingController();
  final _pwKonfirmCtrl = TextEditingController();

  bool _isLoading = false;
  bool _obscureBaru = true;
  bool _obscureKonfirm = true;

  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic));
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _pwBaruCtrl.dispose();
    _pwKonfirmCtrl.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  // --- Password strength indicator ---
  double get _passwordStrength {
    final pw = _pwBaruCtrl.text;
    if (pw.isEmpty) return 0;
    double s = 0;
    if (pw.length >= 6) s += 0.25;
    if (pw.length >= 10) s += 0.15;
    if (RegExp(r'[A-Z]').hasMatch(pw)) s += 0.2;
    if (RegExp(r'[0-9]').hasMatch(pw)) s += 0.2;
    if (RegExp(r'[!@#\$%^&*(),.?":{}|<>]').hasMatch(pw)) s += 0.2;
    return s.clamp(0, 1);
  }

  Color get _strengthColor {
    final s = _passwordStrength;
    if (s <= 0.25) return const Color(0xFFE05252);
    if (s <= 0.5) return const Color(0xFFCBA400);
    if (s <= 0.75) return const Color(0xFF4EADCF);
    return const Color(0xFF12A150);
  }

  String get _strengthLabel {
    final s = _passwordStrength;
    if (s == 0) return '';
    if (s <= 0.25) return 'Lemah';
    if (s <= 0.5) return 'Cukup';
    if (s <= 0.75) return 'Kuat';
    return 'Sangat Kuat';
  }

  // --- Kirim ganti password ---
  Future<void> _gantiPassword() async {
    // Manual validation (no Form/GlobalKey needed)
    final pwBaru = _pwBaruCtrl.text.trim();
    final pwKonfirm = _pwKonfirmCtrl.text.trim();

    if (pwBaru.isEmpty) {
      _showSnack('Password baru wajib diisi', isError: true);
      return;
    }
    if (pwBaru.length < 6) {
      _showSnack('Password minimal 6 karakter', isError: true);
      return;
    }
    if (pwKonfirm.isEmpty) {
      _showSnack('Konfirmasi password wajib diisi', isError: true);
      return;
    }
    if (pwBaru != pwKonfirm) {
      _showSnack('Password dan konfirmasi tidak cocok', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      await AuthService.changePassword(pwBaru);

      if (!mounted) return;
      setState(() => _isLoading = false);

      _showSnack('Password berhasil diubah! Selamat datang.');

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
      _showSnack(e.message, isError: true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showSnack('Tidak dapat terhubung ke server.', isError: true);
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor:
            isError ? const Color(0xFFE05252) : AppColorsSoft.navy,
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
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          _showSnack(
            'Anda harus mengubah password terlebih dahulu.',
            isError: true,
          );
        }
      },
      child: Scaffold(
        body: Container(
          decoration:
              BoxDecoration(gradient: AppColorsSoft.backgroundGradient),
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                child: FadeTransition(
                  opacity: _fadeAnim,
                  child: SlideTransition(
                    position: _slideAnim,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 420),
                      child: Column(
                        children: [
                          // --- Lock icon ---
                          Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              color: AppColorsSoft.cardWhite,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColorsSoft.navy
                                      .withValues(alpha: 0.1),
                                  blurRadius: 24,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.lock_reset_rounded,
                              size: 32,
                              color: AppColorsSoft.navy,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'Halo, ${widget.nama}!',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: AppColorsSoft.navy,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Demi keamanan akun Anda, silakan buat\npassword baru untuk melanjutkan.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColorsSoft.textGray,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 28),

                          // --- Info Banner ---
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF8E1),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFECB3),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.info_outline_rounded,
                                    color: Color(0xFFE08A00),
                                    size: 18,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                const Expanded(
                                  child: Text(
                                    'Login pertama terdeteksi. Anda wajib mengganti password default sebelum mengakses portal.',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF7A5A00),
                                      height: 1.45,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),

                          // --- Form Card ---
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: AppColorsSoft.card(),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Buat Password Baru',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: AppColorsSoft.navy,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'Minimal 6 karakter. Jangan gunakan NIM.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColorsSoft.textGrayLight,
                                  ),
                                ),
                                const SizedBox(height: 20),

                                // Password Baru
                                TextField(
                                  controller: _pwBaruCtrl,
                                  obscureText: _obscureBaru,
                                  textInputAction: TextInputAction.next,
                                  onChanged: (_) => setState(() {}),
                                  decoration: AppColorsSoft.fieldDecoration(
                                    hint: 'Password Baru',
                                    prefixIcon: Icons.lock_outline_rounded,
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscureBaru
                                            ? Icons.visibility_off_outlined
                                            : Icons.visibility_outlined,
                                        color: AppColorsSoft.textGrayLight,
                                        size: 20,
                                      ),
                                      onPressed: () => setState(
                                          () => _obscureBaru = !_obscureBaru),
                                    ),
                                  ),
                                ),

                                // Strength meter
                                if (_pwBaruCtrl.text.isNotEmpty) ...[
                                  const SizedBox(height: 10),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: LinearProgressIndicator(
                                      value: _passwordStrength,
                                      minHeight: 4,
                                      backgroundColor:
                                          AppColorsSoft.fieldFill,
                                      valueColor:
                                          AlwaysStoppedAnimation<Color>(
                                              _strengthColor),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: Text(
                                      _strengthLabel,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: _strengthColor,
                                      ),
                                    ),
                                  ),
                                ],

                                const SizedBox(height: 16),

                                // Konfirmasi Password
                                TextField(
                                  controller: _pwKonfirmCtrl,
                                  obscureText: _obscureKonfirm,
                                  textInputAction: TextInputAction.done,
                                  onSubmitted: (_) => _gantiPassword(),
                                  decoration: AppColorsSoft.fieldDecoration(
                                    hint: 'Konfirmasi Password',
                                    prefixIcon: Icons.lock_reset_rounded,
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscureKonfirm
                                            ? Icons.visibility_off_outlined
                                            : Icons.visibility_outlined,
                                        color: AppColorsSoft.textGrayLight,
                                        size: 20,
                                      ),
                                      onPressed: () => setState(() =>
                                          _obscureKonfirm =
                                              !_obscureKonfirm),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 28),

                                // Tombol Simpan
                                SizedBox(
                                  width: double.infinity,
                                  height: 52,
                                  child: ElevatedButton(
                                    onPressed:
                                        _isLoading ? null : _gantiPassword,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColorsSoft.navy,
                                      foregroundColor: Colors.white,
                                      disabledBackgroundColor: AppColorsSoft
                                          .navy
                                          .withValues(alpha: 0.5),
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(26),
                                      ),
                                      elevation: 0,
                                    ),
                                    child: _isLoading
                                        ? const SizedBox(
                                            width: 22,
                                            height: 22,
                                            child:
                                                CircularProgressIndicator(
                                              strokeWidth: 2.5,
                                              color: Colors.white,
                                            ),
                                          )
                                        : const Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                Icons
                                                    .check_circle_outline_rounded,
                                                size: 20,
                                              ),
                                              SizedBox(width: 8),
                                              Text(
                                                'Simpan Password Baru',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 14,
                                                  letterSpacing: 0.5,
                                                ),
                                              ),
                                            ],
                                          ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'Portal Akademik • ${DateTime.now().year}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColorsSoft.textGrayLight,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
