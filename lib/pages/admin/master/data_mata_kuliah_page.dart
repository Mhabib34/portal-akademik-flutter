import 'package:flutter/material.dart';
import '../../../widgets/admin_nav_helper.dart';

import '../../../theme/app_theme.dart';
import '../../../config/api_config.dart';
import '../../../services/api_client.dart';
import '../../../models/prodi_model.dart';
import '../../../widgets/custom_top_bar.dart';
import '../../../utils/app_toast.dart';

// ============================================================
// data_mata_kuliah_page.dart — CRUD Mata Kuliah (admin)
//
//   CATATAN PENTING (sesuai diskusi):
//   - Filter chip pakai PRODI (bukan "Jurusan" seperti di gambar),
//     karena field jurusan sudah diganti prodi_id di update spec
//     sebelumnya.
//   - "Dosen Pengampu" TIDAK ada di schema MataKuliah — dosen
//     terikat ke Kelas (rombel), bukan ke Mata Kuliah. Nama dosen
//     di kartu diturunkan dari get_kelas.php: dicari Kelas dengan
//     mata_kuliah_id yang cocok, diprioritaskan Kelas di tahun
//     ajaran aktif. Kalau MK belum pernah dibuka jadi Kelas sama
//     sekali, tampil "Belum ada kelas dibuka" (bukan nama dosen).
//     Kalau MK dibuka lebih dari 1 kelas di semester yang sama
//     (misal Kelas A & B beda dosen), hanya kelas PERTAMA yang
//     ditemukan yang ditampilkan — bukan representasi lengkap.
//   - Badge "Semester X" ditambahkan di kartu (field semester_ke
//     wajib diisi di spec, walau tidak ada di gambar referensi).
// ============================================================

class DataMataKuliahPage extends StatefulWidget {
  final String nama;
  const DataMataKuliahPage({super.key, this.nama = ''});

  @override
  State<DataMataKuliahPage> createState() => _DataMataKuliahPageState();
}

class _DataMataKuliahPageState extends State<DataMataKuliahPage> {
  List<Prodi> _prodiList = [];
  List<Map<String, dynamic>> _all = [];
  List<Map<String, dynamic>> _filtered = [];

  // mata_kuliah_id -> nama_dosen (dari kelas di tahun ajaran aktif, atau kelas pertama ditemukan)
  Map<String, String> _dosenPengampu = {};

  bool _isLoading = true;
  String _searchQuery = '';
  String _filterProdiId = '';
  final _searchCtrl = TextEditingController();

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

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      // 1. Daftar prodi (untuk filter chip & dropdown form)
      final prodiResp = await ApiClient.get(ApiConfig.getProdi);
      if (prodiResp['status'] == 'ok') {
        _prodiList = (prodiResp['data'] as List)
            .map(
              (e) =>
                  Prodi.fromJson(e as Map<String, dynamic>, namaFakultas: ''),
            )
            .toList();
      }

      // 2. Daftar mata kuliah
      final mkResp = await ApiClient.get(ApiConfig.getMataKuliah);
      if (mkResp['status'] == 'ok') {
        final List list = mkResp['data'] as List? ?? [];
        _all = list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        _applyFilter();
      }

      // 3. Tahun ajaran aktif (untuk prioritaskan kelas semester berjalan)
      String? tahunAjaranAktifId;
      final taResp = await ApiClient.get(ApiConfig.getTahunAjaran);
      if (taResp['status'] == 'ok') {
        final List taList = taResp['data'] as List? ?? [];
        for (final t in taList) {
          final map = t as Map<String, dynamic>;
          if (int.tryParse(map['is_aktif']?.toString() ?? '0') == 1) {
            tahunAjaranAktifId = map['id']?.toString();
            break;
          }
        }
      }

      // 4. Semua kelas -> cari dosen pengampu per mata_kuliah_id
      final kelasResp = await ApiClient.get(ApiConfig.getKelas);
      if (kelasResp['status'] == 'ok') {
        final List kelasList = kelasResp['data'] as List? ?? [];
        final Map<String, String> dosenAktif = {};
        final Map<String, String> dosenFallback = {};
        for (final k in kelasList) {
          final map = k as Map<String, dynamic>;
          final mkId = map['mata_kuliah_id']?.toString();
          final namaDosen = map['nama_dosen']?.toString();
          if (mkId == null || namaDosen == null || namaDosen.isEmpty) continue;

          dosenFallback.putIfAbsent(mkId, () => namaDosen);
          if (tahunAjaranAktifId != null &&
              map['tahun_ajaran_id']?.toString() == tahunAjaranAktifId) {
            dosenAktif.putIfAbsent(mkId, () => namaDosen);
          }
        }
        // Prioritaskan dosen dari tahun ajaran aktif, fallback ke kelas manapun.
        _dosenPengampu = {...dosenFallback, ...dosenAktif};
      }
    } catch (_) {
      _showSnackBar('Gagal memuat data mata kuliah', isError: true);
    }
    if (mounted) setState(() => _isLoading = false);
  }

  void _applyFilter() {
    final q = _searchQuery.toLowerCase();
    _filtered = _all.where((m) {
      final namaMk = (m['nama_mk'] ?? '').toString().toLowerCase();
      final kodeMk = (m['kode_mk'] ?? '').toString().toLowerCase();
      final matchSearch = q.isEmpty || namaMk.contains(q) || kodeMk.contains(q);
      final matchProdi =
          _filterProdiId.isEmpty || m['prodi_id']?.toString() == _filterProdiId;
      return matchSearch && matchProdi;
    }).toList();
  }

  void _showSnackBar(String msg, {bool isError = false}) {
    AppToast.show(context, msg, isError: isError);
  }

  Future<void> _showFormDialog({Map<String, dynamic>? existing}) async {
    if (_prodiList.isEmpty) {
      _showSnackBar(
        'Tambahkan data Prodi dulu sebelum membuat Mata Kuliah',
        isError: true,
      );
      return;
    }

    final kodeCtrl = TextEditingController(
      text: existing?['kode_mk']?.toString() ?? '',
    );
    final namaCtrl = TextEditingController(
      text: existing?['nama_mk']?.toString() ?? '',
    );
    final sksCtrl = TextEditingController(
      text: existing?['sks']?.toString() ?? '',
    );
    final semesterCtrl = TextEditingController(
      text: existing?['semester_ke']?.toString() ?? '',
    );
    final deskripsiCtrl = TextEditingController(
      text: existing?['deskripsi']?.toString() ?? '',
    );
    String? selectedProdiId =
        existing?['prodi_id']?.toString() ?? _prodiList.first.id;
    bool saving = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => StatefulBuilder(
        builder: (builderCtx, setSheetState) {
          Future<void> submit() async {
            if (kodeCtrl.text.trim().isEmpty ||
                namaCtrl.text.trim().isEmpty ||
                sksCtrl.text.trim().isEmpty ||
                semesterCtrl.text.trim().isEmpty ||
                selectedProdiId == null) {
              _showSnackBar(
                'Kode, Nama, SKS, Semester, dan Prodi wajib diisi',
                isError: true,
              );
              return;
            }
            setSheetState(() => saving = true);
            try {
              final body = {
                'kode_mk': kodeCtrl.text.trim(),
                'nama_mk': namaCtrl.text.trim(),
                'sks': sksCtrl.text.trim(),
                'prodi_id': selectedProdiId!,
                'semester_ke': semesterCtrl.text.trim(),
                'deskripsi': deskripsiCtrl.text.trim(),
                if (existing != null) 'id': existing['id'].toString(),
              };
              final url = existing == null
                  ? ApiConfig.simpanMataKuliah
                  : ApiConfig.updateMataKuliah;
              final data = await ApiClient.postForm(url, body: body);
              if (data['status'] == 'ok') {
                if (mounted) Navigator.pop(sheetCtx);
                _showSnackBar(
                  existing == null
                      ? 'Mata kuliah berhasil ditambahkan'
                      : 'Mata kuliah berhasil diperbarui',
                );
                _loadData();
              } else {
                setSheetState(() => saving = false);
                _showSnackBar(
                  data['message']?.toString() ?? 'Gagal menyimpan data',
                  isError: true,
                );
              }
            } catch (_) {
              setSheetState(() => saving = false);
              _showSnackBar('Koneksi gagal', isError: true);
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
                      existing == null ? 'Tambah Mata Kuliah' : 'Edit Mata Kuliah',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppColorsSoft.navy,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _formLabel('Kode Mata Kuliah'),
                    const SizedBox(height: 8),
                    TextField(
                      controller: kodeCtrl,
                      decoration: AppColorsSoft.fieldDecoration(
                        hint: 'Kode MK (mis. IF101)',
                        prefixIcon: Icons.tag_rounded,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _formLabel('Nama Mata Kuliah'),
                    const SizedBox(height: 8),
                    TextField(
                      controller: namaCtrl,
                      decoration: AppColorsSoft.fieldDecoration(
                        hint: 'Nama Mata Kuliah',
                        prefixIcon: Icons.menu_book_rounded,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _formLabel('SKS'),
                              const SizedBox(height: 8),
                              TextField(
                                controller: sksCtrl,
                                keyboardType: TextInputType.number,
                                decoration: AppColorsSoft.fieldDecoration(
                                  hint: 'SKS',
                                  prefixIcon: Icons.numbers_rounded,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _formLabel('Semester Ke-'),
                              const SizedBox(height: 8),
                              TextField(
                                controller: semesterCtrl,
                                keyboardType: TextInputType.number,
                                decoration: AppColorsSoft.fieldDecoration(
                                  hint: 'Semester',
                                  prefixIcon: Icons.calendar_view_month_rounded,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _formLabel('Program Studi'),
                    const SizedBox(height: 8),
                    InputDecorator(
                      decoration: AppColorsSoft.fieldDecoration(
                        hint: 'Pilih Prodi',
                        prefixIcon: Icons.school_rounded,
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          isExpanded: true,
                          value: selectedProdiId,
                          isDense: true,
                          items: _prodiList
                              .map(
                                (p) => DropdownMenuItem(
                                  value: p.id,
                                  child: Text(
                                    p.namaProdi,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (v) =>
                              setSheetState(() => selectedProdiId = v),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _formLabel('Deskripsi'),
                    const SizedBox(height: 8),
                    TextField(
                      controller: deskripsiCtrl,
                      maxLines: 3,
                      decoration: AppColorsSoft.fieldDecoration(
                        hint: 'Deskripsi (opsional)',
                        prefixIcon: Icons.notes_rounded,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed:
                                saving ? null : () => Navigator.pop(sheetCtx),
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
                            onPressed: saving ? null : submit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColorsSoft.navy,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(26),
                              ),
                            ),
                            child: saving
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor:
                                          AlwaysStoppedAnimation(Colors.white),
                                    ),
                                  )
                                : const Text(
                                    'Simpan',
                                    style: TextStyle(
                                      color: Colors.white,
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

  Future<void> _deleteMataKuliah(Map<String, dynamic> mk) async {
    final konfirmasi = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Hapus Mata Kuliah'),
        content: Text('Hapus "${mk['nama_mk']}"?'),
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
      final data = await ApiClient.postForm(
        ApiConfig.deleteMataKuliah,
        body: {'id': mk['id'].toString()},
      );
      if (data['status'] == 'ok') {
        _showSnackBar('Mata kuliah berhasil dihapus');
        _loadData();
      } else {
        _showSnackBar(data['message']?.toString() ?? 'Gagal', isError: true);
      }
    } catch (_) {
      _showSnackBar('Koneksi gagal', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: AdminNavHelper.buildNav(context: context, currentIndex: -1),
      body: Container(
        decoration: BoxDecoration(gradient: AppColorsSoft.backgroundGradient),
        child: SafeArea(
          child: Column(
            children: [
              CustomTopBar(
                title: 'Data Mata Kuliah',
                nama: widget.nama,
                onBack: () => Navigator.pop(context),
                trailing: GestureDetector(
                  onTap: () => _showFormDialog(),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: AppColorsSoft.navy,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.add_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: TextField(
                  controller: _searchCtrl,
                  decoration: AppColorsSoft.fieldDecoration(
                    hint: 'Cari nama mata kuliah atau kode...',
                    prefixIcon: Icons.search_rounded,
                  ),
                  onChanged: (v) => setState(() {
                    _searchQuery = v;
                    _applyFilter();
                  }),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: [
                    _filterChip('Semua Prodi', ''),
                    ..._prodiList.map((p) => _filterChip(p.namaProdi, p.id)),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: AppColorsSoft.navy,
                        ),
                      )
                    : RefreshIndicator(
                        color: AppColorsSoft.navy,
                        onRefresh: _loadData,
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                          itemCount: _filtered.length + 1,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 14),
                          itemBuilder: (_, i) {
                            if (i == _filtered.length) {
                              return _buildAddCard();
                            }
                            if (_filtered.isEmpty && i == 0) {
                              return const Padding(
                                padding: EdgeInsets.only(top: 20, bottom: 10),
                                child: Center(
                                  child: Text(
                                    'Belum ada data mata kuliah',
                                    style: TextStyle(
                                      color: AppColorsSoft.textGray,
                                    ),
                                  ),
                                ),
                              );
                            }
                            return _buildMkCard(_filtered[i], i);
                          },
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _filterChip(String label, String prodiId) {
    final selected = _filterProdiId == prodiId;
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: GestureDetector(
        onTap: () => setState(() {
          _filterProdiId = prodiId;
          _applyFilter();
        }),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
          decoration: BoxDecoration(
            color: selected ? AppColorsSoft.navy : AppColorsSoft.cardWhite,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: AppColorsSoft.navy.withOpacity(0.06),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: selected ? Colors.white : AppColorsSoft.navy,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMkCard(Map<String, dynamic> mk, int index) {
    final kodeMk = mk['kode_mk']?.toString() ?? '-';
    final namaMk = mk['nama_mk']?.toString() ?? '-';
    final sks = mk['sks']?.toString() ?? '-';
    final semesterKe = mk['semester_ke']?.toString();
    final namaProdi = mk['nama_prodi']?.toString() ?? '-';
    final dosen = _dosenPengampu[mk['id']?.toString()];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppColorsSoft.card(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _badge(
                '$sks SKS',
                const Color(0xFFDCEBFF),
                const Color(0xFF2E6FE0),
              ),
              if (semesterKe != null) ...[
                const SizedBox(width: 8),
                _badge(
                  'Semester $semesterKe',
                  const Color(0xFFEEE3FF),
                  const Color(0xFF8B5CF6),
                ),
              ],
              const Spacer(),
              IconButton(
                onPressed: () => _showFormDialog(existing: mk),
                icon: const Icon(
                  Icons.edit_outlined,
                  size: 19,
                  color: AppColorsSoft.textGray,
                ),
                visualDensity: VisualDensity.compact,
              ),
              IconButton(
                onPressed: () => _deleteMataKuliah(mk),
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  size: 19,
                  color: Color(0xFFE05252),
                ),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '$kodeMk – $namaMk',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColorsSoft.navy,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            namaProdi,
            style: const TextStyle(
              fontSize: 13,
              color: AppColorsSoft.textGray,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: AppColorsSoft.gradientLavender,
                child: Icon(
                  dosen != null
                      ? Icons.person_rounded
                      : Icons.person_off_outlined,
                  size: 16,
                  color: AppColorsSoft.navy,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'DOSEN PENGAMPU',
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        color: AppColorsSoft.textGrayLight,
                        letterSpacing: 0.3,
                      ),
                    ),
                    Text(
                      dosen ?? 'Belum ada kelas dibuka',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: dosen != null
                            ? AppColorsSoft.navy
                            : AppColorsSoft.textGrayLight,
                        fontStyle: dosen != null
                            ? FontStyle.normal
                            : FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _badge(String text, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: fg),
      ),
    );
  }

  Widget _buildAddCard() {
    return InkWell(
      onTap: () => _showFormDialog(),
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 28),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: AppColorsSoft.textGrayLight.withOpacity(0.4),
            width: 1.4,
          ),
        ),
        child: Column(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                color: AppColorsSoft.navy,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.add_rounded, color: Colors.white),
            ),
            const SizedBox(height: 12),
            const Text(
              'Tambah Mata Kuliah',
              style: TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w800,
                color: AppColorsSoft.navy,
              ),
            ),
            const SizedBox(height: 2),
            const Text(
              'Klik untuk input data baru',
              style: TextStyle(fontSize: 12, color: AppColorsSoft.textGray),
            ),
          ],
        ),
      ),
    );
  }
}