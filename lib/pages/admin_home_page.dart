import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../config/api_config.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../widgets/soft_bottom_nav.dart';
import 'login_page.dart';
import 'data_dosen_page.dart';
import 'data_mahasiswa_page.dart';

// ============================================================
// admin_home_page.dart — Dashboard Admin
// ============================================================

class AdminHomePage extends StatefulWidget {
  final String userId;
  final String nama;
  final String username;

  const AdminHomePage({
    super.key,
    required this.userId,
    required this.nama,
    required this.username,
  });

  @override
  State<AdminHomePage> createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage> {
  int _navIndex = 0;
  bool _isLoading = true;

  String _totalMahasiswa = '-';
  String _totalDosen = '-';
  String _totalMataKuliah = '-';
  String _krsMenunggu = '-';

  final List<SoftNavItem> _navItems = const [
    SoftNavItem(icon: Icons.home_rounded, label: 'Beranda'),
    SoftNavItem(icon: Icons.calendar_month_rounded, label: 'Jadwal'),
    SoftNavItem(icon: Icons.storage_rounded, label: 'Data'),
    SoftNavItem(icon: Icons.person_rounded, label: 'Profil'),
  ];

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _isLoading = true);

    await Future.wait([
      _fetchTotal(ApiConfig.getMahasiswa, (v) => _totalMahasiswa = v),
      _fetchTotal(ApiConfig.getDosen, (v) => _totalDosen = v),
      _fetchTotal(ApiConfig.getMataKuliah, (v) => _totalMataKuliah = v),
      _fetchTotal(
        ApiConfig.getKrs,
        (v) => _krsMenunggu = v,
        queryParams: {'status': 'menunggu'},
      ),
    ]);

    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _fetchTotal(
    String url,
    void Function(String) onValue, {
    Map<String, String>? queryParams,
  }) async {
    try {
      final data = await ApiClient.get(url, queryParams: queryParams);
      if (data['status'] == 'ok') {
        onValue('${data['total'] ?? 0}');
      }
    } catch (_) {
      // biarkan tampil '-' kalau salah satu request gagal,
      // jangan bikin seluruh dashboard error
    }
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
            onRefresh: _loadStats,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 110),
              children: [
                _buildTopBar(),
                const SizedBox(height: 20),
                _buildGreeting(),
                const SizedBox(height: 24),
                _buildStatsGrid(),
                const SizedBox(height: 28),
                _buildSectionTitle(),
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
              widget.nama.isNotEmpty ? widget.nama[0].toUpperCase() : 'A',
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

  Widget _buildGreeting() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Selamat Datang,\n${widget.nama}',
          style: const TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: AppColorsSoft.navy,
            height: 1.25,
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'Kelola aktivitas akademik harian Anda dengan mudah. '
          'Pantau statistik mahasiswa, dosen, dan mata kuliah secara real-time.',
          style: TextStyle(
            fontSize: 13.5,
            color: AppColorsSoft.textGray,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildStatsGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 14,
      crossAxisSpacing: 14,
      childAspectRatio: 1.15,
      children: [
        _StatCard(
          icon: Icons.school_rounded,
          iconBg: const Color(0xFFDCEBFF),
          iconColor: const Color(0xFF2E6FE0),
          tagText: 'AKTIF',
          tagColor: const Color(0xFF2E6FE0),
          label: 'TOTAL\nMAHASISWA',
          value: _isLoading ? '...' : _totalMahasiswa,
        ),
        _StatCard(
          icon: Icons.groups_rounded,
          iconBg: const Color(0xFFEEE3FF),
          iconColor: const Color(0xFF8B5CF6),
          tagText: 'TETAP',
          tagColor: const Color(0xFF8B5CF6),
          label: 'TOTAL DOSEN',
          value: _isLoading ? '...' : _totalDosen,
        ),
        _StatCard(
          icon: Icons.menu_book_rounded,
          iconBg: const Color(0xFFFFE8CC),
          iconColor: const Color(0xFFE08A00),
          tagText: 'SMT GANJIL',
          tagColor: const Color(0xFFE08A00),
          label: 'MATA KULIAH',
          value: _isLoading ? '...' : _totalMataKuliah,
        ),
        _StatCard(
          icon: Icons.warning_rounded,
          iconBg: const Color(0xFFFFE0E0),
          iconColor: const Color(0xFFE05252),
          tagText: 'URGENT',
          tagColor: const Color(0xFFE05252),
          label: 'KRS MENUNGGU',
          value: _isLoading ? '...' : _krsMenunggu,
        ),
      ],
    );
  }

  Widget _buildSectionTitle() {
    return const Row(
      children: [
        Icon(Icons.settings_rounded, size: 18, color: AppColorsSoft.navy),
        SizedBox(width: 8),
        Text(
          'Manajemen Sistem',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: AppColorsSoft.navy,
          ),
        ),
      ],
    );
  }

  Widget _buildMenuGrid() {
    final menu = [
      _MenuData(
        Icons.people_alt_rounded,
        'Data Mahasiswa',
        const Color(0xFFDCEBFF),
        const Color(0xFF2E6FE0),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const DataMahasiswaPage()),
        ),
      ),
      _MenuData(
        Icons.person_2_rounded,
        'Data Dosen',
        const Color(0xFFEEE3FF),
        const Color(0xFF8B5CF6),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const DataDosenPage()),
        ),
      ),
      _MenuData(
        Icons.menu_book_rounded,
        'Data Mata Kuliah',
        const Color(0xFFFFE8CC),
        const Color(0xFFE08A00),
        onTap: () => _handlePlaceholder('Data Mata Kuliah'),
      ),
      _MenuData(
        Icons.event_note_rounded,
        'Penjadwalan',
        const Color(0xFFD9F5E4),
        const Color(0xFF12A150),
        onTap: () => _handlePlaceholder('Penjadwalan'),
      ),
      _MenuData(
        Icons.fact_check_rounded,
        'Persetujuan KRS',
        const Color(0xFFFFE0E0),
        const Color(0xFFE05252),
        onTap: () => _handlePlaceholder('Persetujuan KRS'),
      ),
      _MenuData(
        Icons.star_rounded,
        'Nilai',
        const Color(0xFFFFF6D6),
        const Color(0xFFCBA400),
        onTap: () => _handlePlaceholder('Nilai'),
      ),
      _MenuData(
        Icons.manage_accounts_rounded,
        'User',
        const Color(0xFFD9F5E4),
        const Color(0xFF12A150),
        onTap: () => _handlePlaceholder('User'),
      ),
      _MenuData(
        Icons.more_horiz_rounded,
        'Lainnya',
        const Color(0xFFE9E9EF),
        const Color(0xFF6B7280),
        onTap: () => _handlePlaceholder('Lainnya'),
      ),
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 14,
      crossAxisSpacing: 14,
      childAspectRatio: 1.4,
      children: menu.map((m) => _MenuTile(data: m, onTap: m.onTap)).toList(),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String tagText;
  final Color tagColor;
  final String label;
  final String value;

  const _StatCard({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.tagText,
    required this.tagColor,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppColorsSoft.card(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 18, color: iconColor),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: tagColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  tagText,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: tagColor,
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10.5,
              color: AppColorsSoft.textGray,
              fontWeight: FontWeight.w600,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: AppColorsSoft.navy,
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuData {
  final IconData icon;
  final String label;
  final Color iconBg;
  final Color iconColor;
  final VoidCallback onTap;
  const _MenuData(
    this.icon,
    this.label,
    this.iconBg,
    this.iconColor, {
    required this.onTap,
  });
}

class _MenuTile extends StatelessWidget {
  final _MenuData data;
  final VoidCallback onTap;

  const _MenuTile({required this.data, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
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
                color: data.iconBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(data.icon, size: 18, color: data.iconColor),
            ),
            const SizedBox(height: 10),
            Text(
              data.label,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: AppColorsSoft.navy,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
