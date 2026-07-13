import 'package:flutter/material.dart';
import '../../../widgets/admin_nav_helper.dart';

import '../../../theme/app_theme.dart';
import '../../../config/api_config.dart';
import '../../../services/api_client.dart';

// ============================================================
// data_kelas_page.dart — CRUD Kelas (admin)
// ============================================================

class DataKelasPage extends StatefulWidget {
  const DataKelasPage({super.key});

  @override
  State<DataKelasPage> createState() => _DataKelasPageState();
}

class _DataKelasPageState extends State<DataKelasPage> {
  List<Map<String, dynamic>> _kelasList = [];
  List<Map<String, dynamic>> _mataKuliahList = [];
  List<Map<String, dynamic>> _dosenList = [];
  List<Map<String, dynamic>> _tahunAjaranList = [];

  bool _isLoading = true;
  String _searchQuery = '';
  String _filterTahunAjaranId = '';
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
      final results = await Future.wait([
        ApiClient.get(ApiConfig.getKelas),
        ApiClient.get(ApiConfig.getMataKuliah),
        ApiClient.get(ApiConfig.getDosen),
        ApiClient.get(ApiConfig.getTahunAjaran),
      ]);

      final kelasRes = results[0];
      final mkRes = results[1];
      final dosenRes = results[2];
      final taRes = results[3];

      if (mkRes['status'] == 'ok') {
        _mataKuliahList = (mkRes['data'] as List? ?? [])
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
      }

      if (dosenRes['status'] == 'ok') {
        _dosenList = (dosenRes['data'] as List? ?? [])
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
      }

      if (taRes['status'] == 'ok') {
        _tahunAjaranList = (taRes['data'] as List? ?? [])
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
      }

      if (kelasRes['status'] == 'ok') {
        _kelasList = (kelasRes['data'] as List? ?? [])
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
      }
    } catch (_) {
      _showSnackBar('Gagal memuat data kelas', isError: true);
    }
    if (mounted) setState(() => _isLoading = false);
  }

  List<Map<String, dynamic>> get _filteredKelas {
    final q = _searchQuery.toLowerCase();
    return _kelasList.where((k) {
      final namaMk = (k['nama_mk'] ?? '').toString().toLowerCase();
      final namaKelas = (k['nama_kelas'] ?? '').toString().toLowerCase();
      final matchSearch =
          q.isEmpty || namaMk.contains(q) || namaKelas.contains(q);
      final matchTa = _filterTahunAjaranId.isEmpty ||
          k['tahun_ajaran_id']?.toString() == _filterTahunAjaranId;
      return matchSearch && matchTa;
    }).toList();
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

  Future<void> _showFormDialog({Map<String, dynamic>? existing}) async {
    if (_mataKuliahList.isEmpty) {
      _showSnackBar('Data Mata Kuliah kosong. Tambahkan dulu!', isError: true);
      return;
    }
    if (_tahunAjaranList.isEmpty) {
      _showSnackBar('Data Tahun Ajaran kosong. Tambahkan dulu!', isError: true);
      return;
    }

    final namaKelasCtrl = TextEditingController(
      text: existing?['nama_kelas']?.toString() ?? '',
    );
    String? selectedMkId = existing?['mata_kuliah_id']?.toString() ??
        _mataKuliahList.first['id']?.toString();
    String? selectedDosenId = existing?['dosen_id']?.toString() ??
        (_dosenList.isNotEmpty ? _dosenList.first['id']?.toString() : null);
    String? selectedTaId = existing?['tahun_ajaran_id']?.toString();

    if (selectedTaId == null) {
      // Cari TA aktif
      for (final t in _tahunAjaranList) {
        if (int.tryParse(t['is_aktif']?.toString() ?? '0') == 1) {
          selectedTaId = t['id'].toString();
          break;
        }
      }
      // Fallback TA pertama jika tidak ada yang aktif
      selectedTaId ??= _tahunAjaranList.isNotEmpty
          ? _tahunAjaranList.first['id'].toString()
          : null;
    }

    bool saving = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          Future<void> submit() async {
            if (namaKelasCtrl.text.trim().isEmpty ||
                selectedMkId == null ||
                selectedDosenId == null ||
                selectedTaId == null) {
              _showSnackBar(
                'Nama Kelas, Mata Kuliah, Dosen, dan Tahun Ajaran wajib diisi',
                isError: true,
              );
              return;
            }
            setSheetState(() => saving = true);
            try {
              final body = {
                'nama_kelas': namaKelasCtrl.text.trim(),
                'mata_kuliah_id': selectedMkId!,
                'dosen_id': selectedDosenId!,
                'tahun_ajaran_id': selectedTaId!,
                if (existing != null) 'id': existing['id'].toString(),
              };
              final url = existing == null
                  ? ApiConfig.simpanKelas
                  : ApiConfig.updateKelas;
              final data = await ApiClient.postForm(url, body: body);
              if (data['status'] == 'ok') {
                if (mounted) Navigator.pop(ctx);
                _showSnackBar(
                  existing == null
                      ? 'Kelas berhasil ditambahkan'
                      : 'Kelas berhasil diperbarui',
                );
                _loadData();
              } else {
                setSheetState(() => saving = false);
                _showSnackBar(
                  data['message']?.toString() ?? 'Gagal menyimpan data',
                  isError: true,
                );
              }
            } catch (e) {
              setSheetState(() => saving = false);
              _showSnackBar(e.toString(), isError: true);
            }
          }

          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
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
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: AppColorsSoft.fieldFill,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    Text(
                      existing == null ? 'Buka Kelas Baru' : 'Edit Kelas',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColorsSoft.navy,
                      ),
                    ),
                    const SizedBox(height: 18),
                    _fieldLabel('Mata Kuliah'),
                    const SizedBox(height: 8),
                    InputDecorator(
                      decoration: AppColorsSoft.fieldDecoration(
                        hint: 'Pilih Mata Kuliah',
                        prefixIcon: Icons.menu_book_rounded,
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          isExpanded: true,
                          isDense: true,
                          value: selectedMkId,
                          items: _mataKuliahList
                              .map(
                                (m) => DropdownMenuItem(
                                  value: m['id'].toString(),
                                  child: Text(
                                    '${m['kode_mk'] ?? '-'} - ${m['nama_mk'] ?? '-'}',
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (v) =>
                              setSheetState(() => selectedMkId = v),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    _fieldLabel('Nama Kelas / Rombel'),
                    const SizedBox(height: 8),
                    TextField(
                      controller: namaKelasCtrl,
                      decoration: AppColorsSoft.fieldDecoration(
                        hint: 'Contoh: A, B, atau Reguler Pagi',
                        prefixIcon: Icons.label_rounded,
                      ),
                    ),
                    const SizedBox(height: 14),
                    _fieldLabel('Dosen Pengampu'),
                    const SizedBox(height: 8),
                    InputDecorator(
                      decoration: AppColorsSoft.fieldDecoration(
                        hint: 'Pilih Dosen',
                        prefixIcon: Icons.person_rounded,
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          isExpanded: true,
                          isDense: true,
                          value: selectedDosenId,
                          items: _dosenList
                              .map(
                                (d) => DropdownMenuItem(
                                  value: d['id'].toString(),
                                  child: Text(
                                    d['nama']?.toString() ?? '-',
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (v) =>
                              setSheetState(() => selectedDosenId = v),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    _fieldLabel('Tahun Ajaran'),
                    const SizedBox(height: 8),
                    InputDecorator(
                      decoration: AppColorsSoft.fieldDecoration(
                        hint: 'Pilih Tahun Ajaran',
                        prefixIcon: Icons.calendar_today_rounded,
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          isExpanded: true,
                          isDense: true,
                          value: selectedTaId,
                          items: _tahunAjaranList
                              .map(
                                (t) => DropdownMenuItem(
                                  value: t['id'].toString(),
                                  child: Text(
                                    '${t['nama'] ?? '-'} (Smt ${t['semester'] ?? '-'})',
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (v) =>
                              setSheetState(() => selectedTaId = v),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: saving ? null : submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColorsSoft.navy,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(26),
                          ),
                        ),
                        child: saving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                existing == null ? 'Simpan' : 'Simpan Perubahan',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                      ),
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

  Widget _fieldLabel(String text) => Text(
        text,
        style: const TextStyle(
          fontSize: 12.5,
          fontWeight: FontWeight.w700,
          color: AppColorsSoft.navy,
        ),
      );

  Future<void> _deleteKelas(Map<String, dynamic> k) async {
    final konfirmasi = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Hapus Kelas'),
        content: Text(
            'Hapus kelas "${k['nama_mk']} - ${k['nama_kelas']}"?\nPenghapusan bisa gagal jika kelas ini digunakan pada jadwal atau KRS mahasiswa.'),
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
        ApiConfig.deleteKelas,
        body: {'id': k['id'].toString()},
      );
      if (data['status'] == 'ok') {
        _showSnackBar('Kelas berhasil dihapus');
        _loadData();
      } else {
        _showSnackBar(data['message']?.toString() ?? 'Gagal menghapus',
            isError: true);
      }
    } catch (e) {
      _showSnackBar(e.toString(), isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final list = _filteredKelas;
    return Scaffold(
      bottomNavigationBar: AdminNavHelper.buildNav(context: context, currentIndex: -1),
      body: Container(
        decoration: BoxDecoration(gradient: AppColorsSoft.backgroundGradient),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 20, 0),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(
                        Icons.arrow_back_rounded,
                        color: AppColorsSoft.navy,
                      ),
                    ),
                    const Text(
                      'Data Kelas',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: AppColorsSoft.navy,
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
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
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: TextField(
                  controller: _searchCtrl,
                  decoration: AppColorsSoft.fieldDecoration(
                    hint: 'Cari mata kuliah atau kelas...',
                    prefixIcon: Icons.search_rounded,
                  ),
                  onChanged: (v) => setState(() => _searchQuery = v),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: [
                    _filterChip('Semua Tahun Ajaran', ''),
                    ..._tahunAjaranList.map((t) => _filterChip(
                        '${t['nama'] ?? '-'}', t['id'].toString())),
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
                          itemCount: list.length + 1,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 14),
                          itemBuilder: (_, i) {
                            if (i == list.length) {
                              return _buildAddCard();
                            }
                            if (list.isEmpty && i == 0) {
                              return const Padding(
                                padding: EdgeInsets.only(top: 20, bottom: 10),
                                child: Center(
                                  child: Text(
                                    'Belum ada data kelas',
                                    style: TextStyle(
                                      color: AppColorsSoft.textGray,
                                    ),
                                  ),
                                ),
                              );
                            }
                            return _buildKelasCard(list[i]);
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

  Widget _filterChip(String label, String taId) {
    final selected = _filterTahunAjaranId == taId;
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: GestureDetector(
        onTap: () => setState(() {
          _filterTahunAjaranId = taId;
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

  Widget _buildKelasCard(Map<String, dynamic> k) {
    final namaMk = k['nama_mk']?.toString() ?? '-';
    final namaKelas = k['nama_kelas']?.toString() ?? '-';
    final namaDosen = k['nama_dosen']?.toString() ?? 'Belum ada dosen';

    String taLabel = '-';
    final ta = _tahunAjaranList.where((t) => t['id'].toString() == k['tahun_ajaran_id']?.toString()).toList();
    if (ta.isNotEmpty) {
      taLabel = '${ta.first['nama'] ?? ''} (Smt ${ta.first['semester'] ?? ''})';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppColorsSoft.card(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEE3FF),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Kelas $namaKelas',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF8B5CF6),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  taLabel,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColorsSoft.textGray,
                  ),
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                ),
              ),
              IconButton(
                onPressed: () => _showFormDialog(existing: k),
                icon: const Icon(
                  Icons.edit_outlined,
                  size: 19,
                  color: AppColorsSoft.textGray,
                ),
                visualDensity: VisualDensity.compact,
              ),
              IconButton(
                onPressed: () => _deleteKelas(k),
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  size: 19,
                  color: Color(0xFFE05252),
                ),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            namaMk,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColorsSoft.navy,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(
                Icons.person_rounded,
                size: 16,
                color: AppColorsSoft.textGrayLight,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  namaDosen,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: k['dosen_id'] != null && k['dosen_id'].toString().isNotEmpty
                        ? AppColorsSoft.textGray
                        : AppColorsSoft.textGrayLight,
                    fontStyle: k['dosen_id'] != null && k['dosen_id'].toString().isNotEmpty
                        ? FontStyle.normal
                        : FontStyle.italic,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
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
              'Buka Kelas Baru',
              style: TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w800,
                color: AppColorsSoft.navy,
              ),
            ),
            const SizedBox(height: 2),
            const Text(
              'Klik untuk buka kelas',
              style: TextStyle(fontSize: 12, color: AppColorsSoft.textGray),
            ),
          ],
        ),
      ),
    );
  }
}
