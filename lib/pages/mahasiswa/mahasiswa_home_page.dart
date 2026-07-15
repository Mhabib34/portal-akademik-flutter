import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../config/api_config.dart';
import '../../services/api_client.dart';
import '../../services/auth_service.dart';
import '../../widgets/mahasiswa_nav_helper.dart';
import '../../widgets/logout_dialog.dart';
import '../../widgets/ajukan_krs_bottom_sheet.dart';
import '../auth/login_page.dart';
import './mahasiswa_khs_page.dart';
import './mahasiswa_krs_page.dart';
import './mahasiswa_jadwal_page.dart';
import './mahasiswa_nilai_page.dart';
import '../../utils/app_toast.dart';

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
    AppToast.show(context, msg, isError: isError);
  }

  Future<void> _logout() async {
    final konfirmasi = await showLogoutDialog(context);
    if (konfirmasi != true) return;

    await AuthService.logout();
    // Tunggu animasi dialog selesai sebelum destroy rute
    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  // ---------------- UI Building ----------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: Container(
        decoration: BoxDecoration(gradient: AppColorsSoft.backgroundGradient),
        child: SafeArea(
          bottom: false,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
            children: _isLoading
                ? [
                    _buildTopBar(),
                    const SizedBox(height: 150),
                    const Center(child: CircularProgressIndicator(color: AppColorsSoft.navy)),
                  ]
                : [
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
      bottomNavigationBar: MahasiswaNavHelper.buildNav(
        context: context,
        currentIndex: _navIndex,
        userId: widget.userId,
        nama: widget.nama,
        username: widget.username,
        nim: widget.nim,
        centerActionOnTap: () => AjukanKrsBottomSheet.show(context, onSuccess: _loadData),
        onBerandaTap: () => setState(() => _navIndex = 0),
      ),
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
        IconButton(
          onPressed: _logout,
          tooltip: 'Logout',
          icon: const Icon(
            Icons.logout_rounded,
            color: Color(0xFFE05252),
            size: 22,
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
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Image.asset(
              'assets/images/banner_kuliah.png',
              height: 150,
              width: double.infinity,
              fit: BoxFit.fitHeight,
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
              onTap: () {
                if (m.label == 'KHS') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => MahasiswaKhsPage(
                        userId: widget.userId,
                        nama: widget.nama,
                        username: widget.username,
                        nim: widget.nim,
                      ),
                    ),
                  );
                } else if (m.label == 'KRS') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => MahasiswaKrsPage(
                        userId: widget.userId,
                        nama: widget.nama,
                        username: widget.username,
                        nim: widget.nim,
                      ),
                    ),
                  );
                } else if (m.label == 'Jadwal Kuliah') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => MahasiswaJadwalPage(
                        userId: widget.userId,
                        nama: widget.nama,
                        username: widget.username,
                        nim: widget.nim,
                      ),
                    ),
                  );
                } else if (m.label == 'Nilai/Transkrip') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => MahasiswaNilaiPage(
                        userId: widget.userId,
                        nama: widget.nama,
                        username: widget.username,
                        nim: widget.nim,
                      ),
                    ),
                  );
                } else {
                  _handlePlaceholder(m.label);
                }
              },
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

}

class _MenuData {
  final IconData icon;
  final String label;
  final Color iconBg;
  final Color iconColor;
  const _MenuData(this.icon, this.label, this.iconBg, this.iconColor);
}
