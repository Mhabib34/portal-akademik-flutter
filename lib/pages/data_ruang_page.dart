import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../config/api_config.dart';
import '../services/api_client.dart';
import '../models/ruang_model.dart';

const List<Map<String, dynamic>> _iconPalette = [
  {
    'icon': Icons.meeting_room_rounded,
    'bg': Color(0xFFDCEBFF),
    'fg': Color(0xFF2E6FE0),
  },
  {
    'icon': Icons.door_front_door_rounded,
    'bg': Color(0xFFFCE3D6),
    'fg': Color(0xFFE06A2E),
  },
  {
    'icon': Icons.apartment_rounded,
    'bg': Color(0xFFEEE3FF),
    'fg': Color(0xFF8B5CF6),
  },
  {
    'icon': Icons.business_rounded,
    'bg': Color(0xFFD9F5E4),
    'fg': Color(0xFF12A150),
  },
  {
    'icon': Icons.room_preferences_rounded,
    'bg': Color(0xFFFFF6D6),
    'fg': Color(0xFFCBA400),
  },
];

class DataRuangPage extends StatefulWidget {
  const DataRuangPage({super.key});

  @override
  State<DataRuangPage> createState() => _DataRuangPageState();
}

class _DataRuangPageState extends State<DataRuangPage> {
  List<Ruang> _all = [];
  List<Ruang> _filtered = [];
  Map<String, int> _jadwalCount = {}; // ruang_id -> jumlah jadwal
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
      final ruangRes = await ApiClient.get(ApiConfig.getRuang);
      if (ruangRes['status'] == 'ok') {
        final list = (ruangRes['data'] as List)
            .map((e) => Ruang.fromJson(e as Map<String, dynamic>))
            .toList();
        _all = list;
        _applySearch();
      }

      final jadwalRes = await ApiClient.get(ApiConfig.getJadwal);
      if (jadwalRes['status'] == 'ok') {
        final List jadwalList = jadwalRes['data'] as List? ?? [];
        final Map<String, int> counts = {};
        for (final j in jadwalList) {
          final map = j as Map<String, dynamic>;
          final ruangId = map['ruang_id']?.toString();
          if (ruangId == null) continue;
          counts[ruangId] = (counts[ruangId] ?? 0) + 1;
        }
        _jadwalCount = counts;
      }
    } catch (_) {
      _showSnackBar('Gagal memuat data ruang', isError: true);
    }
    if (mounted) setState(() => _isLoading = false);
  }

  void _applySearch() {
    final q = _searchQuery.toLowerCase();
    _filtered = q.isEmpty
        ? List.from(_all)
        : _all
            .where((r) =>
                r.namaRuang.toLowerCase().contains(q) ||
                r.gedung.toLowerCase().contains(q))
            .toList();
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

  // Membuka form tambah/edit. Konten form sengaja dipisah ke widget
  // _RuangFormSheet sendiri (lihat di bawah) yang punya lifecycle
  // sendiri (initState/dispose) — supaya TextEditingController-nya
  // di-dispose otomatis oleh Flutter TEPAT saat widget itu benar-benar
  // lepas dari tree, bukan di-dispose manual segera setelah `await`
  // selesai (yang ternyata masih lebih cepat daripada animasi sheet
  // selesai menutup, dan itu penyebab crash sebelumnya).
  Future<void> _showFormDialog({Ruang? existing}) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _RuangFormSheet(
        existing: existing,
        onSubmit: (body) async {
          try {
            final url = existing == null
                ? ApiConfig.simpanRuang
                : ApiConfig.updateRuang;
            final data = await ApiClient.postForm(url, body: body);
            if (data['status'] == 'ok') return null; // null = sukses
            return data['message']?.toString() ?? 'Gagal menyimpan data';
          } catch (_) {
            return 'Koneksi gagal';
          }
        },
      ),
    );

    if (result == true) {
      _showSnackBar(
        existing == null
            ? 'Ruang berhasil ditambahkan'
            : 'Ruang berhasil diperbarui',
      );
      await _loadData();
    }
  }

  Future<void> _deleteRuang(Ruang r) async {
    final jumlahJadwal = _jadwalCount[r.id] ?? 0;
    final konfirmasi = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Hapus Ruang'),
        content: Text(
          jumlahJadwal > 0
              ? 'Hapus ruang "${r.namaRuang}"? Ruang ini sedang digunakan oleh $jumlahJadwal jadwal.'
              : 'Hapus ruang "${r.namaRuang}"?',
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
        ApiConfig.deleteRuang,
        body: {'id': r.id},
      );
      if (data['status'] == 'ok') {
        _showSnackBar('Ruang berhasil dihapus');
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
                      'Data Ruang',
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
                    hint: 'Cari nama ruang atau gedung...',
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
                                      'Belum ada data ruang',
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
                                  final r = _filtered[i];
                                  final palette =
                                      _iconPalette[i % _iconPalette.length];
                                  final jumlahJadwal = _jadwalCount[r.id] ?? 0;

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
                                            const SizedBox(width: 14),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    r.namaRuang,
                                                    style: const TextStyle(
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.w800,
                                                      color: AppColorsSoft.navy,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    '${r.gedung} • Kapasitas: ${r.kapasitas}',
                                                    style: const TextStyle(
                                                      fontSize: 13,
                                                      color:
                                                          AppColorsSoft.textGray,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            IconButton(
                                              onPressed: () =>
                                                  _showFormDialog(existing: r),
                                              icon: const Icon(
                                                Icons.edit_outlined,
                                                size: 19,
                                                color: AppColorsSoft.textGray,
                                              ),
                                              visualDensity:
                                                  VisualDensity.compact,
                                            ),
                                            IconButton(
                                              onPressed: () => _deleteRuang(r),
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
                                        const Divider(
                                            height: 1,
                                            color: AppColorsSoft.fieldFill),
                                        const SizedBox(height: 12),
                                        Row(
                                          children: [
                                            const Icon(
                                              Icons.event_note_rounded,
                                              size: 15,
                                              color: AppColorsSoft.textGray,
                                            ),
                                            const SizedBox(width: 5),
                                            Text(
                                              '$jumlahJadwal Jadwal Terdaftar',
                                              style: const TextStyle(
                                                fontSize: 12.5,
                                                color: AppColorsSoft.textGray,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
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

// ============================================================
// _RuangFormSheet — konten form Tambah/Edit Ruang.
//
// Sengaja dijadikan StatefulWidget TERPISAH (bukan builder inline +
// StatefulBuilder) supaya TextEditingController dimiliki dan
// di-dispose oleh lifecycle widget ini sendiri (initState/dispose).
// Ini penting: kalau controller dibuat di function luar lalu
// di-dispose manual persis setelah `await showModalBottomSheet(...)`
// selesai, dispose() itu kepanggil SEBELUM animasi keluar sheet
// benar-benar selesai (TextField masih hidup selama animasi),
// sehingga TextField masih pakai controller yang sudah mati ->
// "A TextEditingController was used after being disposed" -> lalu
// merembet jadi error-error lain yang membingungkan
// (_dependents.isEmpty, Duplicate GlobalKeys, dst).
//
// Dengan controller dimiliki State widget ini sendiri, Flutter yang
// akan memanggil dispose() pada waktu yang benar (persis saat widget
// ini betul-betul di-unmount dari tree), jadi tidak ada lagi race.
// ============================================================
class _RuangFormSheet extends StatefulWidget {
  final Ruang? existing;
  // Mengembalikan null jika sukses, atau pesan error jika gagal.
  final Future<String?> Function(Map<String, String> body) onSubmit;

  const _RuangFormSheet({required this.existing, required this.onSubmit});

  @override
  State<_RuangFormSheet> createState() => _RuangFormSheetState();
}

class _RuangFormSheetState extends State<_RuangFormSheet> {
  late final TextEditingController namaCtrl;
  late final TextEditingController gedungCtrl;
  late final TextEditingController kapasitasCtrl;
  bool saving = false;

  @override
  void initState() {
    super.initState();
    namaCtrl = TextEditingController(text: widget.existing?.namaRuang ?? '');
    gedungCtrl = TextEditingController(text: widget.existing?.gedung ?? '');
    kapasitasCtrl = TextEditingController(
      text: widget.existing?.kapasitas.toString() ?? '',
    );
  }

  @override
  void dispose() {
    namaCtrl.dispose();
    gedungCtrl.dispose();
    kapasitasCtrl.dispose();
    super.dispose();
  }

  void _showLocalSnackBar(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: const Color(0xFFE05252),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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

  Future<void> _submit() async {
    if (namaCtrl.text.trim().isEmpty) {
      _showLocalSnackBar('Nama ruang wajib diisi');
      return;
    }
    setState(() => saving = true);
    final body = <String, String>{
      'nama_ruang': namaCtrl.text.trim(),
      'gedung': gedungCtrl.text.trim(),
      'kapasitas': kapasitasCtrl.text.trim(),
      if (widget.existing != null) 'id': widget.existing!.id.toString(),
    };
    final errorMsg = await widget.onSubmit(body);
    if (!mounted) return;
    if (errorMsg == null) {
      Navigator.pop(context, true);
    } else {
      setState(() => saving = false);
      _showLocalSnackBar(errorMsg);
    }
  }

  @override
  Widget build(BuildContext context) {
    final existing = widget.existing;
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
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
                existing == null ? 'Tambah Ruang' : 'Edit Ruang',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColorsSoft.navy,
                ),
              ),
              const SizedBox(height: 20),
              _formLabel('Nama Ruang'),
              const SizedBox(height: 8),
              TextField(
                controller: namaCtrl,
                decoration: AppColorsSoft.fieldDecoration(
                  hint: 'Nama Ruang (mis. R-101)',
                  prefixIcon: Icons.meeting_room_rounded,
                ),
              ),
              const SizedBox(height: 16),
              _formLabel('Gedung'),
              const SizedBox(height: 8),
              TextField(
                controller: gedungCtrl,
                decoration: AppColorsSoft.fieldDecoration(
                  hint: 'Gedung (mis. Gedung A)',
                  prefixIcon: Icons.business_rounded,
                ),
              ),
              const SizedBox(height: 16),
              _formLabel('Kapasitas'),
              const SizedBox(height: 8),
              TextField(
                controller: kapasitasCtrl,
                keyboardType: TextInputType.number,
                decoration: AppColorsSoft.fieldDecoration(
                  hint: 'Kapasitas (mis. 40)',
                  prefixIcon: Icons.people_alt_rounded,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed:
                          saving ? null : () => Navigator.pop(context),
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
                      onPressed: saving ? null : _submit,
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
  }
}