import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../config/api_config.dart';
import '../../services/api_client.dart';
import '../../services/auth_service.dart';
import '../../widgets/mahasiswa_nav_helper.dart';
import '../../widgets/logout_dialog.dart';
import '../auth/login_page.dart';
import '../auth/change_password.dart';
import '../../utils/app_toast.dart';

// ============================================================
// mahasiswa_profil_page.dart — Halaman Profil Mahasiswa
//   Data dari API: nama, nim, prodi (via get_prodi), alamat.
//   Desain sesuai referensi UI (avatar besar tengah, info card,
//   ganti password, logout).
// ============================================================

class MahasiswaProfilPage extends StatefulWidget {
  final String userId;
  final String nama;
  final String username;
  final String nim;

  const MahasiswaProfilPage({
    super.key,
    required this.userId,
    required this.nama,
    required this.username,
    required this.nim,
  });

  @override
  State<MahasiswaProfilPage> createState() => _MahasiswaProfilPageState();
}

class _MahasiswaProfilPageState extends State<MahasiswaProfilPage> {
  bool _isLoading = true;
  final int _navIndex = 3; // Profil aktif

  String _nama = '-';
  String _nim = '-';
  String _namaProdi = '-';
  String _alamat = '-';



  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);

    try {
      // 1. Ambil data mahasiswa (role mahasiswa -> data sendiri)
      final mhsRes = await ApiClient.get(ApiConfig.getMahasiswa);
      if (mhsRes['status'] == 'ok' && mhsRes['data'] != null) {
        final data = mhsRes['data'] as Map<String, dynamic>;
        _nama = data['nama']?.toString() ?? '-';
        _nim = data['nim']?.toString() ?? '-';
        _alamat = data['alamat']?.toString() ?? '-';

        // 2. Resolve prodi_id ke nama_prodi
        final prodiId = data['prodi_id']?.toString();
        if (prodiId != null && prodiId.isNotEmpty) {
          await _resolveProdi(prodiId);
        }
      }
    } catch (_) {
      // fallback: gunakan data dari widget params
      _nama = widget.nama;
      _nim = widget.nim;
    }

    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _resolveProdi(String prodiId) async {
    try {
      final prodiRes = await ApiClient.get(ApiConfig.getProdi);
      if (prodiRes['status'] == 'ok') {
        final List prodiList = prodiRes['data'] as List? ?? [];
        for (final p in prodiList) {
          final map = p as Map<String, dynamic>;
          if (map['id']?.toString() == prodiId) {
            _namaProdi = map['nama_prodi']?.toString() ?? '-';
            break;
          }
        }
      }
    } catch (_) {
      // biarkan '-'
    }
  }

  void _handlePlaceholder(String fitur) {
    AppToast.show(context, '$fitur akan segera hadir', isError: false);
  }

  Future<void> _logout() async {
    final konfirmasi = await showLogoutDialog(context);
    if (konfirmasi != true) return;

    await AuthService.logout();
    // Tunggu animasi dialog selesai sebelum destroy rute
    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }


  void _openChangePassword() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChangePasswordPage(
          userId: widget.userId,
          nama: widget.nama,
          username: widget.username,
          role: 'user',
          nim: widget.nim,
          isForced: false,
        ),
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
      bottomNavigationBar: MahasiswaNavHelper.buildNav(
        context: context,
        currentIndex: _navIndex,
        userId: widget.userId,
        nama: widget.nama,
        username: widget.username,
        nim: widget.nim,
      ),
    );
  }

  // ---- Header ----
  Widget _buildTopBar() {
    return Row(
      children: [
        IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_rounded, color: AppColorsSoft.navy),
        ),
        const Text(
          'Portal Akademik',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppColorsSoft.navy,
          ),
        ),
        const Spacer(),
        IconButton(
          onPressed: () => _handlePlaceholder('Notifikasi'),
          icon: const Icon(
            Icons.notifications_none_rounded,
            color: AppColorsSoft.navy,
          ),
        ),
      ],
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
          gradient: LinearGradient(
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
                _nama.isNotEmpty ? _nama[0].toUpperCase() : 'M',
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

  // ---- Nama, NIM, Prodi ----
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
          _nim,
          style: const TextStyle(
            fontSize: 14,
            color: AppColorsSoft.textGray,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          _namaProdi.toUpperCase(),
          style: const TextStyle(
            fontSize: 12,
            color: AppColorsSoft.textGrayLight,
            fontWeight: FontWeight.w700,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }

  // ---- Card Informasi Mahasiswa ----
  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: AppColorsSoft.card(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Informasi Mahasiswa',
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
            label: 'NIM',
            value: _nim,
          ),
          _divider(),
          _infoRow(
            icon: Icons.school_rounded,
            iconBg: const Color(0xFFEEE3FF),
            iconColor: const Color(0xFF8B5CF6),
            label: 'Program Studi',
            value: _namaProdi,
          ),
          _divider(),
          _infoRow(
            icon: Icons.location_on_outlined,
            iconBg: const Color(0xFFD9F5E4),
            iconColor: const Color(0xFF12A150),
            label: 'Alamat',
            value: _alamat,
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
    return Divider(
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
            onTap: _openChangePassword,
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
          Divider(
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
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFE0E0),
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
