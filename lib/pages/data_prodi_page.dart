import 'package:flutter/material.dart';
import '../widgets/admin_nav_helper.dart';

import '../theme/app_theme.dart';
import '../config/api_config.dart';
import '../services/api_client.dart';
import '../models/fakultas_model.dart';
import '../models/prodi_model.dart';

// ============================================================
// data_prodi_page.dart — CRUD Prodi (admin)
//   Redesain sesuai referensi UI: stats ringkas di atas, kartu
//   dengan ikon dekoratif + jumlah mahasiswa per prodi.
//
//   CATATAN PENTING (sesuai kesepakatan):
//   - Badge "Akreditasi" DIHAPUS — field ini tidak ada sama sekali
//     di schema Prodi maupun entity lain di spec.
//   - Card "Kapasitas %" adalah PLACEHOLDER STATIS (dummy), bukan
//     dari data asli — tidak ada metrik kapasitas program studi di
//     spec manapun. Ganti/hapus begitu ada sumber data sebenarnya.
//   - Jumlah mahasiswa per prodi & total mahasiswa dihitung dari
//     fetch penuh get_mahasiswa.php lalu di-group per prodi_id di
//     client (karena get_prodi.php tidak punya field count/relasi
//     balik ke mahasiswa). Untuk data mahasiswa dalam jumlah besar
//     ini bisa terasa berat saat load pertama — reuse hasil fetch
//     yang sama untuk total & per-kartu, tidak fetch dua kali.
//   - Ikon per kartu murni dekoratif (cycle berdasar index), sama
//     seperti Data Fakultas — schema Prodi tidak punya field
//     kategori/jenjang untuk menentukan ikon yang relevan.
//   - Bisa dibuka dengan filter awal dari Data Fakultas (parameter
//     fakultasId & namaFakultas opsional).
// ============================================================

const List<Map<String, dynamic>> _iconPalette = [
  {
    'icon': Icons.school_rounded,
    'bg': Color(0xFFDCEBFF),
    'fg': Color(0xFF2E6FE0),
  },
  {
    'icon': Icons.medical_services_rounded,
    'bg': Color(0xFFFFE8CC),
    'fg': Color(0xFFE08A00),
  },
  {
    'icon': Icons.architecture_rounded,
    'bg': Color(0xFFEEE3FF),
    'fg': Color(0xFF8B5CF6),
  },
  {
    'icon': Icons.show_chart_rounded,
    'bg': Color(0xFFD9F5E4),
    'fg': Color(0xFF12A150),
  },
  {
    'icon': Icons.bolt_rounded,
    'bg': Color(0xFFFFF6D6),
    'fg': Color(0xFFCBA400),
  },
  {
    'icon': Icons.public_rounded,
    'bg': Color(0xFFFCE3D6),
    'fg': Color(0xFFE06A2E),
  },
  {
    'icon': Icons.science_rounded,
    'bg': Color(0xFFFFE0E0),
    'fg': Color(0xFFE05252),
  },
];

class DataProdiPage extends StatefulWidget {
  final String? fakultasId;
  final String? namaFakultas;

  const DataProdiPage({super.key, this.fakultasId, this.namaFakultas});

  @override
  State<DataProdiPage> createState() => _DataProdiPageState();
}

class _DataProdiPageState extends State<DataProdiPage> {
  List<Fakultas> _fakultasList = [];
  List<Prodi> _all = [];
  List<Prodi> _filtered = [];
  Map<String, int> _mahasiswaCount = {}; // prodi_id -> jumlah mahasiswa
  int _totalMahasiswa = 0;
  bool _isLoading = true;
  String _searchQuery = '';
  String _filterFakultasId = '';
  final _searchCtrl = TextEditingController();

  // Placeholder statis — belum ada metrik kapasitas prodi di spec.
  static const int _kapasitasDummy = 92;

  @override
  void initState() {
    super.initState();
    _filterFakultasId = widget.fakultasId ?? '';
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
      final fakultasResp = await ApiClient.get(ApiConfig.getFakultas);
      if (fakultasResp['status'] == 'ok') {
        _fakultasList = (fakultasResp['data'] as List)
            .map((e) => Fakultas.fromJson(e as Map<String, dynamic>))
            .toList();
      }

      final prodiResp = await ApiClient.get(ApiConfig.getProdi);
      if (prodiResp['status'] == 'ok') {
        final namaFakultasMap = {
          for (final f in _fakultasList) f.id: f.namaFakultas,
        };
        _all = (prodiResp['data'] as List).map((e) {
          final json = e as Map<String, dynamic>;
          final fakultasId = (json['fakultas_id'] ?? '').toString();
          return Prodi.fromJson(
            json,
            namaFakultas: namaFakultasMap[fakultasId] ?? '',
          );
        }).toList();
        _applyFilter();
      }

      // Fetch semua mahasiswa sekali, dipakai untuk total & grouping per prodi.
      final mhsResp = await ApiClient.get(ApiConfig.getMahasiswa);
      if (mhsResp['status'] == 'ok') {
        final List mhsList = mhsResp['data'] as List? ?? [];
        _totalMahasiswa = mhsList.length;
        final Map<String, int> counts = {};
        for (final m in mhsList) {
          final map = m as Map<String, dynamic>;
          final prodiId = map['prodi_id']?.toString();
          if (prodiId == null) continue;
          counts[prodiId] = (counts[prodiId] ?? 0) + 1;
        }
        _mahasiswaCount = counts;
      }
    } catch (_) {
      _showSnackBar('Gagal memuat data prodi', isError: true);
    }
    if (mounted) setState(() => _isLoading = false);
  }

  void _applyFilter() {
    final q = _searchQuery.toLowerCase();
    _filtered = _all.where((p) {
      final matchSearch = q.isEmpty || p.namaProdi.toLowerCase().contains(q);
      final matchFakultas =
          _filterFakultasId.isEmpty || p.fakultasId == _filterFakultasId;
      return matchSearch && matchFakultas;
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

  String _formatCount(int n) {
    if (n >= 1000) {
      final k = n / 1000;
      return '${k.toStringAsFixed(k.truncateToDouble() == k ? 0 : 1)}K';
    }
    return '$n';
  }

  Future<void> _showFormDialog({Prodi? existing}) async {
    if (_fakultasList.isEmpty) {
      _showSnackBar(
        'Tambahkan data Fakultas dulu sebelum membuat Prodi',
        isError: true,
      );
      return;
    }

    final namaCtrl = TextEditingController(text: existing?.namaProdi ?? '');
    String? selectedFakultasId = existing?.fakultasId ?? _fakultasList.first.id;
    bool saving = false;
    bool success = false;
    String? errorMsg;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => StatefulBuilder(
        builder: (builderCtx, setSheetState) {
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
                      existing == null ? 'Tambah Prodi' : 'Edit Prodi',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppColorsSoft.navy,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _formLabel('Pilih Fakultas'),
                    const SizedBox(height: 8),
                InputDecorator(
                  decoration: AppColorsSoft.fieldDecoration(
                    hint: 'Pilih Fakultas',
                    prefixIcon: Icons.account_balance_rounded,
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: selectedFakultasId,
                      isDense: true,
                      items: _fakultasList
                          .map(
                            (f) => DropdownMenuItem(
                              value: f.id,
                              child: Text(
                                f.namaFakultas,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (v) => setSheetState(() => selectedFakultasId = v),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _formLabel('Nama Program Studi'),
                const SizedBox(height: 8),
                TextField(
                  controller: namaCtrl,
                  decoration: AppColorsSoft.fieldDecoration(
                    hint: 'Nama Program Studi',
                    prefixIcon: Icons.school_rounded,
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
                                if (selectedFakultasId == null ||
                                    namaCtrl.text.trim().isEmpty) {
                                  _showSnackBar(
                                    'Fakultas dan Nama Prodi wajib diisi',
                                    isError: true,
                                  );
                                  return;
                                }
                                setSheetState(() => saving = true);
                                try {
                                  final body = {
                                    'fakultas_id': selectedFakultasId!,
                                    'nama_prodi': namaCtrl.text.trim(),
                                    if (existing != null) 'id': existing.id,
                                  };
                                  final url = existing == null
                                      ? ApiConfig.simpanProdi
                                      : ApiConfig.updateProdi;
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
      );
    },
  ),
);
    await Future.delayed(const Duration(milliseconds: 300));
    if (mounted) {
      namaCtrl.dispose();
    }

    if (success) {
      _showSnackBar(
        existing == null
            ? 'Prodi berhasil ditambahkan'
            : 'Prodi berhasil diperbarui',
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

  Future<void> _deleteProdi(Prodi p) async {
    final jumlahMhs = _mahasiswaCount[p.id] ?? 0;
    final konfirmasi = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Hapus Prodi'),
        content: Text(
          jumlahMhs > 0
              ? 'Hapus "${p.namaProdi}"? Prodi ini masih punya $jumlahMhs mahasiswa terdaftar — kemungkinan besar akan ditolak backend.'
              : 'Hapus "${p.namaProdi}"?',
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
        ApiConfig.deleteProdi,
        body: {'id': p.id},
      );
      if (data['status'] == 'ok') {
        _showSnackBar('Prodi berhasil dihapus');
        await _loadData();
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
                      'Data Prodi',
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
                        child: ListView(
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                          children: [
                            TextField(
                              controller: _searchCtrl,
                              decoration: AppColorsSoft.fieldDecoration(
                                hint: 'Cari Program Studi...',
                                prefixIcon: Icons.search_rounded,
                              ),
                              onChanged: (v) => setState(() {
                                _searchQuery = v;
                                _applyFilter();
                              }),
                            ),
                            const SizedBox(height: 12),
                            InputDecorator(
                              decoration: AppColorsSoft.fieldDecoration(
                                hint: 'Semua Fakultas',
                                prefixIcon: Icons.account_balance_rounded,
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  isExpanded: true,
                                  value: _filterFakultasId.isEmpty
                                      ? null
                                      : _filterFakultasId,
                                  isDense: true,
                                  hint: const Text('Semua Fakultas'),
                                  items: [
                                    const DropdownMenuItem(
                                      value: '',
                                      child: Text(
                                        'Semua Fakultas',
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    ..._fakultasList.map(
                                      (f) => DropdownMenuItem(
                                        value: f.id,
                                        child: Text(
                                          f.namaFakultas,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ),
                                  ],
                                  onChanged: (v) => setState(() {
                                    _filterFakultasId = v ?? '';
                                    _applyFilter();
                                  }),
                                ),
                              ),
                            ),
                            const SizedBox(height: 18),
                            _buildStatCard(
                              icon: Icons.school_rounded,
                              iconBg: const Color(0xFFEEE3FF),
                              iconFg: const Color(0xFF8B5CF6),
                              label: 'TOTAL PRODI',
                              value: '${_all.length}',
                              accented: true,
                            ),
                            const SizedBox(height: 12),
                            _buildStatCard(
                              icon: Icons.people_alt_rounded,
                              iconBg: const Color(0xFFEEE3FF),
                              iconFg: const Color(0xFF8B5CF6),
                              label: 'MAHASISWA',
                              value: _formatCount(_totalMahasiswa),
                            ),
                            const SizedBox(height: 12),
                            _buildKapasitasCard(),
                            const SizedBox(height: 22),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Expanded(
                                  child: Text(
                                    'Daftar Program Studi',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                      color: AppColorsSoft.navy,
                                    ),
                                  ),
                                ),
                                Text(
                                  'Menampilkan ${_filtered.length} item',
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    color: AppColorsSoft.textGray,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            if (_filtered.isEmpty)
                              const Padding(
                                padding: EdgeInsets.only(top: 30),
                                child: Center(
                                  child: Text(
                                    'Belum ada data prodi',
                                    style: TextStyle(
                                      color: AppColorsSoft.textGray,
                                    ),
                                  ),
                                ),
                              )
                            else
                              ..._filtered.asMap().entries.map((entry) {
                                final i = entry.key;
                                final p = entry.value;
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 14),
                                  child: _buildProdiCard(p, i),
                                );
                              }),
                          ],
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required Color iconBg,
    required Color iconFg,
    required String label,
    required String value,
    bool accented = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColorsSoft.cardWhite,
        borderRadius: BorderRadius.circular(20),
        border: accented
            ? const Border(
                left: BorderSide(color: AppColorsSoft.navy, width: 4),
              )
            : null,
        boxShadow: [
          BoxShadow(
            color: AppColorsSoft.navy.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 20, color: iconFg),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: AppColorsSoft.textGray,
                  letterSpacing: 0.4,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColorsSoft.navy,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildKapasitasCard() {
    return Container(
      decoration: AppColorsSoft.card(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Text(
                'KAPASITAS',
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: AppColorsSoft.textGray,
                  letterSpacing: 0.4,
                ),
              ),
              SizedBox(width: 6),
              Tooltip(
                message:
                    'Data contoh (placeholder) — belum ada metrik kapasitas di API',
                child: Icon(
                  Icons.info_outline_rounded,
                  size: 13,
                  color: AppColorsSoft.textGrayLight,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          const Text(
            '$_kapasitasDummy%',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColorsSoft.navy,
            ),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: _kapasitasDummy / 100,
              minHeight: 8,
              backgroundColor: AppColorsSoft.fieldFill,
              valueColor: const AlwaysStoppedAnimation(AppColorsSoft.navy),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProdiCard(Prodi p, int index) {
    final palette = _iconPalette[index % _iconPalette.length];
    final jumlahMhs = _mahasiswaCount[p.id] ?? 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppColorsSoft.card(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: palette['bg'] as Color,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  palette['icon'] as IconData,
                  size: 20,
                  color: palette['fg'] as Color,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: () => _showFormDialog(existing: p),
                icon: const Icon(
                  Icons.edit_outlined,
                  size: 19,
                  color: AppColorsSoft.textGray,
                ),
                visualDensity: VisualDensity.compact,
              ),
              IconButton(
                onPressed: () => _deleteProdi(p),
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
            p.namaProdi,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColorsSoft.navy,
            ),
          ),
          if (p.namaFakultas.isNotEmpty) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFEEE3FF),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                p.namaFakultas,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF8B5CF6),
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          const Divider(height: 1, color: AppColorsSoft.fieldFill),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildAvatarStack(jumlahMhs),
              const Spacer(),
              Text(
                '$jumlahMhs Mahasiswa',
                style: const TextStyle(
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

  // Avatar stack dekoratif (bukan foto asli — spec tidak punya foto mahasiswa),
  // jumlah lingkaran maksimal 2 lalu ditutup badge "+N" sesuai jumlah asli.
  Widget _buildAvatarStack(int count) {
    if (count == 0) {
      return const Text(
        'Belum ada mahasiswa',
        style: TextStyle(
          fontSize: 11.5,
          color: AppColorsSoft.textGrayLight,
          fontStyle: FontStyle.italic,
        ),
      );
    }
    final dotCount = count > 2 ? 2 : count;
    final extraBadge = count > 2 ? 1 : 0;
    final stackWidth =
        (dotCount + extraBadge - 1) * 18.0 + 28.0; // ⬅️ hitung lebar total

    return SizedBox(
      height: 28,
      width: stackWidth, // ⬅️ ini yang tadinya nggak ada, bikin Stack unbounded
      child: Stack(
        children: [
          for (int i = 0; i < dotCount; i++)
            Positioned(
              left: i * 18.0,
              child: CircleAvatar(
                radius: 14,
                backgroundColor: AppColorsSoft.cardWhite,
                child: CircleAvatar(
                  radius: 12,
                  backgroundColor: AppColorsSoft.gradientLavender,
                  child: const Icon(
                    Icons.person_rounded,
                    size: 14,
                    color: AppColorsSoft.navy,
                  ),
                ),
              ),
            ),
          if (count > 2)
            Positioned(
              left: dotCount * 18.0,
              child: CircleAvatar(
                radius: 14,
                backgroundColor: AppColorsSoft.cardWhite,
                child: CircleAvatar(
                  radius: 12,
                  backgroundColor: AppColorsSoft.navy,
                  child: Text(
                    '+${count - dotCount}',
                    style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
