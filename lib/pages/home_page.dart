import 'dart:convert';
import 'package:app_input/pages/change_password.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../theme/app_theme.dart';
import '../models/mahasiswa_model.dart';
import 'login_page.dart';

// ============================================================
// home_page.dart — Halaman Utama Portal Akademik
//   - Admin  : kelola mahasiswa (CRUD + reset pw + toggle aktif)
//   - Mahasiswa : lihat biodata + ganti password
// ============================================================

const String _baseUrl = 'http://10.10.1.159/flutter_api/';

class HomePage extends StatefulWidget {
  final String userId;
  final String nama;
  final String username;
  final String role;
  final String nim;

  const HomePage({
    super.key,
    required this.userId,
    required this.nama,
    required this.username,
    required this.role,
    required this.nim,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // ----------------------------------------------------------------
  // STATE
  // ----------------------------------------------------------------
  List<Mahasiswa> _allMahasiswa = [];
  List<Mahasiswa> _filtered = [];
  Mahasiswa? _myData;

  bool _isLoading = false;
  bool _apiOk = false;
  String _searchQuery = '';

  final _searchCtrl = TextEditingController();

  // ----------------------------------------------------------------
  // LIFECYCLE
  // ----------------------------------------------------------------
  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  // ----------------------------------------------------------------
  // DATA FETCHING
  // ----------------------------------------------------------------

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    // Cek koneksi API
    try {
      final r = await http
          .get(Uri.parse('${_baseUrl}cek_koneksi.php'))
          .timeout(const Duration(seconds: 10));
      final d = jsonDecode(r.body);
      _apiOk = d['status'] == 'ok';
    } catch (_) {
      _apiOk = false;
    }

    if (widget.role == 'admin') {
      await _fetchAllMahasiswa();
    } else {
      await _fetchMyData();
    }

    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _fetchAllMahasiswa() async {
    try {
      final r = await http
          .get(Uri.parse('${_baseUrl}get_mahasiswa.php?role=admin'))
          .timeout(const Duration(seconds: 15));
      final d = jsonDecode(r.body) as Map<String, dynamic>;
      if (d['status'] == 'ok') {
        final list = (d['data'] as List)
            .map((e) => Mahasiswa.fromJson(e as Map<String, dynamic>))
            .toList();
        setState(() {
          _allMahasiswa = list;
          _applySearch();
        });
      }
    } catch (e) {
      _showSnackBar('Gagal memuat data mahasiswa', isError: true);
    }
  }

  Future<void> _fetchMyData() async {
    try {
      final r = await http
          .get(
            Uri.parse(
              '${_baseUrl}get_mahasiswa.php?role=user&user_id=${widget.userId}',
            ),
          )
          .timeout(const Duration(seconds: 15));
      final d = jsonDecode(r.body) as Map<String, dynamic>;
      if (d['status'] == 'ok') {
        setState(() => _myData = Mahasiswa.fromJson(d['data']));
      }
    } catch (e) {
      _showSnackBar('Gagal memuat data profil', isError: true);
    }
  }

  void _applySearch() {
    final q = _searchQuery.toLowerCase();
    if (q.isEmpty) {
      _filtered = List.from(_allMahasiswa);
    } else {
      _filtered = _allMahasiswa.where((m) {
        return m.nim.toLowerCase().contains(q) ||
            m.nama.toLowerCase().contains(q) ||
            m.jurusan.toLowerCase().contains(q);
      }).toList();
    }
  }

  // ----------------------------------------------------------------
  // ADMIN ACTIONS
  // ----------------------------------------------------------------

  // Tambah mahasiswa
  Future<void> _showTambahDialog() async {
    final nimCtrl = TextEditingController();
    final namaCtrl = TextEditingController();
    final jurusanCtrl = TextEditingController();
    final alamatCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool saving = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Text('Tambah Mahasiswa', style: AppTextStyles.heading3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          content: SizedBox(
            width: 380,
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const _InfoBox(
                      'Username dan password awal akan diset sama dengan NIM',
                    ),
                    const SizedBox(height: 16),
                    _buildField(
                      nimCtrl,
                      'NIM *',
                      'Nomor Induk Mahasiswa',
                      Icons.badge_outlined,
                    ),
                    const SizedBox(height: 12),
                    _buildField(
                      namaCtrl,
                      'Nama *',
                      'Nama lengkap',
                      Icons.person_outline_rounded,
                    ),
                    const SizedBox(height: 12),
                    _buildField(
                      jurusanCtrl,
                      'Jurusan *',
                      'Program studi',
                      Icons.book_outlined,
                    ),
                    const SizedBox(height: 12),
                    _buildField(
                      alamatCtrl,
                      'Alamat',
                      'Alamat tinggal',
                      Icons.home_outlined,
                      maxLines: 2,
                      required: false,
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: saving ? null : () => Navigator.pop(ctx),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: saving
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;
                      setLocal(() => saving = true);
                      try {
                        final r = await http.post(
                          Uri.parse('${_baseUrl}simpan_mahasiswa.php'),
                          body: {
                            'nim': nimCtrl.text.trim(),
                            'nama': namaCtrl.text.trim(),
                            'jurusan': jurusanCtrl.text.trim(),
                            'alamat': alamatCtrl.text.trim(),
                          },
                        );
                        final d = jsonDecode(r.body);
                        if (!ctx.mounted) return;
                        Navigator.pop(ctx);
                        if (d['status'] == 'ok') {
                          _showSnackBar('Mahasiswa berhasil ditambahkan');
                          await _fetchAllMahasiswa();
                        } else {
                          _showSnackBar(d['message'] ?? 'Gagal', isError: true);
                        }
                      } catch (_) {
                        setLocal(() => saving = false);
                        _showSnackBar('Koneksi gagal', isError: true);
                      }
                    },
              style: ElevatedButton.styleFrom(minimumSize: const Size(100, 40)),
              child: saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
    Future.delayed(const Duration(milliseconds: 300), () {
      nimCtrl.dispose();
      namaCtrl.dispose();
      jurusanCtrl.dispose();
      alamatCtrl.dispose();
    });
  }

  // Edit mahasiswa
  Future<void> _showEditDialog(Mahasiswa m) async {
    final nimCtrl = TextEditingController(text: m.nim);
    final namaCtrl = TextEditingController(text: m.nama);
    final jurusanCtrl = TextEditingController(text: m.jurusan);
    final alamatCtrl = TextEditingController(text: m.alamat);
    final formKey = GlobalKey<FormState>();
    bool saving = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Text(
            'Edit Data Mahasiswa',
            style: AppTextStyles.heading3,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          content: SizedBox(
            width: 380,
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildField(nimCtrl, 'NIM *', '', Icons.badge_outlined),
                    const SizedBox(height: 12),
                    _buildField(
                      namaCtrl,
                      'Nama *',
                      '',
                      Icons.person_outline_rounded,
                    ),
                    const SizedBox(height: 12),
                    _buildField(
                      jurusanCtrl,
                      'Jurusan *',
                      '',
                      Icons.book_outlined,
                    ),
                    const SizedBox(height: 12),
                    _buildField(
                      alamatCtrl,
                      'Alamat',
                      '',
                      Icons.home_outlined,
                      maxLines: 2,
                      required: false,
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: saving ? null : () => Navigator.pop(ctx),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: saving
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;
                      setLocal(() => saving = true);
                      try {
                        final r = await http.post(
                          Uri.parse('${_baseUrl}update_mahasiswa.php'),
                          body: {
                            'id': m.id,
                            'nim': nimCtrl.text.trim(),
                            'nama': namaCtrl.text.trim(),
                            'jurusan': jurusanCtrl.text.trim(),
                            'alamat': alamatCtrl.text.trim(),
                          },
                        );
                        final d = jsonDecode(r.body);
                        if (!ctx.mounted) return;
                        Navigator.pop(ctx);
                        if (d['status'] == 'ok') {
                          _showSnackBar('Data berhasil diperbarui');
                          await _fetchAllMahasiswa();
                        } else {
                          _showSnackBar(d['message'] ?? 'Gagal', isError: true);
                        }
                      } catch (_) {
                        setLocal(() => saving = false);
                        _showSnackBar('Koneksi gagal', isError: true);
                      }
                    },
              style: ElevatedButton.styleFrom(minimumSize: const Size(100, 40)),
              child: saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
    nimCtrl.dispose();
    namaCtrl.dispose();
    jurusanCtrl.dispose();
    alamatCtrl.dispose();
  }

  // Hapus mahasiswa
  Future<void> _deleteMahasiswa(Mahasiswa m) async {
    final konfirmasi = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Konfirmasi Hapus', style: AppTextStyles.heading3),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Hapus data mahasiswa berikut?', style: AppTextStyles.body),
            const SizedBox(height: 12),
            _InfoBox('NIM: ${m.nim}\nNama: ${m.nama}', isWarning: true),
            const SizedBox(height: 8),
            const Text(
              'Tindakan ini akan menghapus data mahasiswa beserta akun loginnya dan tidak dapat dibatalkan.',
              style: TextStyle(fontSize: 12, color: AppColors.danger),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              minimumSize: const Size(100, 40),
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (konfirmasi != true) return;

    try {
      final r = await http.post(
        Uri.parse('${_baseUrl}delete_mahasiswa.php'),
        body: {'id': m.id},
      );
      final d = jsonDecode(r.body);
      if (d['status'] == 'ok') {
        _showSnackBar('Mahasiswa berhasil dihapus');
        await _fetchAllMahasiswa();
      } else {
        _showSnackBar(d['message'] ?? 'Gagal', isError: true);
      }
    } catch (_) {
      _showSnackBar('Koneksi gagal', isError: true);
    }
  }

  // Reset password
  Future<void> _resetPassword(Mahasiswa m) async {
    final konfirmasi = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset Password', style: AppTextStyles.heading3),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Reset password ${m.nama} (${m.nim}) ke NIM?\n\nMahasiswa akan diminta mengganti password saat login berikutnya.',
              style: AppTextStyles.body,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(minimumSize: const Size(100, 40)),
            child: const Text('Reset'),
          ),
        ],
      ),
    );

    if (konfirmasi != true) return;

    try {
      final r = await http.post(
        Uri.parse('${_baseUrl}reset_password.php'),
        body: {'user_id': m.userId},
      );
      final d = jsonDecode(r.body);
      _showSnackBar(
        d['status'] == 'ok'
            ? 'Password berhasil direset ke NIM'
            : (d['message'] ?? 'Gagal'),
        isError: d['status'] != 'ok',
      );
      if (d['status'] == 'ok') await _fetchAllMahasiswa();
    } catch (_) {
      _showSnackBar('Koneksi gagal', isError: true);
    }
  }

  // Toggle aktif/nonaktif
  Future<void> _toggleAktif(Mahasiswa m) async {
    final label = m.isActive ? 'nonaktifkan' : 'aktifkan';
    final konfirmasi = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          '${label[0].toUpperCase()}${label.substring(1)} Akun',
          style: AppTextStyles.heading3,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Text(
          '${'${label[0].toUpperCase()}${label.substring(1)}'} akun ${m.nama} (${m.nim})?',
          style: AppTextStyles.body,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: m.isActive
                  ? AppColors.warning
                  : AppColors.success,
              minimumSize: const Size(100, 40),
            ),
            child: Text('${label[0].toUpperCase()}${label.substring(1)}'),
          ),
        ],
      ),
    );

    if (konfirmasi != true) return;

    try {
      final r = await http.post(
        Uri.parse('${_baseUrl}toggle_aktif.php'),
        body: {'user_id': m.userId},
      );
      final d = jsonDecode(r.body);
      _showSnackBar(
        d['status'] == 'ok' ? d['message'] : (d['message'] ?? 'Gagal'),
        isError: d['status'] != 'ok',
      );
      if (d['status'] == 'ok') await _fetchAllMahasiswa();
    } catch (_) {
      _showSnackBar('Koneksi gagal', isError: true);
    }
  }

  // ----------------------------------------------------------------
  // MAHASISWA: Ganti Password (dari profil)
  // ----------------------------------------------------------------
  void _goToChangePassword() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChangePasswordPage(
          userId: widget.userId,
          nama: widget.nama,
          username: widget.username,
          role: widget.role,
          nim: widget.nim,
        ),
      ),
    );
  }

  // ----------------------------------------------------------------
  // LOGOUT
  // ----------------------------------------------------------------
  Future<void> _logout() async {
    final konfirmasi = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Keluar dari Portal', style: AppTextStyles.heading3),
        content: const Text('Anda yakin ingin keluar?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(minimumSize: const Size(80, 40)),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );

    if (konfirmasi == true && mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (route) => false,
      );
    }
  }

  // ----------------------------------------------------------------
  // HELPERS
  // ----------------------------------------------------------------
  void _showSnackBar(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? AppColors.danger : AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  static TextFormField _buildField(
    TextEditingController ctrl,
    String label,
    String hint,
    IconData icon, {
    int maxLines = 1,
    bool required = true,
  }) {
    return TextFormField(
      controller: ctrl,
      maxLines: maxLines,
      decoration: AppDecorations.inputDecoration(
        label: label,
        hint: hint,
        prefixIcon: icon,
      ),
      validator: required
          ? (v) => (v == null || v.trim().isEmpty)
                ? '${label.replaceAll(' *', '')} wajib diisi'
                : null
          : null,
    );
  }

  // ----------------------------------------------------------------
  // BUILD
  // ----------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(),
      floatingActionButton: widget.role == 'admin'
          ? FloatingActionButton.extended(
              onPressed: _showTambahDialog,
              icon: const Icon(Icons.person_add_rounded),
              label: const Text('Tambah Mahasiswa'),
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.white,
            )
          : null,
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : RefreshIndicator(
              color: AppColors.primary,
              onRefresh: _loadData,
              child: widget.role == 'admin'
                  ? _buildAdminView()
                  : _buildMahasiswaView(),
            ),
    );
  }

  // --- AppBar ---
  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.primary,
      automaticallyImplyLeading: false,
      title: Row(
        children: [
          const Icon(Icons.school_rounded, color: AppColors.white, size: 22),
          const SizedBox(width: 8),
          const Text(
            'Portal Akademik',
            style: TextStyle(
              color: AppColors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
      actions: [
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              widget.nama,
              style: const TextStyle(
                color: AppColors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: widget.role == 'admin'
                    ? AppColors.warning
                    : AppColors.success,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                widget.role.toUpperCase(),
                style: const TextStyle(
                  color: AppColors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(width: 8),
        IconButton(
          onPressed: _logout,
          icon: const Icon(Icons.logout_rounded, color: AppColors.white),
          tooltip: 'Keluar',
        ),
        const SizedBox(width: 4),
      ],
    );
  }

  // ================================================================
  // ADMIN VIEW
  // ================================================================
  Widget _buildAdminView() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildAdminStats(),
        const SizedBox(height: 16),
        _buildSearchBar(),
        const SizedBox(height: 16),
        _buildMahasiswaList(),
        const SizedBox(height: 80), // ruang FAB
      ],
    );
  }

  // Stats Card
  Widget _buildAdminStats() {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: Icons.people_alt_rounded,
            label: 'Total Mahasiswa',
            value: '${_allMahasiswa.length}',
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            icon: Icons.how_to_reg_rounded,
            label: 'Akun Aktif',
            value: '${_allMahasiswa.where((m) => m.isActive).length}',
            color: AppColors.success,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            icon: _apiOk ? Icons.cloud_done_rounded : Icons.cloud_off_rounded,
            label: 'Status API',
            value: _apiOk ? 'Online' : 'Offline',
            color: _apiOk ? AppColors.success : AppColors.danger,
          ),
        ),
      ],
    );
  }

  // Search Bar
  Widget _buildSearchBar() {
    return Container(
      decoration: AppDecorations.card(),
      child: TextField(
        controller: _searchCtrl,
        decoration: InputDecoration(
          hintText: 'Cari NIM, nama, atau jurusan...',
          hintStyle: TextStyle(color: AppColors.textLight, fontSize: 13),
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: AppColors.primaryMed,
            size: 20,
          ),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(
                    Icons.clear_rounded,
                    color: AppColors.textLight,
                    size: 18,
                  ),
                  onPressed: () {
                    _searchCtrl.clear();
                    setState(() {
                      _searchQuery = '';
                      _applySearch();
                    });
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: AppColors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
        onChanged: (v) {
          setState(() {
            _searchQuery = v;
            _applySearch();
          });
        },
      ),
    );
  }

  // ----------------------------------------------------------------
  // CARD LIST — menggantikan tabel yang overflow di layar sempit
  // ----------------------------------------------------------------
  Widget _buildMahasiswaList() {
    if (_filtered.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(40),
        decoration: AppDecorations.card(),
        child: Column(
          children: [
            Icon(
              Icons.people_outline_rounded,
              size: 60,
              color: AppColors.textLight,
            ),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isEmpty
                  ? 'Belum ada data mahasiswa'
                  : 'Tidak ada hasil untuk "$_searchQuery"',
              style: AppTextStyles.body,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Text(
            '${_filtered.length} mahasiswa ditemukan',
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textLight,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _filtered.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (_, i) => _buildMahasiswaCard(_filtered[i]),
        ),
      ],
    );
  }

  Widget _buildMahasiswaCard(Mahasiswa m) {
    return Container(
      decoration: AppDecorations.card(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Baris atas: avatar + info + status badge
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar inisial
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Text(
                  m.nama.isNotEmpty ? m.nama[0].toUpperCase() : '?',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Nama, NIM, Jurusan
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      m.nama,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      m.nim,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      m.jurusan,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textMedium,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Badge status
              _StatusBadge(isActive: m.isActive),
            ],
          ),

          const SizedBox(height: 14),
          const Divider(height: 1, color: AppColors.divider),
          const SizedBox(height: 12),

          // Baris bawah: label Aksi + tombol-tombol rata kanan
          Row(
            children: [
              const Text(
                'Aksi:',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textLight,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              _ActionBtn(
                icon: Icons.edit_outlined,
                tooltip: 'Edit',
                color: AppColors.primaryMed,
                onTap: () => _showEditDialog(m),
              ),
              const SizedBox(width: 8),
              _ActionBtn(
                icon: Icons.lock_reset_rounded,
                tooltip: 'Reset Password',
                color: AppColors.warning,
                onTap: () => _resetPassword(m),
              ),
              const SizedBox(width: 8),
              _ActionBtn(
                icon: m.isActive
                    ? Icons.block_rounded
                    : Icons.check_circle_outline_rounded,
                tooltip: m.isActive ? 'Nonaktifkan' : 'Aktifkan',
                color: m.isActive ? AppColors.warning : AppColors.success,
                onTap: () => _toggleAktif(m),
              ),
              const SizedBox(width: 8),
              _ActionBtn(
                icon: Icons.delete_outline_rounded,
                tooltip: 'Hapus',
                color: AppColors.danger,
                onTap: () => _deleteMahasiswa(m),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ================================================================
  // MAHASISWA VIEW
  // ================================================================
  Widget _buildMahasiswaView() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildGreetingCard(),
        const SizedBox(height: 16),
        _buildBiodataCard(),
        const SizedBox(height: 16),
        _buildInfoBannerMhs(),
        const SizedBox(height: 16),
        _buildGantiPasswordBtn(),
      ],
    );
  }

  Widget _buildGreetingCard() {
    return Container(
      decoration: AppDecorations.primaryCard,
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.person_rounded,
              color: AppColors.white,
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
                    color: AppColors.white.withOpacity(0.8),
                    fontSize: 13,
                  ),
                ),
                Text(
                  widget.nama,
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'NIM: ${widget.nim.isNotEmpty ? widget.nim : '-'}',
                    style: const TextStyle(
                      color: AppColors.white,
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
      decoration: AppDecorations.card(),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(
                Icons.assignment_ind_rounded,
                color: AppColors.primary,
                size: 20,
              ),
              SizedBox(width: 8),
              Text('Biodata Akademik', style: AppTextStyles.heading3),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: AppColors.divider),
          const SizedBox(height: 12),
          if (m == null)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            )
          else ...[
            _BiodataRow(label: 'NIM', value: m.nim, icon: Icons.badge_outlined),
            _BiodataRow(
              label: 'Nama Lengkap',
              value: m.nama,
              icon: Icons.person_outline_rounded,
            ),
            _BiodataRow(
              label: 'Program Studi',
              value: m.jurusan,
              icon: Icons.book_outlined,
            ),
            _BiodataRow(
              label: 'Alamat',
              value: m.alamat.isNotEmpty ? m.alamat : '-',
              icon: Icons.home_outlined,
            ),
            _BiodataRow(
              label: 'Status Akun',
              value: m.isActive ? 'Aktif' : 'Nonaktif',
              icon: Icons.verified_user_outlined,
              valueColor: m.isActive ? AppColors.success : AppColors.danger,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoBannerMhs() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.infoLight,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline_rounded, color: AppColors.info, size: 18),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Untuk mengubah data akademik, silakan hubungi bagian administrasi atau administrator.',
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

  Widget _buildGantiPasswordBtn() {
    return OutlinedButton.icon(
      onPressed: _goToChangePassword,
      icon: const Icon(Icons.lock_open_rounded, size: 20),
      label: const Text('Ganti Password'),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        side: const BorderSide(color: AppColors.primary, width: 1.5),
        minimumSize: const Size(double.infinity, 50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
      ),
    );
  }
}

// ================================================================
// WIDGET HELPERS
// ================================================================

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: AppColors.textLight),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final bool isActive;
  const _StatusBadge({required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isActive ? AppColors.successLight : AppColors.dangerLight,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isActive
              ? AppColors.success.withOpacity(0.4)
              : AppColors.danger.withOpacity(0.4),
        ),
      ),
      child: Text(
        isActive ? 'Aktif' : 'Nonaktif',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: isActive ? AppColors.success : AppColors.danger,
        ),
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final Color color;
  final VoidCallback onTap;

  const _ActionBtn({
    required this.icon,
    required this.tooltip,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withOpacity(0.3), width: 1),
          ),
          child: Icon(icon, size: 18, color: color),
        ),
      ),
    );
  }
}

class _BiodataRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? valueColor;

  const _BiodataRow({
    required this.label,
    required this.value,
    required this.icon,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.primaryMed),
          const SizedBox(width: 12),
          SizedBox(width: 110, child: Text(label, style: AppTextStyles.label)),
          const Text(' : ', style: TextStyle(color: AppColors.textLight)),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: valueColor ?? AppColors.textDark,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoBox extends StatelessWidget {
  final String text;
  final bool isWarning;
  const _InfoBox(this.text, {this.isWarning = false});

  @override
  Widget build(BuildContext context) {
    final color = isWarning ? AppColors.warning : AppColors.info;
    final bg = isWarning ? AppColors.warningLight : AppColors.infoLight;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 12, color: color, height: 1.5),
      ),
    );
  }
}
