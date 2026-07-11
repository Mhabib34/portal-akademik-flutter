import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../config/api_config.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../widgets/soft_bottom_nav.dart';
import 'login_page.dart';

// ============================================================
// dosen_home_page.dart — Dashboard Dosen
// ============================================================

class DosenHomePage extends StatefulWidget {
  final String userId;
  final String nama;
  final String username;

  const DosenHomePage({
    super.key,
    required this.userId,
    required this.nama,
    required this.username,
  });

  @override
  State<DosenHomePage> createState() => _DosenHomePageState();
}

class _DosenHomePageState extends State<DosenHomePage> {
  int _navIndex = 0;
  bool _isLoading = true;
  String _dosenId = '';
  String _totalKelas = '-';

  final List<SoftNavItem> _navItems = const [
    SoftNavItem(icon: Icons.home_rounded, label: 'Beranda'),
    SoftNavItem(icon: Icons.calendar_month_rounded, label: 'Jadwal'),
    SoftNavItem(icon: Icons.star_rounded, label: 'Nilai'),
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
      final profil = await ApiClient.get(ApiConfig.getDosen);
      if (profil['status'] == 'ok') {
        final data = profil['data'] as Map<String, dynamic>;
        _dosenId = data['id']?.toString() ?? '';
      }

      if (_dosenId.isNotEmpty) {
        final kelas = await ApiClient.get(
          ApiConfig.getKelas,
          queryParams: {'dosen_id': _dosenId},
        );
        if (kelas['status'] == 'ok') {
          _totalKelas = '${kelas['total'] ?? 0}';
        }
      }
    } catch (_) {
      // biarkan tampil '-' kalau gagal
    }

    if (mounted) setState(() => _isLoading = false);
  }

  void _handlePlaceholder(String fitur) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$fitur akan segera hadir'),
        backgroundColor: AppColorsSoft.navy,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
    if (index == 3) {
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
          child: RefreshIndicator(
            color: AppColorsSoft.navy,
            onRefresh: _loadData,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 110),
              children: [
                _buildTopBar(),
                const SizedBox(height: 20),
                Text(
                  'Selamat Datang,\n${widget.nama}',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: AppColorsSoft.navy,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 20),
                _buildStatCard(),
                const SizedBox(height: 28),
                const Row(
                  children: [
                    Icon(
                      Icons.dashboard_customize_rounded,
                      size: 18,
                      color: AppColorsSoft.navy,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Menu Dosen',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColorsSoft.navy,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildMenuGrid(),
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
              widget.nama.isNotEmpty ? widget.nama[0].toUpperCase() : 'D',
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

  Widget _buildStatCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: AppColorsSoft.card(),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFDCEBFF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.class_rounded,
              color: Color(0xFF2E6FE0),
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _isLoading ? '...' : _totalKelas,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppColorsSoft.navy,
                ),
              ),
              const Text(
                'Kelas Diampu Semester Ini',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColorsSoft.textGray,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMenuGrid() {
    final menu = [
      _DosenMenuData(
        Icons.calendar_month_rounded,
        'Jadwal Mengajar',
        const Color(0xFFDCEBFF),
        const Color(0xFF2E6FE0),
      ),
      _DosenMenuData(
        Icons.edit_note_rounded,
        'Input Nilai',
        const Color(0xFFFFF6D6),
        const Color(0xFFCBA400),
      ),
      _DosenMenuData(
        Icons.groups_rounded,
        'Daftar Mahasiswa',
        const Color(0xFFD9F5E4),
        const Color(0xFF12A150),
      ),
      _DosenMenuData(
        Icons.person_rounded,
        'Profil Saya',
        const Color(0xFFEEE3FF),
        const Color(0xFF8B5CF6),
      ),
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 14,
      crossAxisSpacing: 14,
      childAspectRatio: 1.4,
      children: menu
          .map(
            (m) => InkWell(
              onTap: () => _handlePlaceholder(m.label),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: AppColorsSoft.card(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: m.iconBg,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(m.icon, size: 18, color: m.iconColor),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      m.label,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: AppColorsSoft.navy,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _DosenMenuData {
  final IconData icon;
  final String label;
  final Color iconBg;
  final Color iconColor;
  const _DosenMenuData(this.icon, this.label, this.iconBg, this.iconColor);
}
