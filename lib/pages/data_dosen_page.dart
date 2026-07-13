import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../config/api_config.dart';
import '../services/api_client.dart';

// ============================================================
// data_dosen_page.dart — Manajemen Data Dosen (Admin)
//   Sesuai schema Dosen di openapi spec: id, nidn, nama, no_hp,
//   user_id, is_active, must_change_password. Tidak ada field
//   foto atau status "cuti" terpisah — badge AKTIF/CUTI di UI
//   dipetakan langsung dari is_active (1/0). Jumlah "Mata Kuliah"
//   per dosen dihitung dari get_kelas.php (grouping mata_kuliah_id
//   unik per dosen_id di client), karena tidak ada di schema Dosen.
// ============================================================

class DataDosenPage extends StatefulWidget {
  const DataDosenPage({super.key});

  @override
  State<DataDosenPage> createState() => _DataDosenPageState();
}

class _DataDosenPageState extends State<DataDosenPage> {
  bool _isLoading = true;
  String _searchQuery = '';

  List<Map<String, dynamic>> _allDosen = [];
  Map<String, int> _mataKuliahCount = {}; // dosen_id -> jumlah mk unik

  List<Map<String, dynamic>> get _filteredDosen {
    if (_searchQuery.trim().isEmpty) return _allDosen;
    final q = _searchQuery.trim().toLowerCase();
    return _allDosen.where((d) {
      final nama = (d['nama'] ?? '').toString().toLowerCase();
      final nidn = (d['nidn'] ?? '').toString().toLowerCase();
      return nama.contains(q) || nidn.contains(q);
    }).toList();
  }

  int get _totalCount => _allDosen.length;
  int get _aktifCount => _allDosen
      .where((d) => int.tryParse(d['is_active']?.toString() ?? '0') == 1)
      .length;
  int get _cutiCount => _totalCount - _aktifCount;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final dosenRes = await ApiClient.get(ApiConfig.getDosen);
      if (dosenRes['status'] == 'ok') {
        final List list = dosenRes['data'] as List? ?? [];
        _allDosen = list
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
      }

      // Ambil semua kelas sekali, group jumlah mata_kuliah_id unik per dosen_id.
      final kelasRes = await ApiClient.get(ApiConfig.getKelas);
      if (kelasRes['status'] == 'ok') {
        final List kelasList = kelasRes['data'] as List? ?? [];
        final Map<String, Set<String>> grouped = {};
        for (final k in kelasList) {
          final map = k as Map<String, dynamic>;
          final dosenId = map['dosen_id']?.toString();
          final mkId = map['mata_kuliah_id']?.toString();
          if (dosenId == null || mkId == null) continue;
          grouped.putIfAbsent(dosenId, () => {}).add(mkId);
        }
        _mataKuliahCount = grouped.map((k, v) => MapEntry(k, v.length));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal memuat data dosen'),
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

  // ---------------- Toggle status Aktif/Cuti ----------------
  Future<void> _toggleStatus(Map<String, dynamic> dosen) async {
    final userId = dosen['user_id']?.toString() ?? '';
    if (userId.isEmpty) return;

    try {
      final res = await ApiClient.postForm(
        ApiConfig.toggleAktif,
        body: {'user_id': userId},
      );
      if (res['status'] == 'ok') {
        _showSnack('Status ${dosen['nama']} berhasil diubah');
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

  // ---------------- Tambah / Edit dosen ----------------
  Future<void> _openForm({Map<String, dynamic>? existing}) async {
    final isEdit = existing != null;
    final nidnCtrl = TextEditingController(
      text: existing?['nidn']?.toString() ?? '',
    );
    final namaCtrl = TextEditingController(
      text: existing?['nama']?.toString() ?? '',
    );
    final hpCtrl = TextEditingController(
      text: existing?['no_hp']?.toString() ?? '',
    );
    bool isSaving = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => StatefulBuilder(
        builder: (builderCtx, setSheetState) {
          Future<void> submit() async {
            if (nidnCtrl.text.trim().isEmpty || namaCtrl.text.trim().isEmpty) {
              _showSnack('NIDN dan Nama wajib diisi', isError: true);
              return;
            }
            setSheetState(() => isSaving = true);
            try {
              final body = {
                'nidn': nidnCtrl.text.trim(),
                'nama': namaCtrl.text.trim(),
                'no_hp': hpCtrl.text.trim(),
              };
              final res = await ApiClient.postForm(
                isEdit ? ApiConfig.updateDosen : ApiConfig.simpanDosen,
                body: isEdit
                    ? {'id': existing['id'].toString(), ...body}
                    : body,
              );
              if (res['status'] == 'ok') {
                if (mounted) Navigator.pop(sheetCtx);
                _showSnack(
                  isEdit
                      ? 'Data dosen berhasil diperbarui'
                      : 'Dosen baru berhasil ditambahkan',
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
                    Text(
                      isEdit ? 'Edit Data Dosen' : 'Tambah Dosen Baru',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppColorsSoft.navy,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _formLabel('NIDN'),
                    const SizedBox(height: 8),
                    TextField(
                      controller: nidnCtrl,
                      keyboardType: TextInputType.number,
                      decoration: AppColorsSoft.fieldDecoration(
                        hint: 'NIDN',
                        prefixIcon: Icons.badge_outlined,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _formLabel('Nama Lengkap'),
                    const SizedBox(height: 8),
                    TextField(
                      controller: namaCtrl,
                      decoration: AppColorsSoft.fieldDecoration(
                        hint: 'Nama Lengkap (mis. Dr. Ahmad Subarjo, M.T.)',
                        prefixIcon: Icons.person_outline_rounded,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _formLabel('No. HP'),
                    const SizedBox(height: 8),
                    TextField(
                      controller: hpCtrl,
                      keyboardType: TextInputType.phone,
                      decoration: AppColorsSoft.fieldDecoration(
                        hint: 'No. HP',
                        prefixIcon: Icons.phone_outlined,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: isSaving ? null : () => Navigator.pop(sheetCtx),
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
                                      valueColor: AlwaysStoppedAnimation(Colors.white),
                                    ),
                                  )
                                : Text(
                                    isEdit ? 'Simpan' : 'Tambah',
                                    style: const TextStyle(
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

  // ---------------- Hapus dosen ----------------
  Future<void> _confirmDelete(Map<String, dynamic> dosen) async {
    final konfirmasi = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Hapus Dosen'),
        content: Text(
          'Yakin ingin menghapus ${dosen['nama']}? Akun login dosen ini juga akan dihapus.',
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
        ApiConfig.deleteDosen,
        body: {'id': dosen['id'].toString()},
      );
      if (res['status'] == 'ok') {
        _showSnack('${dosen['nama']} berhasil dihapus');
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
                _buildStatsRow(),
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
                else if (_filteredDosen.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 40),
                    child: Center(
                      child: Text(
                        _searchQuery.isEmpty
                            ? 'Belum ada data dosen'
                            : 'Dosen tidak ditemukan',
                        style: const TextStyle(color: AppColorsSoft.textGray),
                      ),
                    ),
                  )
                else
                  ..._filteredDosen.map(_buildDosenCard),
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
          'Data Dosen',
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
        const SizedBox(width: 8),
        IconButton(
          onPressed: () {},
          icon: const Icon(
            Icons.notifications_none_rounded,
            color: AppColorsSoft.navy,
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
          hintText: 'Cari nama atau NIDN...',
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

  Widget _buildStatsRow() {
    Widget pill(String label, String value, {bool highlighted = false}) {
      return Expanded(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: AppColorsSoft.cardWhite,
            borderRadius: BorderRadius.circular(20),
            border: highlighted
                ? Border.all(color: const Color(0xFF12A150), width: 1.4)
                : null,
            boxShadow: [
              BoxShadow(
                color: AppColorsSoft.navy.withOpacity(0.06),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColorsSoft.textGray,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColorsSoft.navy,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Row(
      children: [
        pill('Total', _isLoading ? '...' : '$_totalCount'),
        pill('Aktif', _isLoading ? '...' : '$_aktifCount', highlighted: true),
        pill('Cuti', _isLoading ? '...' : '$_cutiCount'),
      ],
    );
  }

  Widget _buildDosenCard(Map<String, dynamic> dosen) {
    final nama = dosen['nama']?.toString() ?? '-';
    final nidn = dosen['nidn']?.toString() ?? '-';
    final isActive = int.tryParse(dosen['is_active']?.toString() ?? '0') == 1;
    final mkCount = _mataKuliahCount[dosen['id']?.toString()] ?? 0;

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
                backgroundColor: AppColorsSoft.gradientLavender,
                child: Text(
                  nama.isNotEmpty ? nama[0].toUpperCase() : 'D',
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
                      'NIDN: $nidn',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColorsSoft.textGray,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => _toggleStatus(dosen),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: isActive
                        ? const Color(0xFF12A150).withOpacity(0.12)
                        : const Color(0xFFCBA400).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isActive ? 'AKTIF' : 'CUTI',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: isActive
                          ? const Color(0xFF12A150)
                          : const Color(0xFFCBA400),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              const Icon(
                Icons.school_outlined,
                size: 16,
                color: AppColorsSoft.textGray,
              ),
              const SizedBox(width: 6),
              Text(
                '$mkCount Mata Kuliah',
                style: const TextStyle(
                  fontSize: 12.5,
                  color: AppColorsSoft.textGray,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: () => _openForm(existing: dosen),
                icon: const Icon(
                  Icons.edit_outlined,
                  size: 19,
                  color: AppColorsSoft.textGray,
                ),
                visualDensity: VisualDensity.compact,
              ),
              IconButton(
                onPressed: () => _confirmDelete(dosen),
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  size: 19,
                  color: Color(0xFFE05252),
                ),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
