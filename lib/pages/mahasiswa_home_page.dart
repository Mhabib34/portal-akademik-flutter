import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../config/api_config.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';
import 'login_page.dart';

// ============================================================
// mahasiswa_home_page.dart — Dashboard Mahasiswa
//   Redesain sesuai referensi UI (banner semester, kartu IPK/SKS/
//   KRS, menu cepat, jadwal hari ini, FAB "Ajukan KRS"). Semua
//   data diambil sesuai openapi spec:
//   - IPK & SKS kumulatif -> get_khs.php (tanpa param = smt aktif)
//   - Status KRS -> get_krs.php, dicocokkan ke tahun_ajaran aktif
//   - Semester aktif -> get_tahun_ajaran.php (is_aktif == 1)
//   - Jadwal hari ini -> get_jadwal.php (otomatis dari KRS
//     disetujui sesuai spec), field `dosen` & `nama_ruang` sudah
//     tersedia langsung di schema Jadwal, tidak perlu join manual.
//   Catatan: "Top 5%" (ranking) dihapus karena tidak ada di spec.
//   "Target: 144" SKS di-hardcode (standar umum S1), karena tidak
//   ada field target kelulusan di spec.
// ============================================================

const List<String> _hariEnum = [
  'Senin',
  'Selasa',
  'Rabu',
  'Kamis',
  'Jumat',
  'Sabtu',
];

const List<String> _namaBulan = [
  '',
  'Januari',
  'Februari',
  'Maret',
  'April',
  'Mei',
  'Juni',
  'Juli',
  'Agustus',
  'September',
  'Oktober',
  'November',
  'Desember',
];

class MahasiswaHomePage extends StatefulWidget {
  final String userId;
  final String nama;
  final String username;
  final String nim;

  const MahasiswaHomePage({
    super.key,
    required this.userId,
    required this.nama,
    required this.username,
    required this.nim,
  });

  @override
  State<MahasiswaHomePage> createState() => _MahasiswaHomePageState();
}

class _MahasiswaHomePageState extends State<MahasiswaHomePage> {
  int _navIndex = 0;
  bool _isLoading = true;

  String _semesterTag = '-';
  String _semesterLabel = '-';
  String? _tahunAjaranAktifId;

  String _ipk = '-';
  String _totalSks = '-';

  String _krsValue = '-';
  String _krsTag = 'Belum Ajukan';
  Color _krsColor = AppColorsSoft.textGray;

  List<Map<String, dynamic>> _jadwalHariIni = [];

  String? get _hariIni {
    final weekday = DateTime.now().weekday;
    if (weekday < 1 || weekday > 6) return null;
    return _hariEnum[weekday - 1];
  }

  String get _tanggalHariIni {
    final now = DateTime.now();
    final hari = _hariIni ?? 'Minggu';
    return '$hari, ${now.day} ${_namaBulan[now.month]}';
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      // 1. Tahun ajaran aktif
      final taRes = await ApiClient.get(ApiConfig.getTahunAjaran);
      if (taRes['status'] == 'ok') {
        final List taList = taRes['data'] as List? ?? [];
        for (final t in taList) {
          final map = t as Map<String, dynamic>;
          if (int.tryParse(map['is_aktif']?.toString() ?? '0') == 1) {
            _tahunAjaranAktifId = map['id']?.toString();
            _semesterLabel = map['nama']?.toString() ?? '-';
            _semesterTag = 'Semester ${map['semester'] ?? ''}'.trim();
            break;
          }
        }
      }

      // 2. IPK & SKS kumulatif dari KHS semester aktif
      final khsRes = await ApiClient.get(ApiConfig.getKhs);
      if (khsRes['status'] == 'ok' && khsRes['data'] != null) {
        final khs = khsRes['data'] as Map<String, dynamic>;
        _ipk = (khs['ipk_kumulatif'] ?? 0).toString();
        _totalSks = (khs['total_sks_kumulatif'] ?? 0).toString();
      }

      // 3. Status KRS untuk tahun ajaran aktif
      final krsRes = await ApiClient.get(ApiConfig.getKrs);
      if (krsRes['status'] == 'ok' && krsRes['data'] != null) {
        Map<String, dynamic>? krs;
        final raw = krsRes['data'];
        if (raw is List) {
          for (final k in raw) {
            final map = k as Map<String, dynamic>;
            if (map['tahun_ajaran_id']?.toString() == _tahunAjaranAktifId) {
              krs = map;
              break;
            }
          }
        } else if (raw is Map<String, dynamic>) {
          if (raw['tahun_ajaran_id']?.toString() == _tahunAjaranAktifId) {
            krs = raw;
          }
        }

        if (krs != null) {
          final status = krs['status']?.toString() ?? '';
          switch (status) {
            case 'disetujui':
              _krsValue = 'Aktif';
              _krsTag = 'Terverifikasi';
              _krsColor = const Color(0xFF12A150);
              break;
            case 'menunggu':
              _krsValue = 'Menunggu';
              _krsTag = 'Diproses';
              _krsColor = const Color(0xFFCBA400);
              break;
            case 'ditolak':
              _krsValue = 'Ditolak';
              _krsTag = 'Perlu Revisi';
              _krsColor = const Color(0xFFE05252);
              break;
          }
        }
      }

      // 4. Jadwal hari ini (otomatis dari KRS disetujui, sesuai spec)
      final hariIni = _hariIni;
      if (hariIni != null) {
        final jadwalRes = await ApiClient.get(
          ApiConfig.getJadwal,
          queryParams: {'hari': hariIni},
        );
        if (jadwalRes['status'] == 'ok') {
          final List list = jadwalRes['data'] as List? ?? [];
          _jadwalHariIni =
              list.map((e) => Map<String, dynamic>.from(e as Map)).toList()
                ..sort(
                  (a, b) => (a['jam_mulai'] ?? '').toString().compareTo(
                    (b['jam_mulai'] ?? '').toString(),
                  ),
                );
        }
      } else {
        _jadwalHariIni = [];
      }
    } catch (_) {
      _showSnackBar('Gagal memuat data dashboard', isError: true);
    }

    if (mounted) setState(() => _isLoading = false);
  }

  void _handlePlaceholder(String fitur) {
    _showSnackBar('$fitur akan segera hadir');
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

  Future<void> _logout() async {
    final konfirmasi = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Keluar dari Portal'),
        content: const Text('Anda yakin ingin keluar?'),
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
            child: const Text('Keluar'),
          ),
        ],
      ),
    );

    if (konfirmasi != true) return;

    await AuthService.logout();
    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  void _onNavTap(int index) {
    if (index == 0) {
      setState(() => _navIndex = 0);
      return;
    }
    if (index == 3) {
      _logout();
      return;
    }
    _handlePlaceholder(['Beranda', 'Jadwal', 'Nilai', 'Profil'][index]);
  }

  // ---------------- Ajukan KRS (FAB tengah) ----------------
  Future<void> _openAjukanKrsSheet() async {
    List<Map<String, dynamic>> kelasTersedia = [];
    bool isLoadingKelas = true;
    bool isSubmitting = false;
    final Set<String> selectedIds = {};

    try {
      final res = await ApiClient.get(ApiConfig.getKelasTersedia);
      if (res['status'] == 'ok') {
        final List list = res['data'] as List? ?? [];
        kelasTersedia = list
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
      }
    } catch (_) {
      // biarkan list kosong, ditangani di UI
    }
    isLoadingKelas = false;

    if (!mounted) return;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          final totalSksDipilih = kelasTersedia
              .where((k) => selectedIds.contains(k['id'].toString()))
              .fold<int>(
                0,
                (sum, k) =>
                    sum + (int.tryParse(k['sks']?.toString() ?? '0') ?? 0),
              );

          Future<void> submit() async {
            if (selectedIds.isEmpty) {
              _showSnackBar('Pilih minimal 1 kelas', isError: true);
              return;
            }
            setSheetState(() => isSubmitting = true);
            try {
              final res = await ApiClient.postJson(
                ApiConfig.ajukanKrs,
                body: {'kelas_ids': selectedIds.toList()},
              );
              if (res['status'] == 'ok') {
                if (mounted) Navigator.pop(ctx);
                _showSnackBar(
                  'KRS berhasil diajukan, menunggu persetujuan admin',
                );
                _loadData();
              } else {
                setSheetState(() => isSubmitting = false);
                _showSnackBar(
                  res['message']?.toString() ?? 'Gagal mengajukan KRS',
                  isError: true,
                );
              }
            } catch (_) {
              setSheetState(() => isSubmitting = false);
              _showSnackBar('Gagal terhubung ke server', isError: true);
            }
          }

          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
            ),
            child: Container(
              height: MediaQuery.of(ctx).size.height * 0.75,
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
              decoration: const BoxDecoration(
                color: AppColorsSoft.cardWhite,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
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
                  const Text(
                    'Ajukan KRS',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppColorsSoft.navy,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Total SKS dipilih: $totalSksDipilih',
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: AppColorsSoft.textGray,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: isLoadingKelas
                        ? const Center(
                            child: CircularProgressIndicator(
                              color: AppColorsSoft.navy,
                            ),
                          )
                        : kelasTersedia.isEmpty
                        ? const Center(
                            child: Text(
                              'Tidak ada kelas tersedia',
                              style: TextStyle(color: AppColorsSoft.textGray),
                            ),
                          )
                        : ListView.separated(
                            itemCount: kelasTersedia.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 10),
                            itemBuilder: (_, i) {
                              final k = kelasTersedia[i];
                              final id = k['id'].toString();
                              final checked = selectedIds.contains(id);
                              return InkWell(
                                onTap: () => setSheetState(
                                  () => checked
                                      ? selectedIds.remove(id)
                                      : selectedIds.add(id),
                                ),
                                borderRadius: BorderRadius.circular(16),
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: checked
                                        ? AppColorsSoft.navy.withOpacity(0.06)
                                        : AppColorsSoft.fieldFill,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Row(
                                    children: [
                                      Checkbox(
                                        value: checked,
                                        activeColor: AppColorsSoft.navy,
                                        onChanged: (_) => setSheetState(
                                          () => checked
                                              ? selectedIds.remove(id)
                                              : selectedIds.add(id),
                                        ),
                                      ),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              '${k['nama_mk'] ?? '-'} (${k['nama_kelas'] ?? '-'})',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w700,
                                                color: AppColorsSoft.navy,
                                                fontSize: 13,
                                              ),
                                            ),
                                            Text(
                                              '${k['sks'] ?? 0} SKS • ${k['nama_dosen'] ?? '-'}',
                                              style: const TextStyle(
                                                fontSize: 11.5,
                                                color: AppColorsSoft.textGray,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: isSubmitting ? null : submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColorsSoft.navy,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(26),
                        ),
                      ),
                      child: isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Ajukan KRS',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: Container(
        decoration: BoxDecoration(gradient: AppColorsSoft.backgroundGradient),
        child: SafeArea(
          bottom: false,
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: AppColorsSoft.navy),
                )
              : RefreshIndicator(
                  color: AppColorsSoft.navy,
                  onRefresh: _loadData,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
                    children: [
                      _buildTopBar(),
                      const SizedBox(height: 20),
                      _buildBanner(),
                      const SizedBox(height: 20),
                      _buildStatRow(),
                      const SizedBox(height: 24),
                      _buildMenuGrid(),
                      const SizedBox(height: 24),
                      _buildJadwalCard(),
                    ],
                  ),
                ),
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildTopBar() {
    return Row(
      children: [
        GestureDetector(
          onTap: _logout,
          child: CircleAvatar(
            radius: 20,
            backgroundColor: AppColorsSoft.navy,
            child: Text(
              widget.nama.isNotEmpty ? widget.nama[0].toUpperCase() : 'M',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            'Halo, ${widget.nama}',
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColorsSoft.navy,
            ),
          ),
        ),
        IconButton(
          onPressed: () => _handlePlaceholder('Notifikasi'),
          icon: const Icon(
            Icons.notifications_none_rounded,
            color: AppColorsSoft.navy,
          ),
        ),
      ],
    );
  }

  Widget _buildBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: AppColorsSoft.card(),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColorsSoft.gradientPeach,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _semesterTag,
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: AppColorsSoft.navy,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Semester Aktif:\n${_isLoading ? '...' : _semesterLabel}',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppColorsSoft.navy,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: 180,
            height: 44,
            child: ElevatedButton(
              onPressed: () => _handlePlaceholder('Jadwal Kuliah'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColorsSoft.navy,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              child: const Text(
                'Lihat Jadwal',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            height: 150,
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColorsSoft.gradientLavender,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Center(
              child: Icon(
                Icons.school_rounded,
                size: 40,
                color: AppColorsSoft.navy,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow() {
    Widget stat(
      String label,
      String value,
      String tag,
      Color tagBg,
      Color tagFg,
    ) {
      return Expanded(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 5),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
          decoration: AppColorsSoft.card(),
          child: Column(
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColorsSoft.textGray,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColorsSoft.navy,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: tagBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  tag,
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    color: tagFg,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Row(
      children: [
        stat(
          'IPK',
          _isLoading ? '...' : _ipk,
          'Kumulatif',
          const Color(0xFFD9F5E4),
          const Color(0xFF12A150),
        ),
        stat(
          'SKS',
          _isLoading ? '...' : _totalSks,
          'Target: 144',
          const Color(0xFFDCEBFF),
          const Color(0xFF2E6FE0),
        ),
        stat(
          'KRS',
          _isLoading ? '...' : _krsValue,
          _krsTag,
          _krsColor.withOpacity(0.14),
          _krsColor,
        ),
      ],
    );
  }

  Widget _buildMenuGrid() {
    final menu = [
      _MenuData(
        Icons.calendar_month_rounded,
        'Jadwal Kuliah',
        const Color(0xFFEEE3FF),
        const Color(0xFF8B5CF6),
      ),
      _MenuData(
        Icons.school_rounded,
        'Nilai/Transkrip',
        const Color(0xFFFFE8CC),
        const Color(0xFFE08A00),
      ),
      _MenuData(
        Icons.edit_note_rounded,
        'KRS',
        const Color(0xFFEEE3FF),
        const Color(0xFF8B5CF6),
      ),
      _MenuData(
        Icons.fact_check_rounded,
        'KHS',
        const Color(0xFFDCEBFF),
        const Color(0xFF2E6FE0),
      ),
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 14,
      crossAxisSpacing: 14,
      childAspectRatio: 1.4,
      children: menu
          .map(
            (m) => InkWell(
              onTap: () => _handlePlaceholder(m.label),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: AppColorsSoft.card(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: m.iconBg,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(m.icon, size: 18, color: m.iconColor),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      m.label,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: AppColorsSoft.navy,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildJadwalCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: AppColorsSoft.card(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Jadwal Hari Ini',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppColorsSoft.navy,
                ),
              ),
              const Spacer(),
              Text(
                _tanggalHariIni,
                style: const TextStyle(
                  fontSize: 11.5,
                  color: AppColorsSoft.textGray,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (_jadwalHariIni.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Text(
                  'Tidak ada jadwal kuliah hari ini',
                  style: TextStyle(color: AppColorsSoft.textGray),
                ),
              ),
            )
          else
            ..._jadwalHariIni.map((j) {
              final jamMulai = (j['jam_mulai'] ?? '').toString();
              final jamSelesai = (j['jam_selesai'] ?? '').toString();
              final namaMk = j['nama_mk']?.toString() ?? '-';
              final namaRuang = j['nama_ruang']?.toString() ?? '-';
              final dosen = j['dosen']?.toString() ?? '-';

              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 52,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            jamMulai,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: AppColorsSoft.navy,
                            ),
                          ),
                          Text(
                            jamSelesai,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColorsSoft.textGrayLight,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            namaMk,
                            style: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              color: AppColorsSoft.navy,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '$namaRuang • $dosen',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColorsSoft.textGray,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
          Center(
            child: TextButton(
              onPressed: () => _handlePlaceholder('Jadwal Kuliah'),
              child: const Text(
                'Lihat Selengkapnya',
                style: TextStyle(
                  color: AppColorsSoft.linkAccent,
                  fontWeight: FontWeight.w700,
                  fontSize: 12.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    final items = [
      (Icons.home_rounded, 'Home'),
      (Icons.calendar_month_rounded, 'Schedule'),
      (Icons.school_rounded, 'Grades'),
      (Icons.person_rounded, 'Profile'),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: SizedBox(
        height: 76,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.topCenter,
          children: [
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 64,
                decoration: BoxDecoration(
                  color: AppColorsSoft.cardWhite,
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [
                    BoxShadow(
                      color: AppColorsSoft.navy.withOpacity(0.10),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _navItem(items[0], 0),
                    _navItem(items[1], 1),
                    const SizedBox(width: 48),
                    _navItem(items[2], 2),
                    _navItem(items[3], 3),
                  ],
                ),
              ),
            ),
            Positioned(
              top: 0,
              child: GestureDetector(
                onTap: _openAjukanKrsSheet,
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppColorsSoft.navy,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColorsSoft.navy.withOpacity(0.3),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.add_rounded,
                    color: Colors.white,
                    size: 26,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _navItem((IconData, String) item, int index) {
    final selected = index == _navIndex;
    return Expanded(
      child: InkWell(
        onTap: () => _onNavTap(index),
        borderRadius: BorderRadius.circular(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: selected
                    ? AppColorsSoft.navy.withOpacity(0.08)
                    : Colors.transparent,
                shape: BoxShape.circle,
              ),
              child: Icon(
                item.$1,
                size: 20,
                color: selected
                    ? AppColorsSoft.navy
                    : AppColorsSoft.textGrayLight,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuData {
  final IconData icon;
  final String label;
  final Color iconBg;
  final Color iconColor;
  const _MenuData(this.icon, this.label, this.iconBg, this.iconColor);
}
