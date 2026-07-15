import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../config/api_config.dart';
import '../../services/api_client.dart';
import '../../services/auth_service.dart';
import '../../widgets/dosen_nav_helper.dart';
import '../../widgets/logout_dialog.dart';
import '../auth/login_page.dart';
import '../auth/change_password.dart';
import 'dosen_input_nilai_page.dart';
import 'dosen_jadwal_page.dart';
import '../../utils/app_toast.dart';
import '../../widgets/custom_top_bar.dart';

// ============================================================
// dosen_profil_page.dart — Halaman Profil Dosen
//   Desain disamakan dengan profil mahasiswa (avatar besar,
//   info card, ganti password, logout).
// ============================================================

class DosenProfilPage extends StatefulWidget {
  final String userId;
  final String nama;
  final String username;

  const DosenProfilPage({
    super.key,
    required this.userId,
    required this.nama,
    required this.username,
  });

  @override
  State<DosenProfilPage> createState() => _DosenProfilPageState();
}

class _DosenProfilPageState extends State<DosenProfilPage> {
  final int _navIndex = 3; // Index Profil
  bool _isLoading = true;
  
  String _nama = '-';
  String _nidn = '-';
  String _hp = '-';

  @override
  void initState() {
    super.initState();
    _loadProfil();
  }

  Future<void> _loadProfil() async {
    setState(() => _isLoading = true);

    try {
      final res = await ApiClient.get(ApiConfig.getDosen);
      if (res['status'] == 'ok' && res['data'] != null) {
        final data = res['data'] as Map<String, dynamic>;
        _nama = data['nama']?.toString() ?? '-';
        _nidn = data['nidn']?.toString() ?? '-';
        _hp = data['no_hp']?.toString() ?? '-';
      }
    } catch (_) {
      // fallback: gunakan data dari widget params
      _nama = widget.nama;
      _nidn = widget.username;
    }

    if (mounted) setState(() => _isLoading = false);
  }



  Future<void> _logout() async {
    final konfirmasi = await showLogoutDialog(context);
    if (konfirmasi != true) return;

    await AuthService.logout();
    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  void _navigateToChangePassword() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChangePasswordPage(
          userId: widget.userId,
          nama: widget.nama,
          username: widget.username,
          role: 'dosen',
          nim: widget.username, // using username (nidn) for nim
          isForced: false,
        ),
      ),
    );
  }
  
  // Method helpers for Bottom Navigation across pages
  void _navToJadwal() {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => DosenJadwalPage(
          userId: widget.userId,
          nama: widget.nama,
          username: widget.username,
        ),
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
    );
  }

  void _navToNilai() {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => DosenInputNilaiPage(
          userId: widget.userId,
          nama: widget.nama,
          username: widget.username,
        ),
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: Container(
        decoration: BoxDecoration(gradient: AppColorsSoft.backgroundGradient),
        child: SafeArea(
          bottom: false,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
            children: _isLoading
                ? [
                    _buildTopBar(),
                    const SizedBox(height: 150),
                    const Center(child: CircularProgressIndicator(color: AppColorsSoft.navy)),
                  ]
                : [
                    _buildTopBar(),
                    const SizedBox(height: 24),
                    _buildAvatar(),
                    const SizedBox(height: 16),
                    _buildIdentity(),
                    const SizedBox(height: 28),
                    _buildInfoCard(),
                    const SizedBox(height: 16),
                    _buildActionCard(),
                  ],
          ),
        ),
      ),
      bottomNavigationBar: DosenNavHelper.buildNav(
        context: context,
        currentIndex: _navIndex,
        onLogout: _logout,
        onBerandaTap: () {
          Navigator.popUntil(context, (route) => route.isFirst);
        },
        onJadwalTap: _navToJadwal,
        onNilaiTap: _navToNilai,
        onProfilTap: () {}, // Already here
      ),
    );
  }

  // ---- Header ----
  Widget _buildTopBar() {
    return CustomTopBar(
      title: 'Profil Dosen',
      nama: widget.nama,
      onBack: () => Navigator.pop(context),
    );
  }

  // ---- Avatar Besar ----
  Widget _buildAvatar() {
    return Center(
      child: Container(
        width: 110,
        height: 110,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColorsSoft.gradientLavender,
              AppColorsSoft.gradientPeach,
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: AppColorsSoft.navy.withOpacity(0.10),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Center(
          child: Container(
            width: 98,
            height: 98,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColorsSoft.gradientLavender,
              border: Border.all(color: AppColorsSoft.cardWhite, width: 3),
            ),
            child: Center(
              child: Text(
                _nama.isNotEmpty ? _nama[0].toUpperCase() : 'D',
                style: const TextStyle(
                  fontSize: 38,
                  fontWeight: FontWeight.w800,
                  color: AppColorsSoft.navy,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ---- Nama & NIDN ----
  Widget _buildIdentity() {
    return Column(
      children: [
        Text(
          _nama,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: AppColorsSoft.navy,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _nidn,
          style: const TextStyle(
            fontSize: 14,
            color: AppColorsSoft.textGray,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 2),
        const Text(
          'DOSEN',
          style: TextStyle(
            fontSize: 12,
            color: AppColorsSoft.textGrayLight,
            fontWeight: FontWeight.w700,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }

  // ---- Card Informasi Dosen ----
  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: AppColorsSoft.card(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Informasi Dosen',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColorsSoft.navy,
            ),
          ),
          const SizedBox(height: 20),
          _infoRow(
            icon: Icons.badge_outlined,
            iconBg: const Color(0xFFDCEBFF),
            iconColor: const Color(0xFF2E6FE0),
            label: 'NIDN',
            value: _nidn,
          ),
          _divider(),
          _infoRow(
            icon: Icons.phone_android_rounded,
            iconBg: const Color(0xFFD9F5E4),
            iconColor: const Color(0xFF12A150),
            label: 'No. Handphone',
            value: _hp.isEmpty ? '-' : _hp,
          ),
        ],
      ),
    );
  }

  Widget _infoRow({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconBg,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 20, color: iconColor),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: AppColorsSoft.textGrayLight,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColorsSoft.navy,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() {
    return const Divider(
      height: 1,
      color: AppColorsSoft.fieldFill,
      thickness: 1,
    );
  }

  // ---- Card Aksi (Ganti Password & Logout) ----
  Widget _buildActionCard() {
    return Container(
      decoration: AppColorsSoft.card(),
      child: Column(
        children: [
          // Ganti Password
          InkWell(
            onTap: _navigateToChangePassword,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(28),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFFF6D6),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.lock_outline_rounded,
                      size: 20,
                      color: Color(0xFFCBA400),
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Text(
                      'Ganti Password',
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: AppColorsSoft.navy,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColorsSoft.textGrayLight,
                    size: 22,
                  ),
                ],
              ),
            ),
          ),
          const Divider(
            height: 1,
            indent: 24,
            endIndent: 24,
            color: AppColorsSoft.fieldFill,
            thickness: 1,
          ),
          // Logout
          InkWell(
            onTap: _logout,
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(28),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFFE0E0),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.logout_rounded,
                      size: 20,
                      color: Color(0xFFE05252),
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Text(
                      'Logout',
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFE05252),
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: Color(0xFFE05252),
                    size: 22,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
