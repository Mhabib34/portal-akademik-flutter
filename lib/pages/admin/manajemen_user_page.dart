import 'package:flutter/material.dart';
import '../../widgets/admin_nav_helper.dart';
import '../../widgets/custom_top_bar.dart';

import '../../theme/app_theme.dart';
import '../../config/api_config.dart';
import '../../services/api_client.dart';
import './master/data_dosen_page.dart';
import './master/data_mahasiswa_page.dart';
import '../../utils/app_toast.dart';

// ============================================================
// manajemen_user_page.dart — Manajemen User (Admin)
//   Gabungan akun Dosen + Mahasiswa (role 'user' di database).
//   CATATAN PENTING (sesuai kesepakatan):
//   - Tab "Admin" TIDAK ada karena spec tidak punya endpoint untuk
//     akun admin sama sekali (tidak ada get_admin.php / CRUD-nya).
//   - Tidak ada field `username` di schema Mahasiswa/Dosen, jadi
//     "@username" di UI memakai NIM (mahasiswa) / NIDN (dosen)
//     sebagai gantinya — BUKAN username asli hasil generate backend.
//   - get_mahasiswa.php & get_dosen.php tidak punya parameter
//     pagination, jadi data di-fetch sekali lalu di-render dengan
//     lazy loading (infinite scroll) di client biar tetap ringan.
//   - Tombol "+" membuka pilihan Tambah Dosen / Tambah Mahasiswa,
//     yang masing2 diarahkan ke halaman Data Dosen / Data
//     Mahasiswa yang sudah ada form tambahnya.
// ============================================================

enum _RoleFilter { semua, dosen, mahasiswa }

class ManajemenUserPage extends StatefulWidget {
  final String nama;
  const ManajemenUserPage({super.key, required this.nama});

  @override
  State<ManajemenUserPage> createState() => _ManajemenUserPageState();
}

class _ManajemenUserPageState extends State<ManajemenUserPage> {
  bool _isLoading = true;
  String _searchQuery = '';
  _RoleFilter _filter = _RoleFilter.semua;

  List<Map<String, dynamic>> _allUsers = []; // gabungan dosen + mahasiswa
  int _visibleCount = 20;
  final ScrollController _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
    _loadData();
  }

  @override
  void dispose() {
    _scrollCtrl.removeListener(_onScroll);
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels >=
        _scrollCtrl.position.maxScrollExtent - 300) {
      if (_visibleCount < _filteredUsers.length) {
        setState(() => _visibleCount += 20);
      }
    }
  }

  List<Map<String, dynamic>> get _filteredUsers {
    var list = _allUsers;
    if (_filter == _RoleFilter.dosen) {
      list = list.where((u) => u['_role'] == 'dosen').toList();
    } else if (_filter == _RoleFilter.mahasiswa) {
      list = list.where((u) => u['_role'] == 'mahasiswa').toList();
    }
    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.trim().toLowerCase();
      list = list.where((u) {
        final nama = (u['nama'] ?? '').toString().toLowerCase();
        final identifier =
            (u['_role'] == 'dosen' ? u['nidn'] : u['nim'])
                ?.toString()
                .toLowerCase() ??
            '';
        return nama.contains(q) || identifier.contains(q);
      }).toList();
    }
    return list;
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _visibleCount = 20;
    });

    try {
      final results = await Future.wait([
        ApiClient.get(ApiConfig.getDosen),
        ApiClient.get(ApiConfig.getMahasiswa),
      ]);

      final dosenRes = results[0];
      final mhsRes = results[1];

      final merged = <Map<String, dynamic>>[];

      if (dosenRes['status'] == 'ok') {
        final List list = dosenRes['data'] as List? ?? [];
        merged.addAll(
          list.map((e) {
            final map = Map<String, dynamic>.from(e as Map);
            map['_role'] = 'dosen';
            return map;
          }),
        );
      }

      if (mhsRes['status'] == 'ok') {
        final List list = mhsRes['data'] as List? ?? [];
        merged.addAll(
          list.map((e) {
            final map = Map<String, dynamic>.from(e as Map);
            map['_role'] = 'mahasiswa';
            return map;
          }),
        );
      }

      _allUsers = merged;
    } catch (_) {
      if (mounted) {
        AppToast.show(context, 'Gagal memuat data user', isError: true);
      }
    }

    if (mounted) setState(() => _isLoading = false);
  }

  void _showSnack(String message, {bool isError = false}) {
    AppToast.show(context, message, isError: isError);
  }

  Future<void> _toggleStatus(Map<String, dynamic> user) async {
    final userId = user['user_id']?.toString() ?? '';
    if (userId.isEmpty) return;

    try {
      final res = await ApiClient.postForm(
        ApiConfig.toggleAktif,
        body: {'user_id': userId},
      );
      if (res['status'] == 'ok') {
        _showSnack('Status ${user['nama']} berhasil diubah');
        _loadData();
      } else {
        _showSnack(
          res['message']?.toString() ?? 'Gagal mengubah status',
          isError: true,
        );
      }
    } catch (_) {
      _showSnack('Gagal terhubung ke server', isError: true);
    }
  }

  Future<void> _confirmResetPassword(Map<String, dynamic> user) async {
    final userId = user['user_id']?.toString() ?? '';
    if (userId.isEmpty) return;

    final identifier = user['_role'] == 'dosen' ? user['nidn'] : user['nim'];

    final konfirmasi = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Reset Password'),
        content: Text(
          'Password ${user['nama']} akan direset ke ${user['_role'] == 'dosen' ? 'NIDN' : 'NIM'} ($identifier). Lanjutkan?',
        ),
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
            child: const Text('Reset'),
          ),
        ],
      ),
    );

    if (konfirmasi != true) return;

    try {
      final res = await ApiClient.postForm(
        ApiConfig.resetPassword,
        body: {'user_id': userId},
      );
      if (res['status'] == 'ok') {
        _showSnack('Password ${user['nama']} berhasil direset');
      } else {
        _showSnack(
          res['message']?.toString() ?? 'Gagal reset password',
          isError: true,
        );
      }
    } catch (_) {
      _showSnack('Gagal terhubung ke server', isError: true);
    }
  }

  Future<void> _confirmDelete(Map<String, dynamic> user) async {
    final isDosen = user['_role'] == 'dosen';

    final konfirmasi = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Hapus User'),
        content: Text(
          'Yakin ingin menghapus ${user['nama']}? Akun login user ini juga akan dihapus.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE05252),
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (konfirmasi != true) return;

    try {
      final res = await ApiClient.postForm(
        isDosen ? ApiConfig.deleteDosen : ApiConfig.deleteMahasiswa,
        body: {'id': user['id'].toString()},
      );
      if (res['status'] == 'ok') {
        _showSnack('${user['nama']} berhasil dihapus');
        _loadData();
      } else {
        _showSnack(
          res['message']?.toString() ?? 'Gagal menghapus data',
          isError: true,
        );
      }
    } catch (_) {
      _showSnack('Gagal terhubung ke server', isError: true);
    }
  }

  void _openAddChoice() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        decoration: const BoxDecoration(
          color: AppColorsSoft.cardWhite,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 18),
                decoration: BoxDecoration(
                  color: AppColorsSoft.fieldFill,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const Text(
              'Tambah User Baru',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColorsSoft.navy,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              onTap: () {
                Navigator.pop(ctx);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => DataDosenPage(nama: widget.nama)),
                ).then((_) => _loadData());
              },
              leading: const CircleAvatar(
                backgroundColor: Color(0xFFEEE3FF),
                child: Icon(Icons.person_2_rounded, color: Color(0xFF8B5CF6)),
              ),
              title: const Text(
                'Tambah Dosen',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              tileColor: AppColorsSoft.fieldFill,
            ),
            const SizedBox(height: 10),
            ListTile(
              onTap: () {
                Navigator.pop(ctx);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => DataMahasiswaPage(nama: widget.nama)),
                ).then((_) => _loadData());
              },
              leading: const CircleAvatar(
                backgroundColor: Color(0xFFD9F5E4),
                child: Icon(Icons.people_alt_rounded, color: Color(0xFF12A150)),
              ),
              title: const Text(
                'Tambah Mahasiswa',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              tileColor: AppColorsSoft.fieldFill,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final visibleList = _filteredUsers.take(_visibleCount).toList();

    return Scaffold(
      bottomNavigationBar: AdminNavHelper.buildNav(context: context, currentIndex: -1),
      body: Container(
        decoration: BoxDecoration(gradient: AppColorsSoft.backgroundGradient),
        child: SafeArea(
          child: RefreshIndicator(
            color: AppColorsSoft.navy,
            onRefresh: _loadData,
            child: ListView(
              controller: _scrollCtrl,
              padding: const EdgeInsets.fromLTRB(0, 16, 0, 24),
              children: [
                CustomTopBar(
                  title: 'Manajemen User',
                  nama: widget.nama,
                  onBack: () => Navigator.pop(context),
                  trailing: GestureDetector(
                    onTap: _openAddChoice,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        color: AppColorsSoft.navy,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.add_rounded, color: Colors.white),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 10),
                      _buildSearchBar(),
                      const SizedBox(height: 14),
                      _buildFilterChips(),
                      const SizedBox(height: 18),
                      if (_isLoading)
                        const Padding(
                          padding: EdgeInsets.only(top: 40),
                          child: Center(
                            child: CircularProgressIndicator(
                              color: AppColorsSoft.navy,
                            ),
                          ),
                        )
                      else if (visibleList.isEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 40),
                          child: Center(
                            child: Text(
                              _searchQuery.isEmpty
                                  ? 'Belum ada data user'
                                  : 'User tidak ditemukan',
                              style: const TextStyle(color: AppColorsSoft.textGray),
                            ),
                          ),
                        )
                      else ...[
                        ...visibleList.map(_buildUserCard),
                        if (_visibleCount < _filteredUsers.length)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            child: Center(
                              child: CircularProgressIndicator(
                                color: AppColorsSoft.navy,
                              ),
                            ),
                          ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: AppColorsSoft.card(),
      child: TextField(
        onChanged: (v) => setState(() {
          _searchQuery = v;
          _visibleCount = 20;
        }),
        decoration: InputDecoration(
          hintText: 'Cari nama atau NIM/NIDN...',
          hintStyle: const TextStyle(
            color: AppColorsSoft.textGrayLight,
            fontSize: 14,
          ),
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: AppColorsSoft.textGray,
            size: 20,
          ),
          filled: true,
          fillColor: Colors.transparent,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(28),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    Widget chip(String label, _RoleFilter value) {
      final selected = _filter == value;
      return GestureDetector(
        onTap: () => setState(() {
          _filter = value;
          _visibleCount = 20;
        }),
        child: Container(
          margin: const EdgeInsets.only(right: 10),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          decoration: BoxDecoration(
            color: selected ? AppColorsSoft.navy : AppColorsSoft.cardWhite,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: AppColorsSoft.navy.withOpacity(0.06),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: selected ? Colors.white : AppColorsSoft.navy,
            ),
          ),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          chip('Semua', _RoleFilter.semua),
          chip('Dosen', _RoleFilter.dosen),
          chip('Mahasiswa', _RoleFilter.mahasiswa),
        ],
      ),
    );
  }

  Widget _buildUserCard(Map<String, dynamic> user) {
    final isDosen = user['_role'] == 'dosen';
    final nama = user['nama']?.toString() ?? '-';
    final identifier = isDosen
        ? user['nidn']?.toString() ?? '-'
        : user['nim']?.toString() ?? '-';
    final isActive = int.tryParse(user['is_active']?.toString() ?? '0') == 1;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: AppColorsSoft.card(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: isDosen
                    ? AppColorsSoft.gradientLavender
                    : AppColorsSoft.gradientPeach,
                child: Text(
                  nama.isNotEmpty ? nama[0].toUpperCase() : '?',
                  style: const TextStyle(
                    color: AppColorsSoft.navy,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nama,
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: AppColorsSoft.navy,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '@$identifier',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColorsSoft.textGray,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: isDosen
                      ? const Color(0xFF2E6FE0).withOpacity(0.12)
                      : const Color(0xFF12A150).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isDosen ? 'Dosen' : 'Mahasiswa',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: isDosen
                        ? const Color(0xFF2E6FE0)
                        : const Color(0xFF12A150),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _iconCircleButton(
                icon: Icons.restore_rounded,
                onTap: () => _confirmResetPassword(user),
              ),
              const SizedBox(width: 8),
              _iconCircleButton(
                icon: Icons.delete_outline_rounded,
                iconColor: const Color(0xFFE05252),
                onTap: () => _confirmDelete(user),
              ),
              const Spacer(),
              const Text(
                'Aktif',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColorsSoft.textGray,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 6),
              Transform.scale(
                scale: 0.8,
                child: Switch(
                  value: isActive,
                  activeColor: AppColorsSoft.navy,
                  onChanged: (_) => _toggleStatus(user),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _iconCircleButton({
    required IconData icon,
    required VoidCallback onTap,
    Color iconColor = AppColorsSoft.navy,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 34,
        height: 34,
        decoration: const BoxDecoration(
          color: AppColorsSoft.fieldFill,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 16, color: iconColor),
      ),
    );
  }
}
