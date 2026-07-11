import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../config/api_config.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../models/mahasiswa_model.dart';
import '../widgets/soft_bottom_nav.dart';
import 'change_password.dart';
import 'login_page.dart';

// ============================================================
// mahasiswa_home_page.dart — Dashboard Mahasiswa
// ============================================================

class MahasiswaHomePage extends StatefulWidget {
  final String userId;
  final String nama;
  final String username;
  final String nim;

  const MahasiswaHomePage({
    super.key,
    required this.userId,
    required this.nama,
    required this.username,
    required this.nim,
  });

  @override
  State<MahasiswaHomePage> createState() => _MahasiswaHomePageState();
}

class _MahasiswaHomePageState extends State<MahasiswaHomePage> {
  int _navIndex = 0;
  bool _isLoading = true;
  Mahasiswa? _myData;

  final List<SoftNavItem> _navItems = const [
    SoftNavItem(icon: Icons.home_rounded, label: 'Beranda'),
    SoftNavItem(icon: Icons.calendar_month_rounded, label: 'Jadwal'),
    SoftNavItem(icon: Icons.star_rounded, label: 'Nilai'),
    SoftNavItem(icon: Icons.assignment_rounded, label: 'KRS'),
    SoftNavItem(icon: Icons.person_rounded, label: 'Profil'),
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final data = await ApiClient.get(ApiConfig.getMahasiswa);
      if (data['status'] == 'ok') {
        _myData = Mahasiswa.fromJson(data['data'] as Map<String, dynamic>);
      }
    } catch (_) {
      _showSnackBar('Gagal memuat data profil', isError: true);
    }
    if (mounted) setState(() => _isLoading = false);
  }

  void _handlePlaceholder(String fitur) {
    _showSnackBar('$fitur akan segera hadir');
  }

  void _showSnackBar(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? const Color(0xFFE05252) : AppColorsSoft.navy,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _goToChangePassword() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChangePasswordPage(
          userId: widget.userId,
          nama: widget.nama,
          username: widget.username,
          role: 'user',
          nim: widget.nim,
        ),
      ),
    );
  }

  Future<void> _logout() async {
    final konfirmasi = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Keluar dari Portal'),
        content: const Text('Anda yakin ingin keluar?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColorsSoft.navy,
            ),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );

    if (konfirmasi != true) return;

    await AuthService.logout();
    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  void _onNavTap(int index) {
    if (index == 0) {
      setState(() => _navIndex = 0);
      return;
    }
    if (index == 4) {
      _logout();
      return;
    }
    _handlePlaceholder(_navItems[index].label);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: Container(
        decoration: BoxDecoration(gradient: AppColorsSoft.backgroundGradient),
        child: SafeArea(
          bottom: false,
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: AppColorsSoft.navy),
                )
              : RefreshIndicator(
                  color: AppColorsSoft.navy,
                  onRefresh: _loadData,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 110),
                    children: [
                      _buildTopBar(),
                      const SizedBox(height: 20),
                      _buildGreetingCard(),
                      const SizedBox(height: 20),
                      _buildBiodataCard(),
                      const SizedBox(height: 16),
                      _buildGantiPasswordBtn(),
                    ],
                  ),
                ),
        ),
      ),
      bottomNavigationBar: SoftBottomNav(
        items: _navItems,
        currentIndex: _navIndex,
        onTap: _onNavTap,
      ),
    );
  }

  Widget _buildTopBar() {
    return Row(
      children: [
        const Text(
          'Portal Akademik',
          style: TextStyle(
            fontSize: 14,
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
        GestureDetector(
          onTap: _logout,
          child: CircleAvatar(
            radius: 18,
            backgroundColor: AppColorsSoft.navy,
            child: Text(
              widget.nama.isNotEmpty ? widget.nama[0].toUpperCase() : 'M',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGreetingCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColorsSoft.navy,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: Colors.white.withOpacity(0.15),
            child: const Icon(
              Icons.person_rounded,
              color: Colors.white,
              size: 30,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Selamat datang,',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 13,
                  ),
                ),
                Text(
                  widget.nama,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'NIM: ${widget.nim.isNotEmpty ? widget.nim : '-'}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBiodataCard() {
    final m = _myData;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppColorsSoft.card(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.assignment_ind_rounded,
                color: AppColorsSoft.navy,
                size: 20,
              ),
              SizedBox(width: 8),
              Text(
                'Biodata Akademik',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppColorsSoft.navy,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (m == null)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'Data tidak ditemukan',
                style: TextStyle(color: AppColorsSoft.textGray),
              ),
            )
          else ...[
            _BiodataRow(label: 'NIM', value: m.nim),
            _BiodataRow(label: 'Nama', value: m.nama),
            _BiodataRow(label: 'Jurusan', value: m.jurusan),
            _BiodataRow(
              label: 'Alamat',
              value: m.alamat.isNotEmpty ? m.alamat : '-',
            ),
            _BiodataRow(
              label: 'Status',
              value: m.isActive ? 'Aktif' : 'Nonaktif',
              valueColor: m.isActive
                  ? const Color(0xFF12A150)
                  : const Color(0xFFE05252),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildGantiPasswordBtn() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: OutlinedButton.icon(
        onPressed: _goToChangePassword,
        icon: const Icon(Icons.lock_open_rounded, size: 20),
        label: const Text('Ganti Password'),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColorsSoft.navy,
          side: const BorderSide(color: AppColorsSoft.navy, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
        ),
      ),
    );
  }
}

class _BiodataRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _BiodataRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: AppColorsSoft.textGray,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const Text(
            ' : ',
            style: TextStyle(color: AppColorsSoft.textGrayLight),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: valueColor ?? AppColorsSoft.navy,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
