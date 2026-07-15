import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../config/api_config.dart';
import '../../services/api_client.dart';
import '../../services/auth_service.dart';
import '../../widgets/dosen_nav_helper.dart';
import '../../widgets/logout_dialog.dart';
import '../auth/login_page.dart';
import 'dosen_input_nilai_page.dart';
import 'dosen_jadwal_page.dart';
import 'dosen_mahasiswa_page.dart';
import 'dosen_profil_page.dart';
import '../../utils/app_toast.dart';

// ============================================================
// dosen_home_page.dart — Dashboard Dosen
//   Redesain sesuai referensi UI (banner semester aktif, 3 stat
//   card, menu cepat, jadwal mengajar hari ini). Semua data
//   diambil dari API sesuai openapi spec — tidak ada field yang
//   dikarang di luar schema.
// ============================================================

class DosenHomePage extends StatefulWidget {
  final String userId;
  final String nama;
  final String username;

  const DosenHomePage({
    super.key,
    required this.userId,
    required this.nama,
    required this.username,
  });

  @override
  State<DosenHomePage> createState() => _DosenHomePageState();
}

// Urutan hari sesuai enum `hari` di schema Jadwal (Senin..Sabtu).
const List<String> _hariEnum = [
  'Senin',
  'Selasa',
  'Rabu',
  'Kamis',
  'Jumat',
  'Sabtu',
];

class _DosenHomePageState extends State<DosenHomePage> {
  int _navIndex = 0;
  bool _isLoading = true;
  String _dosenId = '';

  String _semesterAktif = '-';
  int _totalMataKuliah = 0;
  int _totalMahasiswa = 0;
  List<Map<String, dynamic>> _jadwalHariIni = [];



  @override
  void initState() {
    super.initState();
    _loadData();
  }

  String? get _hariIni {
    // DateTime.weekday: 1=Senin ... 7=Minggu. Enum hari tidak punya
    // 'Minggu', jadi kalau hari Minggu dianggap tidak ada jadwal.
    final weekday = DateTime.now().weekday;
    if (weekday < 1 || weekday > 6) return null;
    return _hariEnum[weekday - 1];
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      // 1. Profil dosen -> dosen_id
      final profil = await ApiClient.get(ApiConfig.getDosen);
      if (profil['status'] == 'ok') {
        final data = profil['data'] as Map<String, dynamic>;
        _dosenId = data['id']?.toString() ?? '';
      }

      // 2. Kelas yang diampu dosen ini (untuk hitung mata kuliah &
      //    total mahasiswa, serta join jumlah_terisi ke jadwal).
      Map<String, dynamic> kelasById = {};
      if (_dosenId.isNotEmpty) {
        final kelasRes = await ApiClient.get(
          ApiConfig.getKelas,
          queryParams: {'dosen_id': _dosenId},
        );
        if (kelasRes['status'] == 'ok') {
          final List kelasList = kelasRes['data'] as List? ?? [];
          final mataKuliahIds = <String>{};
          var totalMhs = 0;
          for (final k in kelasList) {
            final map = k as Map<String, dynamic>;
            kelasById[map['id'].toString()] = map;
            final mkId = map['mata_kuliah_id']?.toString();
            if (mkId != null && mkId.isNotEmpty) mataKuliahIds.add(mkId);
            totalMhs +=
                int.tryParse(map['jumlah_terisi']?.toString() ?? '0') ?? 0;
          }
          _totalMataKuliah = mataKuliahIds.length;
          _totalMahasiswa = totalMhs;
        }
      }

      // 3. Tahun ajaran aktif -> label "Semester Aktif"
      final taRes = await ApiClient.get(ApiConfig.getTahunAjaran);
      if (taRes['status'] == 'ok') {
        final List taList = taRes['data'] as List? ?? [];
        for (final t in taList) {
          final map = t as Map<String, dynamic>;
          if (int.tryParse(map['is_aktif']?.toString() ?? '0') == 1) {
            _semesterAktif = '${map['nama'] ?? ''} ${map['semester'] ?? ''}'
                .trim();
            break;
          }
        }
      }

      // 4. Jadwal mengajar dosen ini, difilter hari ini.
      //    Sesuai spec, get_jadwal.php sudah otomatis terfilter ke
      //    kelas milik dosen yang login (tanpa perlu param dosen_id).
      final hariIni = _hariIni;
      if (hariIni != null) {
        final jadwalRes = await ApiClient.get(
          ApiConfig.getJadwal,
          queryParams: {'hari': hariIni},
        );
        if (jadwalRes['status'] == 'ok') {
          final List jadwalList = jadwalRes['data'] as List? ?? [];
          _jadwalHariIni =
              jadwalList.map((j) {
                final map = Map<String, dynamic>.from(
                  j as Map<String, dynamic>,
                );
                final kelas = kelasById[map['kelas_id']?.toString()];
                map['jumlah_mahasiswa'] = kelas?['jumlah_terisi'];
                return map;
              }).toList()..sort(
                (a, b) => (a['jam_mulai'] ?? '').toString().compareTo(
                  (b['jam_mulai'] ?? '').toString(),
                ),
              );
        }
      } else {
        _jadwalHariIni = [];
      }
    } catch (_) {
      // biarkan tampil nilai default kalau gagal
    }

    if (mounted) setState(() => _isLoading = false);
  }

  void _handlePlaceholder(String fitur) {
    AppToast.show(context, '$fitur akan segera hadir', isError: false);
  }

  Future<void> _logout() async {
    final konfirmasi = await showLogoutDialog(context);
    if (konfirmasi != true) return;

    await AuthService.logout();
    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
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
          child: RefreshIndicator(
            color: AppColorsSoft.navy,
            onRefresh: _loadData,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 110),
              children: [
                _buildTopBar(),
                const SizedBox(height: 20),
                _buildBanner(),
                const SizedBox(height: 20),
                _buildStatRow(),
                const SizedBox(height: 28),
                const Text(
                  'Menu Cepat',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColorsSoft.navy,
                  ),
                ),
                const SizedBox(height: 12),
                _buildMenuGrid(),
                const SizedBox(height: 28),
                _buildJadwalHeader(),
                const SizedBox(height: 12),
                _buildJadwalList(),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: DosenNavHelper.buildNav(
        context: context,
        currentIndex: _navIndex,
        onLogout: _logout,
        onBerandaTap: () => setState(() => _navIndex = 0),
        onJadwalTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => DosenJadwalPage(
                userId: widget.userId,
                nama: widget.nama,
                username: widget.username,
              ),
            ),
          );
        },
        onNilaiTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => DosenInputNilaiPage(
                userId: widget.userId,
                nama: widget.nama,
                username: widget.username,
              ),
            ),
          );
        },
        onProfilTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => DosenProfilPage(
                userId: widget.userId,
                nama: widget.nama,
                username: widget.username,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTopBar() {
    return Row(
      children: [
        GestureDetector(
          onTap: _logout,
          child: CircleAvatar(
            radius: 22,
            backgroundColor: AppColorsSoft.navy,
            child: Text(
              widget.nama.isNotEmpty ? widget.nama[0].toUpperCase() : 'D',
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
            'Selamat datang, ${widget.nama}',
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColorsSoft.gradientLavender,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'Dashboard Pengajar',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: AppColorsSoft.navy,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Semester Aktif:\n${_isLoading ? '...' : _semesterAktif}',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColorsSoft.navy,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Pastikan jadwal dan nilai mahasiswa terupdate tepat waktu.',
            style: TextStyle(
              fontSize: 13,
              color: AppColorsSoft.textGray,
              fontWeight: FontWeight.w500,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
         ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Image.asset(
              'assets/images/banner_dosen.png',
              height: 130,
              width: double.infinity,
              fit: BoxFit.fitHeight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow() {
    final stats = [
      _StatData(
        Icons.menu_book_rounded,
        'Mata\nKuliah',
        _isLoading ? '...' : '$_totalMataKuliah',
        const Color(0xFFDCEBFF),
        const Color(0xFF2E6FE0),
      ),
      _StatData(
        Icons.groups_rounded,
        'Mahasiswa',
        _isLoading ? '...' : '$_totalMahasiswa',
        const Color(0xFFFCE3D6),
        const Color(0xFFE06A2E),
      ),
      _StatData(
        Icons.event_available_rounded,
        'Kelas Hari\nIni',
        _isLoading ? '...' : '${_jadwalHariIni.length}',
        const Color(0xFFEEE3FF),
        const Color(0xFF8B5CF6),
      ),
    ];

    return Row(
      children: stats
          .map(
            (s) => Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: s == stats.last ? 0 : 12),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 16,
                    horizontal: 12,
                  ),
                  decoration: AppColorsSoft.card(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: s.iconBg,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(s.icon, size: 16, color: s.iconColor),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        s.label,
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: AppColorsSoft.textGray,
                          fontWeight: FontWeight.w600,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        s.value,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: AppColorsSoft.navy,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildMenuGrid() {
    final menu = [
      _DosenMenuData(
        Icons.calendar_month_rounded,
        'Jadwal Mengajar',
        const Color(0xFFDCEBFF),
        const Color(0xFF2E6FE0),
      ),
      _DosenMenuData(
        Icons.edit_note_rounded,
        'Input Nilai',
        const Color(0xFFD9F5E4),
        const Color(0xFF12A150),
      ),
      _DosenMenuData(
        Icons.groups_rounded,
        'Daftar Mahasiswa',
        const Color(0xFFFFF6D6),
        const Color(0xFFCBA400),
      ),
      _DosenMenuData(
        Icons.person_rounded,
        'Profil',
        const Color(0xFFFCE3E9),
        const Color(0xFFE0527A),
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
                if (m.label == 'Input Nilai') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => DosenInputNilaiPage(
                        userId: widget.userId,
                        nama: widget.nama,
                        username: widget.username,
                      ),
                    ),
                  );
                } else if (m.label == 'Jadwal Mengajar') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => DosenJadwalPage(
                        userId: widget.userId,
                        nama: widget.nama,
                        username: widget.username,
                      ),
                    ),
                  );
                } else if (m.label == 'Daftar Mahasiswa') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => DosenMahasiswaPage(
                        userId: widget.userId,
                        nama: widget.nama,
                        username: widget.username,
                      ),
                    ),
                  );
                } else if (m.label == 'Profil') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => DosenProfilPage(
                        userId: widget.userId,
                        nama: widget.nama,
                        username: widget.username,
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

  Widget _buildJadwalHeader() {
    return Row(
      children: [
        const Text(
          'Jadwal Mengajar Hari Ini',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: AppColorsSoft.navy,
          ),
        ),
        const Spacer(),
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => DosenJadwalPage(
                  userId: widget.userId,
                  nama: widget.nama,
                  username: widget.username,
                ),
              ),
            );
          },
          child: const Text(
            'Lihat Semua',
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: AppColorsSoft.linkAccent,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildJadwalList() {
    if (_isLoading) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: AppColorsSoft.card(),
        child: const Center(
          child: Text(
            'Memuat jadwal...',
            style: TextStyle(color: AppColorsSoft.textGray),
          ),
        ),
      );
    }

    if (_jadwalHariIni.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: AppColorsSoft.card(),
        child: const Center(
          child: Text(
            'Tidak ada jadwal mengajar hari ini',
            style: TextStyle(color: AppColorsSoft.textGray),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4),
      decoration: AppColorsSoft.card(),
      child: Column(
        children: _jadwalHariIni.map((j) {
          final jamMulai = (j['jam_mulai'] ?? '').toString();
          final jamShort = jamMulai.length >= 2
              ? jamMulai.substring(0, 2)
              : jamMulai;
          final namaMk = j['nama_mk']?.toString() ?? '-';
          final namaRuang = j['nama_ruang']?.toString() ?? '-';
          final jumlahMhs = j['jumlah_mahasiswa'];

          return InkWell(
            onTap: () => _handlePlaceholder('Detail Jadwal'),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Container(
                    width: 46,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColorsSoft.fieldFill,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Text(
                          jamShort,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: AppColorsSoft.navy,
                          ),
                        ),
                        const Text(
                          'WIB',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: AppColorsSoft.textGrayLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          namaMk,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColorsSoft.navy,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Ruang $namaRuang'
                          '${jumlahMhs != null ? ' • $jumlahMhs Mahasiswa' : ''}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColorsSoft.textGray,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColorsSoft.textGrayLight,
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _StatData {
  final IconData icon;
  final String label;
  final String value;
  final Color iconBg;
  final Color iconColor;
  const _StatData(
    this.icon,
    this.label,
    this.value,
    this.iconBg,
    this.iconColor,
  );
}

class _DosenMenuData {
  final IconData icon;
  final String label;
  final Color iconBg;
  final Color iconColor;
  const _DosenMenuData(this.icon, this.label, this.iconBg, this.iconColor);
}
