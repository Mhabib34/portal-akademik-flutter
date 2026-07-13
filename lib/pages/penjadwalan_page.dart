import 'package:flutter/material.dart';
import '../widgets/admin_nav_helper.dart';

import '../theme/app_theme.dart';
import '../config/api_config.dart';
import '../services/api_client.dart';

// ============================================================
// penjadwalan_page.dart — Manajemen Jadwal Kuliah (admin)
//
//   CATATAN PENTING (sesuai diskusi):
//   - Filter "Semua Prodi" (bukan Jurusan) butuh join 3 langkah:
//     Jadwal.kelas_id -> Kelas.mata_kuliah_id -> MataKuliah.prodi_id.
//     Semua fetch dilakukan sekali di awal, di-mapping ke lookup
//     table di client.
//   - "SKS" per kartu diambil dari Kelas.sks (join via kelas_id),
//     karena schema Jadwal sendiri tidak punya field sks.
//   - Badge konflik dihitung CLIENT-SIDE dengan membandingkan semua
//     jadwal yang hari-nya sama: overlap jam + ruang_id sama =
//     KONFLIK RUANGAN; overlap jam + dosen (via Kelas.dosen_id) sama
//     = KONFLIK DOSEN. Ini cuma indikator visual bantu admin —
//     validasi final & penolakan (409) tetap dilakukan backend saat
//     simpan_jadwal.php/update_jadwal.php dipanggil.
//   - Form Tambah Jadwal: pilih Kelas (dari get_kelas.php, tampilkan
//     nama_mk + nama_kelas) -> pilih Ruang -> Hari -> Jam.
//   - Form Edit Jadwal: Kelas TIDAK BISA diubah (update_jadwal.php
//     di spec tidak menerima kelas_id, cuma ruang_id/hari/jam),
//     jadi field Kelas ditampilkan read-only saat edit.
// ============================================================

const List<String> _hariList = [
  'Senin',
  'Selasa',
  'Rabu',
  'Kamis',
  'Jumat',
  'Sabtu',
];

class PenjadwalanPage extends StatefulWidget {
  const PenjadwalanPage({super.key});

  @override
  State<PenjadwalanPage> createState() => _PenjadwalanPageState();
}

class _PenjadwalanPageState extends State<PenjadwalanPage> {
  bool _isLoading = true;
  String _selectedHari = 'Senin';
  String _filterProdiId = '';

  List<Map<String, dynamic>> _allJadwal = [];
  List<Map<String, dynamic>> _kelasList = [];
  List<Map<String, dynamic>> _ruangList = [];
  List<Map<String, dynamic>> _prodiList = [];

  // lookup: kelas_id -> {sks, mata_kuliah_id, dosen_id, nama_dosen}
  Map<String, Map<String, dynamic>> _kelasMap = {};
  // lookup: mata_kuliah_id -> prodi_id
  Map<String, String> _mkProdiMap = {};

  // hasil deteksi konflik: jadwal_id -> {ruangan: bool, dosen: bool}
  Map<String, Map<String, bool>> _konflik = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        ApiClient.get(ApiConfig.getJadwal),
        ApiClient.get(ApiConfig.getKelas),
        ApiClient.get(ApiConfig.getRuang),
        ApiClient.get(ApiConfig.getProdi),
        ApiClient.get(ApiConfig.getMataKuliah),
      ]);

      final jadwalRes = results[0];
      final kelasRes = results[1];
      final ruangRes = results[2];
      final prodiRes = results[3];
      final mkRes = results[4];

      if (kelasRes['status'] == 'ok') {
        final List list = kelasRes['data'] as List? ?? [];
        _kelasList = list
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
        _kelasMap = {for (final k in _kelasList) k['id'].toString(): k};
      }

      if (mkRes['status'] == 'ok') {
        final List list = mkRes['data'] as List? ?? [];
        _mkProdiMap = {
          for (final m in list)
            (m as Map)['id'].toString(): (m['prodi_id'] ?? '').toString(),
        };
      }

      if (ruangRes['status'] == 'ok') {
        final List list = ruangRes['data'] as List? ?? [];
        _ruangList = list
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
      }

      if (prodiRes['status'] == 'ok') {
        final List list = prodiRes['data'] as List? ?? [];
        _prodiList = list
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
      }

      if (jadwalRes['status'] == 'ok') {
        final List list = jadwalRes['data'] as List? ?? [];
        _allJadwal = list
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
      }

      _computeKonflik();
    } catch (_) {
      if (mounted) _showSnack('Gagal memuat data jadwal', isError: true);
    }
    if (mounted) setState(() => _isLoading = false);
  }

  int _toMinutes(String hhmm) {
    final parts = hhmm.split(':');
    if (parts.length != 2) return 0;
    return (int.tryParse(parts[0]) ?? 0) * 60 + (int.tryParse(parts[1]) ?? 0);
  }

  bool _overlap(String startA, String endA, String startB, String endB) {
    final sA = _toMinutes(startA), eA = _toMinutes(endA);
    final sB = _toMinutes(startB), eB = _toMinutes(endB);
    return sA < eB && sB < eA;
  }

  void _computeKonflik() {
    final Map<String, Map<String, bool>> result = {};
    for (final a in _allJadwal) {
      final idA = a['id'].toString();
      result[idA] = {'ruangan': false, 'dosen': false};
      final kelasA = _kelasMap[a['kelas_id']?.toString()];
      final dosenIdA = kelasA?['dosen_id']?.toString();

      for (final b in _allJadwal) {
        final idB = b['id'].toString();
        if (idA == idB) continue;
        if (a['hari'] != b['hari']) continue;
        if (!_overlap(
          a['jam_mulai']?.toString() ?? '00:00',
          a['jam_selesai']?.toString() ?? '00:00',
          b['jam_mulai']?.toString() ?? '00:00',
          b['jam_selesai']?.toString() ?? '00:00',
        ))
          continue;

        if (a['ruang_id']?.toString() == b['ruang_id']?.toString()) {
          result[idA]!['ruangan'] = true;
        }
        final kelasB = _kelasMap[b['kelas_id']?.toString()];
        final dosenIdB = kelasB?['dosen_id']?.toString();
        if (dosenIdA != null && dosenIdA.isNotEmpty && dosenIdA == dosenIdB) {
          result[idA]!['dosen'] = true;
        }
      }
    }
    _konflik = result;
  }

  List<Map<String, dynamic>> get _filteredJadwal {
    return _allJadwal.where((j) {
      if (j['hari']?.toString() != _selectedHari) return false;
      if (_filterProdiId.isNotEmpty) {
        final kelas = _kelasMap[j['kelas_id']?.toString()];
        final mkId = kelas?['mata_kuliah_id']?.toString();
        final prodiId = _mkProdiMap[mkId];
        if (prodiId != _filterProdiId) return false;
      }
      return true;
    }).toList()..sort(
      (a, b) => (a['jam_mulai'] ?? '').toString().compareTo(
        (b['jam_mulai'] ?? '').toString(),
      ),
    );
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? const Color(0xFFE05252) : AppColorsSoft.navy,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  // ---------------- Tambah / Edit Jadwal ----------------
  Future<void> _openForm({Map<String, dynamic>? existing}) async {
    final isEdit = existing != null;

    if (!isEdit && _kelasList.isEmpty) {
      _showSnack(
        'Belum ada data Kelas — buka kelas dulu sebelum menjadwalkan',
        isError: true,
      );
      return;
    }
    if (_ruangList.isEmpty) {
      _showSnack('Belum ada data Ruang', isError: true);
      return;
    }

    String? selectedKelasId =
        existing?['kelas_id']?.toString() ??
        (_kelasList.isNotEmpty ? _kelasList.first['id'].toString() : null);
    String? selectedRuangId =
        existing?['ruang_id']?.toString() ??
        (_ruangList.isNotEmpty ? _ruangList.first['id'].toString() : null);
    String selectedHari = existing?['hari']?.toString() ?? _selectedHari;
    TimeOfDay? jamMulai = existing != null
        ? _parseTime(existing['jam_mulai']?.toString())
        : null;
    TimeOfDay? jamSelesai = existing != null
        ? _parseTime(existing['jam_selesai']?.toString())
        : null;
    bool saving = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          Future<void> pickTime(bool isMulai) async {
            final picked = await showTimePicker(
              context: ctx,
              initialTime: (isMulai ? jamMulai : jamSelesai) ?? TimeOfDay.now(),
            );
            if (picked != null) {
              setSheetState(() {
                if (isMulai) {
                  jamMulai = picked;
                } else {
                  jamSelesai = picked;
                }
              });
            }
          }

          Future<void> submit() async {
            if (selectedRuangId == null ||
                jamMulai == null ||
                jamSelesai == null ||
                (!isEdit && selectedKelasId == null)) {
              _showSnack('Semua field wajib diisi', isError: true);
              return;
            }
            setSheetState(() => saving = true);
            try {
              final body = {
                'ruang_id': selectedRuangId!,
                'hari': selectedHari,
                'jam_mulai': _formatTime(jamMulai!),
                'jam_selesai': _formatTime(jamSelesai!),
                if (!isEdit) 'kelas_id': selectedKelasId!,
                if (isEdit) 'id': existing['id'].toString(),
              };
              final res = await ApiClient.postForm(
                isEdit ? ApiConfig.updateJadwal : ApiConfig.simpanJadwal,
                body: body,
              );
              if (res['status'] == 'ok') {
                if (mounted) Navigator.pop(ctx);
                _showSnack(
                  isEdit
                      ? 'Jadwal berhasil diperbarui'
                      : 'Jadwal berhasil ditambahkan',
                );
                _loadData();
              } else {
                setSheetState(() => saving = false);
                _showSnack(
                  res['message']?.toString() ??
                      'Bentrok jadwal / gagal menyimpan',
                  isError: true,
                );
              }
            } catch (_) {
              setSheetState(() => saving = false);
              _showSnack('Gagal terhubung ke server', isError: true);
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
                      isEdit ? 'Edit Jadwal' : 'Tambah Jadwal',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColorsSoft.navy,
                      ),
                    ),
                    const SizedBox(height: 18),
                    _fieldLabel('Kelas'),
                    const SizedBox(height: 8),
                    if (isEdit)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: AppColorsSoft.fieldFill,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          '${existing['nama_mk'] ?? '-'} (${existing['nama_kelas'] ?? '-'})',
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            color: AppColorsSoft.navy,
                          ),
                        ),
                      )
                    else
                      InputDecorator(
                        decoration: AppColorsSoft.fieldDecoration(
                          hint: 'Pilih Kelas',
                          prefixIcon: Icons.class_rounded,
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            isExpanded: true,
                            isDense: true,
                            value: selectedKelasId,
                            items: _kelasList
                                .map(
                                  (k) => DropdownMenuItem(
                                    value: k['id'].toString(),
                                    child: Text(
                                      '${k['nama_mk'] ?? '-'} (${k['nama_kelas'] ?? '-'})',
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                )
                                .toList(),
                            onChanged: (v) =>
                                setSheetState(() => selectedKelasId = v),
                          ),
                        ),
                      ),
                    const SizedBox(height: 14),
                    _fieldLabel('Ruang'),
                    const SizedBox(height: 8),
                    InputDecorator(
                      decoration: AppColorsSoft.fieldDecoration(
                        hint: 'Pilih Ruang',
                        prefixIcon: Icons.meeting_room_rounded,
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          isExpanded: true,
                          isDense: true,
                          value: selectedRuangId,
                          items: _ruangList
                              .map(
                                (r) => DropdownMenuItem(
                                  value: r['id'].toString(),
                                  child: Text(
                                    '${r['nama_ruang'] ?? '-'}',
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (v) =>
                              setSheetState(() => selectedRuangId = v),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    _fieldLabel('Hari'),
                    const SizedBox(height: 8),
                    InputDecorator(
                      decoration: AppColorsSoft.fieldDecoration(
                        hint: 'Pilih Hari',
                        prefixIcon: Icons.today_rounded,
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          isExpanded: true,
                          isDense: true,
                          value: selectedHari,
                          items: _hariList
                              .map(
                                (h) =>
                                    DropdownMenuItem(value: h, child: Text(h)),
                              )
                              .toList(),
                          onChanged: (v) => setSheetState(
                            () => selectedHari = v ?? selectedHari,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => pickTime(true),
                            child: _timeBox('Jam Mulai', jamMulai),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => pickTime(false),
                            child: _timeBox('Jam Selesai', jamSelesai),
                          ),
                        ),
                      ],
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
                                isEdit ? 'Simpan Perubahan' : 'Tambah Jadwal',
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

  Widget _timeBox(String label, TimeOfDay? value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: AppColorsSoft.fieldFill,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 10.5,
              color: AppColorsSoft.textGray,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value != null ? _formatTime(value) : '--:--',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColorsSoft.navy,
            ),
          ),
        ],
      ),
    );
  }

  TimeOfDay? _parseTime(String? hhmm) {
    if (hhmm == null) return null;
    final parts = hhmm.split(':');
    if (parts.length != 2) return null;
    return TimeOfDay(
      hour: int.tryParse(parts[0]) ?? 0,
      minute: int.tryParse(parts[1]) ?? 0,
    );
  }

  String _formatTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  Future<void> _confirmDelete(Map<String, dynamic> j) async {
    final konfirmasi = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Hapus Jadwal'),
        content: Text(
          'Hapus jadwal "${j['nama_mk']}" (${j['hari']}, ${j['jam_mulai']}\u2013${j['jam_selesai']})?',
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
        ApiConfig.deleteJadwal,
        body: {'id': j['id'].toString()},
      );
      if (res['status'] == 'ok') {
        _showSnack('Jadwal berhasil dihapus');
        _loadData();
      } else {
        _showSnack(
          res['message']?.toString() ?? 'Gagal menghapus',
          isError: true,
        );
      }
    } catch (_) {
      _showSnack('Gagal terhubung ke server', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final list = _filteredJadwal;

    return Scaffold(
      bottomNavigationBar: AdminNavHelper.buildNav(context: context, currentIndex: 1),
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
                      'Penjadwalan',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: AppColorsSoft.navy,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () {},
                      icon: const Icon(
                        Icons.notifications_none_rounded,
                        color: AppColorsSoft.navy,
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
                          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                          children: [
                            const Text(
                              'Manajemen Jadwal',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: AppColorsSoft.navy,
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Kelola waktu kuliah dan ketersediaan ruangan mahasiswa.',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColorsSoft.textGray,
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () => _openForm(),
                                icon: const Icon(
                                  Icons.add_rounded,
                                  color: Colors.white,
                                  size: 18,
                                ),
                                label: const Text(
                                  'Tambah Jadwal',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColorsSoft.navy,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 15,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(26),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 18),
                            Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              children: _hariList
                                  .map((h) => _hariChip(h))
                                  .toList(),
                            ),
                            const SizedBox(height: 14),
                            InputDecorator(
                              decoration: AppColorsSoft.fieldDecoration(
                                hint: 'Semua Prodi',
                                prefixIcon: Icons.school_rounded,
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  isExpanded: true,
                                  isDense: true,
                                  value: _filterProdiId.isEmpty
                                      ? null
                                      : _filterProdiId,
                                  hint: const Text('Semua Prodi'),
                                  items: [
                                    const DropdownMenuItem(
                                      value: '',
                                      child: Text('Semua Prodi'),
                                    ),
                                    ..._prodiList.map(
                                      (p) => DropdownMenuItem(
                                        value: p['id'].toString(),
                                        child: Text(
                                          '${p['nama_prodi'] ?? '-'}',
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ),
                                  ],
                                  onChanged: (v) =>
                                      setState(() => _filterProdiId = v ?? ''),
                                ),
                              ),
                            ),
                            const SizedBox(height: 18),
                            if (list.isEmpty)
                              const Padding(
                                padding: EdgeInsets.only(top: 30),
                                child: Center(
                                  child: Text(
                                    'Tidak ada jadwal di hari ini',
                                    style: TextStyle(
                                      color: AppColorsSoft.textGray,
                                    ),
                                  ),
                                ),
                              )
                            else
                              ...list.map(
                                (j) => Padding(
                                  padding: const EdgeInsets.only(bottom: 14),
                                  child: _buildJadwalCard(j),
                                ),
                              ),
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

  Widget _hariChip(String hari) {
    final selected = _selectedHari == hari;
    return GestureDetector(
      onTap: () => setState(() => _selectedHari = hari),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
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
        child: Text(
          hari,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: selected ? Colors.white : AppColorsSoft.navy,
          ),
        ),
      ),
    );
  }

  Widget _buildJadwalCard(Map<String, dynamic> j) {
    final id = j['id'].toString();
    final konflik = _konflik[id] ?? {'ruangan': false, 'dosen': false};
    final adaKonflik =
        (konflik['ruangan'] ?? false) || (konflik['dosen'] ?? false);
    final kelas = _kelasMap[j['kelas_id']?.toString()];
    final sks = kelas?['sks']?.toString() ?? '-';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColorsSoft.cardWhite,
        borderRadius: BorderRadius.circular(24),
        border: adaKonflik
            ? const Border(left: BorderSide(color: Color(0xFFCB7B2E), width: 4))
            : null,
        boxShadow: [
          BoxShadow(
            color: AppColorsSoft.navy.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${j['jam_mulai']} — ${j['jam_selesai']}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColorsSoft.navy,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'SKS: $sks',
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: AppColorsSoft.textGray,
                      ),
                    ),
                  ],
                ),
              ),
              if (adaKonflik)
                Wrap(
                  spacing: 6,
                  children: [
                    if (konflik['ruangan'] == true)
                      _konflikBadge('KONFLIK RUANGAN'),
                    if (konflik['dosen'] == true)
                      _konflikBadge('KONFLIK DOSEN'),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            j['nama_mk']?.toString() ?? '-',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColorsSoft.navy,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.location_on_outlined,
                size: 15,
                color: konflik['ruangan'] == true
                    ? const Color(0xFFCB7B2E)
                    : AppColorsSoft.textGray,
              ),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  j['nama_ruang']?.toString() ?? '-',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: konflik['ruangan'] == true
                        ? FontWeight.w700
                        : FontWeight.w500,
                    color: konflik['ruangan'] == true
                        ? const Color(0xFFCB7B2E)
                        : AppColorsSoft.textGray,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(
                Icons.person_outline_rounded,
                size: 15,
                color: konflik['dosen'] == true
                    ? const Color(0xFFCB7B2E)
                    : AppColorsSoft.textGray,
              ),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  j['dosen']?.toString() ?? '-',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: konflik['dosen'] == true
                        ? FontWeight.w700
                        : FontWeight.w500,
                    color: konflik['dosen'] == true
                        ? const Color(0xFFCB7B2E)
                        : AppColorsSoft.textGray,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                onPressed: () => _openForm(existing: j),
                icon: const Icon(
                  Icons.edit_outlined,
                  size: 19,
                  color: AppColorsSoft.textGray,
                ),
                visualDensity: VisualDensity.compact,
              ),
              IconButton(
                onPressed: () => _confirmDelete(j),
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

  Widget _konflikBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFCB7B2E).withOpacity(0.14),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.warning_rounded, size: 11, color: Color(0xFFCB7B2E)),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w800,
              color: Color(0xFFCB7B2E),
            ),
          ),
        ],
      ),
    );
  }
}
