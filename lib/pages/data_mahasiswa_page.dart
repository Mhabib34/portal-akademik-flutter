import 'package:flutter/material.dart';
import '../widgets/admin_nav_helper.dart';

import '../theme/app_theme.dart';
import '../config/api_config.dart';
import '../services/api_client.dart';
import '../models/prodi_model.dart';

// ============================================================
// data_mahasiswa_page.dart — Manajemen Data Mahasiswa (Admin)
//   Sesuai schema Mahasiswa di openapi spec: id, nim, nama,
//   jurusan, alamat, user_id, is_active, must_change_password.
//   Jurusan dibuat sebagai text field biasa (tidak ada enum baku
//   di spec). Data diambil sekaligus tanpa pagination (spec tidak
//   menyediakan parameter pagination di get_mahasiswa.php).
// ============================================================

class DataMahasiswaPage extends StatefulWidget {
  const DataMahasiswaPage({super.key});

  @override
  State<DataMahasiswaPage> createState() => _DataMahasiswaPageState();
}

class _DataMahasiswaPageState extends State<DataMahasiswaPage> {
  bool _isLoading = true;
  String _searchQuery = '';

  List<Map<String, dynamic>> _allMahasiswa = [];
  List<Prodi> _prodiList = [];

  List<Map<String, dynamic>> get _filteredMahasiswa {
    if (_searchQuery.trim().isEmpty) return _allMahasiswa;
    final q = _searchQuery.trim().toLowerCase();
    return _allMahasiswa.where((m) {
      final nama = (m['nama'] ?? '').toString().toLowerCase();
      final nim = (m['nim'] ?? '').toString().toLowerCase();
      return nama.contains(q) || nim.contains(q);
    }).toList();
  }

  int get _totalCount => _allMahasiswa.length;
  int get _aktifCount => _allMahasiswa
      .where((m) => int.tryParse(m['is_active']?.toString() ?? '0') == 1)
      .length;
  int get _nonaktifCount => _totalCount - _aktifCount;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final res = await ApiClient.get(ApiConfig.getMahasiswa);
      final prodiRes = await ApiClient.get(ApiConfig.getProdi);
      
      if (res['status'] == 'ok') {
        final List list = res['data'] as List? ?? [];
        _allMahasiswa = list
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
      }
      
      if (prodiRes['status'] == 'ok') {
        final List list = prodiRes['data'] as List? ?? [];
        _prodiList = list.map((e) => Prodi.fromJson(e as Map<String, dynamic>)).toList();
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal memuat data mahasiswa'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }

    if (mounted) setState(() => _isLoading = false);
  }

  void _showSnack(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? const Color(0xFFE05252) : AppColorsSoft.navy,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  // ---------------- Toggle status Aktif/Nonaktif ----------------
  Future<void> _toggleStatus(Map<String, dynamic> mhs) async {
    final userId = mhs['user_id']?.toString() ?? '';
    if (userId.isEmpty) return;

    try {
      final res = await ApiClient.postForm(
        ApiConfig.toggleAktif,
        body: {'user_id': userId},
      );
      if (res['status'] == 'ok') {
        _showSnack('Status ${mhs['nama']} berhasil diubah');
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

  // ---------------- Reset password ke NIM ----------------
  Future<void> _confirmResetPassword(Map<String, dynamic> mhs) async {
    final userId = mhs['user_id']?.toString() ?? '';
    if (userId.isEmpty) return;

    final konfirmasi = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Reset Password'),
        content: Text(
          'Password ${mhs['nama']} akan direset ke NIM (${mhs['nim']}). Lanjutkan?',
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
        _showSnack('Password ${mhs['nama']} berhasil direset ke NIM');
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

  // ---------------- Tambah / Edit mahasiswa ----------------
  Future<void> _openForm({Map<String, dynamic>? existing}) async {
    final isEdit = existing != null;
    final nimCtrl = TextEditingController(
      text: existing?['nim']?.toString() ?? '',
    );
    final namaCtrl = TextEditingController(
      text: existing?['nama']?.toString() ?? '',
    );
    String? selectedProdiId = existing?['prodi_id']?.toString();
    final alamatCtrl = TextEditingController(
      text: existing?['alamat']?.toString() ?? '',
    );
    bool isSaving = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => StatefulBuilder(
        builder: (builderCtx, setSheetState) {
          Future<void> submit() async {
            if (nimCtrl.text.trim().isEmpty ||
                namaCtrl.text.trim().isEmpty ||
                selectedProdiId == null) {
              _showSnack('NIM, Nama, dan Program Studi wajib diisi', isError: true);
              return;
            }
            setSheetState(() => isSaving = true);
            try {
              final body = {
                'nim': nimCtrl.text.trim(),
                'nama': namaCtrl.text.trim(),
                'prodi_id': selectedProdiId!,
                'alamat': alamatCtrl.text.trim(),
              };
              final res = await ApiClient.postForm(
                isEdit ? ApiConfig.updateMahasiswa : ApiConfig.simpanMahasiswa,
                body: isEdit
                    ? {'id': existing['id'].toString(), ...body}
                    : body,
              );
              if (res['status'] == 'ok') {
                if (sheetCtx.mounted) {
                  FocusManager.instance.primaryFocus?.unfocus();
                  Navigator.pop(sheetCtx);
                }
                _showSnack(
                  isEdit
                      ? 'Data mahasiswa berhasil diperbarui'
                      : 'Mahasiswa baru ditambahkan. Akun login dibuat otomatis (username & password: NIM)',
                );
                _loadData();
              } else {
                setSheetState(() => isSaving = false);
                _showSnack(
                  res['message']?.toString() ?? 'Gagal menyimpan data',
                  isError: true,
                );
              }
            } catch (_) {
              setSheetState(() => isSaving = false);
              _showSnack('Gagal terhubung ke server', isError: true);
            }
          }

          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(builderCtx).viewInsets.bottom,
            ),
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
              decoration: const BoxDecoration(
                color: AppColorsSoft.cardWhite,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
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
                      'Data Mahasiswa',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppColorsSoft.navy,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Lengkapi informasi akademik di bawah ini dengan benar '
                      'untuk pemutakhiran basis data pusat.',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColorsSoft.textGray,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _formLabel('NIM (Nomor Induk Mahasiswa)'),
                    const SizedBox(height: 8),
                    TextField(
                      controller: nimCtrl,
                      keyboardType: TextInputType.number,
                      decoration: AppColorsSoft.fieldDecoration(
                        hint: 'Contoh: 210101001',
                        prefixIcon: Icons.badge_outlined,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _formLabel('Nama Lengkap'),
                    const SizedBox(height: 8),
                    TextField(
                      controller: namaCtrl,
                      decoration: AppColorsSoft.fieldDecoration(
                        hint: 'Masukkan nama sesuai KTP',
                        prefixIcon: Icons.person_outline_rounded,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _formLabel('Program Studi'),
                    const SizedBox(height: 8),
                    InputDecorator(
                      decoration: AppColorsSoft.fieldDecoration(
                        hint: 'Pilih Prodi',
                        prefixIcon: Icons.school_outlined,
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          isExpanded: true,
                          value: _prodiList.any((p) => p.id == selectedProdiId) ? selectedProdiId : null,
                          isDense: true,
                          hint: const Text('Pilih Prodi'),
                          items: _prodiList.map((p) => DropdownMenuItem(
                            value: p.id,
                            child: Text(
                              '${p.namaProdi} (${p.namaFakultas})',
                              style: const TextStyle(fontSize: 14),
                              overflow: TextOverflow.ellipsis,
                            ),
                          )).toList(),
                          onChanged: (v) => setSheetState(() => selectedProdiId = v),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _formLabel('Alamat Tinggal'),
                    const SizedBox(height: 8),
                    TextField(
                      controller: alamatCtrl,
                      maxLines: 3,
                      decoration: AppColorsSoft.fieldDecoration(
                        hint: 'Jl. Kampus Merdeka No. 123...',
                        prefixIcon: Icons.location_on_outlined,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: isSaving
                                ? null
                                : () => Navigator.pop(sheetCtx),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: const Text(
                              'Batal',
                              style: TextStyle(
                                color: AppColorsSoft.textGray,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            onPressed: isSaving ? null : submit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColorsSoft.navy,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(26),
                              ),
                            ),
                            child: isSaving
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                : const Text(
                                    'Simpan',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _formLabel(String text) => Text(
    text,
    style: const TextStyle(
      fontSize: 12.5,
      fontWeight: FontWeight.w700,
      color: AppColorsSoft.navy,
    ),
  );

  // ---------------- Hapus mahasiswa ----------------
  Future<void> _confirmDelete(Map<String, dynamic> mhs) async {
    final konfirmasi = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Hapus Mahasiswa'),
        content: Text(
          'Yakin ingin menghapus ${mhs['nama']}? Akun login mahasiswa ini juga akan dihapus.',
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
        ApiConfig.deleteMahasiswa,
        body: {'id': mhs['id'].toString()},
      );
      if (res['status'] == 'ok') {
        _showSnack('${mhs['nama']} berhasil dihapus');
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: AdminNavHelper.buildNav(context: context, currentIndex: -1),
      body: Container(
        decoration: BoxDecoration(gradient: AppColorsSoft.backgroundGradient),
        child: SafeArea(
          child: RefreshIndicator(
            color: AppColorsSoft.navy,
            onRefresh: _loadData,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              children: [
                _buildTopBar(),
                const SizedBox(height: 20),
                _buildSearchBar(),
                const SizedBox(height: 16),
                _buildStatsChips(),
                const SizedBox(height: 20),
                if (_isLoading)
                  const Padding(
                    padding: EdgeInsets.only(top: 40),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: AppColorsSoft.navy,
                      ),
                    ),
                  )
                else if (_filteredMahasiswa.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 40),
                    child: Center(
                      child: Text(
                        _searchQuery.isEmpty
                            ? 'Belum ada data mahasiswa'
                            : 'Mahasiswa tidak ditemukan',
                        style: const TextStyle(color: AppColorsSoft.textGray),
                      ),
                    ),
                  )
                else
                  ..._filteredMahasiswa.map(_buildMahasiswaCard),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Row(
      children: [
        IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_rounded, color: AppColorsSoft.navy),
        ),
        const Text(
          'Data Mahasiswa',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: AppColorsSoft.navy,
          ),
        ),
        const Spacer(),
        GestureDetector(
          onTap: () => _openForm(),
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
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: AppColorsSoft.card(),
      child: TextField(
        onChanged: (v) => setState(() => _searchQuery = v),
        decoration: InputDecoration(
          hintText: 'Cari nama atau NIM...',
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

  Widget _buildStatsChips() {
    Widget chip(String label, String value, Color bg, Color fg) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          '$label: $value',
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: fg,
          ),
        ),
      );
    }

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        chip(
          'Total',
          _isLoading ? '...' : '$_totalCount',
          AppColorsSoft.navy,
          Colors.white,
        ),
        chip(
          'Aktif',
          _isLoading ? '...' : '$_aktifCount',
          const Color(0xFFFFE8CC),
          const Color(0xFFE08A00),
        ),
        chip(
          'Nonaktif',
          _isLoading ? '...' : '$_nonaktifCount',
          const Color(0xFFFFE0E0),
          const Color(0xFFE05252),
        ),
      ],
    );
  }

  Widget _buildMahasiswaCard(Map<String, dynamic> mhs) {
    final nama = mhs['nama']?.toString() ?? '-';
    final nim = mhs['nim']?.toString() ?? '-';
    final prodi = mhs['nama_prodi']?.toString() ?? '-';
    final fakultas = mhs['nama_fakultas']?.toString() ?? '-';
    final isActive = int.tryParse(mhs['is_active']?.toString() ?? '0') == 1;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: AppColorsSoft.card(),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: AppColorsSoft.gradientPeach,
            child: Text(
              nama.isNotEmpty ? nama[0].toUpperCase() : 'M',
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
                  '$nim • $prodi - $fakultas',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColorsSoft.textGray,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isActive
                        ? const Color(0xFF12A150).withOpacity(0.12)
                        : const Color(0xFFE05252).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isActive ? 'AKTIF' : 'NONAKTIF',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: isActive
                          ? const Color(0xFF12A150)
                          : const Color(0xFFE05252),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Column(
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _iconCircleButton(
                    icon: Icons.edit_outlined,
                    onTap: () => _openForm(existing: mhs),
                  ),
                  const SizedBox(width: 8),
                  _iconCircleButton(
                    icon: Icons.restore_rounded,
                    onTap: () => _confirmResetPassword(mhs),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Transform.scale(
                    scale: 0.75,
                    child: Switch(
                      value: isActive,
                      activeColor: AppColorsSoft.navy,
                      onChanged: (_) => _toggleStatus(mhs),
                    ),
                  ),
                  _iconCircleButton(
                    icon: Icons.delete_outline_rounded,
                    iconColor: const Color(0xFFE05252),
                    onTap: () => _confirmDelete(mhs),
                  ),
                ],
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
        decoration: BoxDecoration(
          color: AppColorsSoft.fieldFill,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 16, color: iconColor),
      ),
    );
  }
}
