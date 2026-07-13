import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../config/api_config.dart';
import '../services/api_client.dart';
import '../models/fakultas_model.dart';
import 'data_prodi_page.dart';

// ============================================================
// data_fakultas_page.dart — CRUD Fakultas (admin)
//   Redesain sesuai referensi UI: kartu dengan ikon berwarna,
//   jumlah program studi, dan tautan "Lihat Detail" ke halaman
//   Data Prodi (difilter per fakultas).
//
//   CATATAN:
//   - Schema Fakultas di spec cuma punya id + nama_fakultas, jadi
//     ikon per kartu TIDAK berbasis data (spec tidak punya field
//     kategori/jenis fakultas) — dibuat cycle dari palet ikon+warna
//     statis berdasarkan urutan index saja, murni dekoratif.
//   - "X Program Studi" dihitung di client dari get_prodi.php
//     (fetch semua prodi, group per fakultas_id), karena
//     get_fakultas.php tidak punya field count.
//   - "Lihat Detail" mengarah ke DataProdiPage (asumsi nama class
//     & constructor sesuai pola penamaan halaman lain — akan
//     disesuaikan begitu kode aslinya dikirim).
//   - Tetap pola back-arrow-only (tanpa bottom nav), konsisten
//     dengan halaman admin lain.
// ============================================================

// Palet ikon+warna dekoratif, cycle berdasarkan index kartu.
const List<Map<String, dynamic>> _iconPalette = [
  {
    'icon': Icons.apartment_rounded,
    'bg': Color(0xFFE3E8EF),
    'fg': Color(0xFF5B6B7D),
  },
  {
    'icon': Icons.science_rounded,
    'bg': Color(0xFFFCE3D6),
    'fg': Color(0xFFE06A2E),
  },
  {
    'icon': Icons.palette_rounded,
    'bg': Color(0xFFEEE3FF),
    'fg': Color(0xFF8B5CF6),
  },
  {
    'icon': Icons.calculate_rounded,
    'bg': Color(0xFFDCEBFF),
    'fg': Color(0xFF2E6FE0),
  },
  {
    'icon': Icons.gavel_rounded,
    'bg': Color(0xFFFFF6D6),
    'fg': Color(0xFFCBA400),
  },
  {
    'icon': Icons.medical_services_rounded,
    'bg': Color(0xFFD9F5E4),
    'fg': Color(0xFF12A150),
  },
  {
    'icon': Icons.agriculture_rounded,
    'bg': Color(0xFFFFE0E0),
    'fg': Color(0xFFE05252),
  },
];

class DataFakultasPage extends StatefulWidget {
  const DataFakultasPage({super.key});

  @override
  State<DataFakultasPage> createState() => _DataFakultasPageState();
}

class _DataFakultasPageState extends State<DataFakultasPage> {
  List<Fakultas> _all = [];
  List<Fakultas> _filtered = [];
  Map<String, int> _prodiCount = {}; // fakultas_id -> jumlah prodi
  bool _isLoading = true;
  String _searchQuery = '';
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
      final fakultasRes = await ApiClient.get(ApiConfig.getFakultas);
      if (fakultasRes['status'] == 'ok') {
        final list = (fakultasRes['data'] as List)
            .map((e) => Fakultas.fromJson(e as Map<String, dynamic>))
            .toList();
        _all = list;
        _applySearch();
      }

      // Hitung jumlah prodi per fakultas dari get_prodi.php (tanpa filter,
      // ambil semua sekali lalu di-group di client).
      final prodiRes = await ApiClient.get(ApiConfig.getProdi);
      if (prodiRes['status'] == 'ok') {
        final List prodiList = prodiRes['data'] as List? ?? [];
        final Map<String, int> counts = {};
        for (final p in prodiList) {
          final map = p as Map<String, dynamic>;
          final fakultasId = map['fakultas_id']?.toString();
          if (fakultasId == null) continue;
          counts[fakultasId] = (counts[fakultasId] ?? 0) + 1;
        }
        _prodiCount = counts;
      }
    } catch (_) {
      _showSnackBar('Gagal memuat data fakultas', isError: true);
    }
    if (mounted) setState(() => _isLoading = false);
  }

  void _applySearch() {
    final q = _searchQuery.toLowerCase();
    _filtered = q.isEmpty
        ? List.from(_all)
        : _all.where((f) => f.namaFakultas.toLowerCase().contains(q)).toList();
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

  Future<void> _showFormDialog({Fakultas? existing}) async {
    final namaCtrl = TextEditingController(text: existing?.namaFakultas ?? '');
    bool saving = false;
    bool success = false;
    String? errorMsg;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => StatefulBuilder(
        builder: (builderCtx, setSheetState) => Padding(
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
                    existing == null ? 'Tambah Fakultas' : 'Edit Fakultas',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppColorsSoft.navy,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _formLabel('Nama Fakultas'),
                  const SizedBox(height: 8),
                  TextField(
                    controller: namaCtrl,
                    decoration: AppColorsSoft.fieldDecoration(
                      hint: 'Nama Fakultas',
                      prefixIcon: Icons.account_balance_rounded,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: saving
                              ? null
                              : () {
                                  FocusManager.instance.primaryFocus?.unfocus();
                                  Future.delayed(const Duration(milliseconds: 150), () {
                                    if (sheetCtx.mounted) Navigator.pop(sheetCtx);
                                  });
                                },
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
                          onPressed: saving
                              ? null
                              : () async {
                                  if (namaCtrl.text.trim().isEmpty) {
                                    _showSnackBar(
                                      'Nama fakultas wajib diisi',
                                      isError: true,
                                    );
                                    return;
                                  }
                                  setSheetState(() => saving = true);
                                  try {
                                    final body = {
                                      'nama_fakultas': namaCtrl.text.trim(),
                                      if (existing != null) 'id': existing.id,
                                    };
                                    final url = existing == null
                                        ? ApiConfig.simpanFakultas
                                        : ApiConfig.updateFakultas;
                                    final data = await ApiClient.postForm(url, body: body);
                                    if (!sheetCtx.mounted) return;
                                    if (data['status'] == 'ok') {
                                      success = true;
                                    } else {
                                      errorMsg = data['message']?.toString() ?? 'Gagal';
                                    }
                                    FocusManager.instance.primaryFocus?.unfocus();
                                    await Future.delayed(const Duration(milliseconds: 200));
                                    if (!sheetCtx.mounted) return;
                                    Navigator.pop(sheetCtx);
                                  } catch (_) {
                                    setSheetState(() => saving = false);
                                    _showSnackBar('Koneksi gagal', isError: true);
                                  }
                                },
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
                                    valueColor: AlwaysStoppedAnimation(Colors.white),
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
        ),
      ),
    );
    await Future.delayed(const Duration(milliseconds: 300));
    if (mounted) {
      namaCtrl.dispose();
    }

    // Handle result AFTER dialog is fully closed
    if (success) {
      _showSnackBar(
        existing == null
            ? 'Fakultas berhasil ditambahkan'
            : 'Fakultas berhasil diperbarui',
      );
      await _loadData();
    } else if (errorMsg != null) {
      _showSnackBar(errorMsg!, isError: true);
    }
  }

  Widget _formLabel(String text) => Text(
        text,
        style: const TextStyle(
          fontSize: 12.5,
          fontWeight: FontWeight.w700,
          color: AppColorsSoft.navy,
        ),
      );

  Future<void> _deleteFakultas(Fakultas f) async {
    final jumlahProdi = _prodiCount[f.id] ?? 0;
    final konfirmasi = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Hapus Fakultas'),
        content: Text(
          jumlahProdi > 0
              ? 'Hapus "${f.namaFakultas}"? Fakultas ini masih punya $jumlahProdi program studi — kemungkinan besar akan ditolak backend sampai semua prodi di bawahnya dihapus/dipindah dulu.'
              : 'Hapus "${f.namaFakultas}"?',
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
      final data = await ApiClient.postForm(
        ApiConfig.deleteFakultas,
        body: {'id': f.id},
      );
      if (data['status'] == 'ok') {
        _showSnackBar('Fakultas berhasil dihapus');
        await _loadData();
      } else {
        _showSnackBar(data['message']?.toString() ?? 'Gagal', isError: true);
      }
    } catch (_) {
      _showSnackBar('Koneksi gagal', isError: true);
    }
  }

  void _openDetail(Fakultas f) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            DataProdiPage(fakultasId: f.id, namaFakultas: f.namaFakultas),
      ),
    ).then((_) => _loadData());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                      'Data Fakultas',
                      style: TextStyle(
                        fontSize: 18,
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
                    hint: 'Cari nama fakultas...',
                    prefixIcon: Icons.search_rounded,
                  ),
                  onChanged: (v) => setState(() {
                    _searchQuery = v;
                    _applySearch();
                  }),
                ),
              ),
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
                        child: _filtered.isEmpty
                            ? ListView(
                                padding: const EdgeInsets.all(40),
                                children: const [
                                  Center(
                                    child: Text(
                                      'Belum ada data fakultas',
                                      style: TextStyle(
                                        color: AppColorsSoft.textGray,
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            : ListView.separated(
                                padding: const EdgeInsets.fromLTRB(
                                  20,
                                  16,
                                  20,
                                  24,
                                ),
                                itemCount: _filtered.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 14),
                                itemBuilder: (_, i) {
                                  final f = _filtered[i];
                                  final palette =
                                      _iconPalette[i % _iconPalette.length];
                                  final jumlahProdi = _prodiCount[f.id] ?? 0;

                                  return Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: AppColorsSoft.card(),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(12),
                                              decoration: BoxDecoration(
                                                color: palette['bg'] as Color,
                                                borderRadius:
                                                    BorderRadius.circular(14),
                                              ),
                                              child: Icon(
                                                palette['icon'] as IconData,
                                                size: 22,
                                                color: palette['fg'] as Color,
                                              ),
                                            ),
                                            const Spacer(),
                                            IconButton(
                                              onPressed: () =>
                                                  _showFormDialog(existing: f),
                                              icon: const Icon(
                                                Icons.edit_outlined,
                                                size: 19,
                                                color: AppColorsSoft.textGray,
                                              ),
                                              visualDensity:
                                                  VisualDensity.compact,
                                            ),
                                            IconButton(
                                              onPressed: () =>
                                                  _deleteFakultas(f),
                                              icon: const Icon(
                                                Icons.delete_outline_rounded,
                                                size: 19,
                                                color: Color(0xFFE05252),
                                              ),
                                              visualDensity:
                                                  VisualDensity.compact,
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 12),
                                        Text(
                                          f.namaFakultas,
                                          style: const TextStyle(
                                            fontSize: 15.5,
                                            fontWeight: FontWeight.w800,
                                            color: AppColorsSoft.navy,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Row(
                                          children: [
                                            const Icon(
                                              Icons.school_outlined,
                                              size: 15,
                                              color: AppColorsSoft.textGray,
                                            ),
                                            const SizedBox(width: 5),
                                            Text(
                                              '$jumlahProdi Program Studi',
                                              style: const TextStyle(
                                                fontSize: 12.5,
                                                color: AppColorsSoft.textGray,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 12),
                                        Align(
                                          alignment: Alignment.centerRight,
                                          child: InkWell(
                                            onTap: () => _openDetail(f),
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text(
                                                  'Lihat Detail',
                                                  style: TextStyle(
                                                    fontSize: 12.5,
                                                    fontWeight: FontWeight.w700,
                                                    color: AppColorsSoft.navy
                                                        .withOpacity(0.85),
                                                  ),
                                                ),
                                                const Icon(
                                                  Icons.chevron_right_rounded,
                                                  size: 18,
                                                  color: AppColorsSoft.navy,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
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
}
