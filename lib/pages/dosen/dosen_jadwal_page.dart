import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../config/api_config.dart';
import '../../services/api_client.dart';
import '../../services/auth_service.dart';
import '../../widgets/dosen_nav_helper.dart';
import '../../widgets/logout_dialog.dart';
import '../auth/login_page.dart';
import 'dosen_profil_page.dart';
import 'dosen_input_nilai_page.dart';
import '../../widgets/custom_top_bar.dart';
import '../../utils/app_toast.dart';

// ============================================================
// dosen_jadwal_page.dart — Halaman Jadwal Mengajar Dosen
// ============================================================

class DosenJadwalPage extends StatefulWidget {
  final String userId;
  final String nama;
  final String username;

  const DosenJadwalPage({
    super.key,
    required this.userId,
    required this.nama,
    required this.username,
  });

  @override
  State<DosenJadwalPage> createState() => _DosenJadwalPageState();
}

const List<String> _hariEnum = [
  'Senin',
  'Selasa',
  'Rabu',
  'Kamis',
  'Jumat',
  'Sabtu',
];

class _DosenJadwalPageState extends State<DosenJadwalPage> {
  final int _navIndex = 1; // 1 = Jadwal
  bool _isLoading = true;
  String _dosenId = '';

  String _selectedHari = 'Senin';
  List<Map<String, dynamic>> _jadwalList = [];
  Map<String, dynamic> _kelasById = {};

  @override
  void initState() {
    super.initState();
    // Default selected hari based on current day if possible
    final weekday = DateTime.now().weekday;
    if (weekday >= 1 && weekday <= 6) {
      _selectedHari = _hariEnum[weekday - 1];
    }
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      // 1. Profil dosen -> dosen_id
      if (_dosenId.isEmpty) {
        final profil = await ApiClient.get(ApiConfig.getDosen);
        if (profil['status'] == 'ok') {
          final data = profil['data'] as Map<String, dynamic>;
          _dosenId = data['id']?.toString() ?? '';
        }
      }

      // 2. Load Kelas untuk mendapatkan jumlah mahasiswa
      if (_kelasById.isEmpty && _dosenId.isNotEmpty) {
        final kelasRes = await ApiClient.get(
          ApiConfig.getKelas,
          queryParams: {'dosen_id': _dosenId},
        );
        if (kelasRes['status'] == 'ok') {
          final List kelasList = kelasRes['data'] as List? ?? [];
          for (final k in kelasList) {
            final map = k as Map<String, dynamic>;
            _kelasById[map['id'].toString()] = map;
          }
        }
      }

      // 3. Load Jadwal berdasarkan hari terpilih
      final jadwalRes = await ApiClient.get(
        ApiConfig.getJadwal,
        queryParams: {'hari': _selectedHari},
      );
      if (jadwalRes['status'] == 'ok') {
        final List jadwalData = jadwalRes['data'] as List? ?? [];
        _jadwalList =
            jadwalData.map((j) {
              final map = Map<String, dynamic>.from(j as Map<String, dynamic>);
              final kelas = _kelasById[map['kelas_id']?.toString()];
              map['jumlah_mahasiswa'] = kelas?['jumlah_terisi'];
              return map;
            }).toList()..sort(
              (a, b) => (a['jam_mulai'] ?? '').toString().compareTo(
                (b['jam_mulai'] ?? '').toString(),
              ),
            );
      } else {
        _jadwalList = [];
      }
    } catch (_) {
      _jadwalList = [];
    }

    if (mounted) setState(() => _isLoading = false);
  }

  void _onHariSelected(String hari) {
    if (_selectedHari == hari) return;
    setState(() {
      _selectedHari = hari;
    });
    _loadData();
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

  void _handlePlaceholder(String fitur) {
    AppToast.show(context, '$fitur akan segera hadir', isError: false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: Container(
        decoration: BoxDecoration(gradient: AppColorsSoft.backgroundGradient),
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              CustomTopBar(
                title: 'Jadwal Mengajar',
                nama: widget.nama,
                onBack: () => Navigator.popUntil(context, (route) => route.isFirst),
              ),
              _buildDaySelector(),
              Expanded(
                child: RefreshIndicator(
                  color: AppColorsSoft.navy,
                  onRefresh: _loadData,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 110),
                    children: [
                      _buildJadwalList(),
                      const SizedBox(height: 20),
                      _buildInfoTerkini(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: DosenNavHelper.buildNav(
        context: context,
        currentIndex: _navIndex,
        onLogout: _logout,
        onBerandaTap: () {
          Navigator.popUntil(context, (route) => route.isFirst);
        },
        onJadwalTap: () {},
        onNilaiTap: () {
          Navigator.pushReplacement(
            context,
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) => DosenInputNilaiPage(
                userId: widget.userId,
                nama: widget.nama,
                username: widget.username,
              ),
              transitionDuration: Duration.zero,
              reverseTransitionDuration: Duration.zero,
            ),
          );
        },
        onProfilTap: () {
          Navigator.pushReplacement(
            context,
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) => DosenProfilPage(
                userId: widget.userId,
                nama: widget.nama,
                username: widget.username,
              ),
              transitionDuration: Duration.zero,
              reverseTransitionDuration: Duration.zero,
            ),
          );
        },
      ),
    );
  }


  Widget _buildDaySelector() {
    return SizedBox(
      height: 48,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _hariEnum.length,
        itemBuilder: (context, index) {
          final hari = _hariEnum[index];
          final isSelected = _selectedHari == hari;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: ChoiceChip(
              label: Text(hari),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) _onHariSelected(hari);
              },
              backgroundColor: Colors.white,
              selectedColor: AppColorsSoft.navy,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : AppColorsSoft.navy,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
              ),
              showCheckmark: false,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
                side: BorderSide(
                  color: isSelected ? AppColorsSoft.navy : Colors.transparent,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildJadwalList() {
    if (_isLoading) {
      return Container(
        padding: const EdgeInsets.all(40),
        child: const Center(
          child: CircularProgressIndicator(color: AppColorsSoft.navy),
        ),
      );
    }

    if (_jadwalList.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(40),
        decoration: AppColorsSoft.card(),
        child: const Center(
          child: Text(
            'Tidak ada jadwal mengajar di hari ini',
            style: TextStyle(color: AppColorsSoft.textGray, fontSize: 14),
          ),
        ),
      );
    }

    return Column(
      children: _jadwalList.map((j) {
        final jamMulai = (j['jam_mulai'] ?? '').toString();
        final jamSelesai = (j['jam_selesai'] ?? '').toString();
        final waktuStr = '$jamMulai - $jamSelesai';
        
        final namaMk = j['nama_mk']?.toString() ?? '-';
        final namaKelas = j['nama_kelas']?.toString() ?? '-';
        final namaRuang = j['nama_ruang']?.toString() ?? '-';
        final jumlahMhs = j['jumlah_mahasiswa']?.toString() ?? '0';

        // Mocking Course Type for UI based on course name
        final isPraktikum = namaMk.toLowerCase().contains('praktikum') || namaMk.toLowerCase().contains('lab');
        final typeLabel = isPraktikum ? 'PRAKTIKUM' : 'TEORI';
        final typeBg = isPraktikum ? const Color(0xFFFDE2E4) : const Color(0xFFE8E4F3);
        final typeColor = isPraktikum ? const Color(0xFFC62828) : const Color(0xFF512DA8);

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(20),
          decoration: AppColorsSoft.card(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Row 1: Time and Type
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    waktuStr,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColorsSoft.textGray,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: typeBg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      typeLabel,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: typeColor,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              // Row 2: Course Name
              Text(
                namaMk,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColorsSoft.navy,
                ),
              ),
              const SizedBox(height: 16),

              // Row 3: Class and Room
              Row(
                children: [
                  _buildSmallChip(Icons.groups_rounded, 'Kelas: $namaKelas'),
                  const SizedBox(width: 12),
                  _buildSmallChip(Icons.door_front_door_outlined, 'R. $namaRuang'),
                ],
              ),
              const SizedBox(height: 12),

              // Row 4: Student Count
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFE8D6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.person_rounded,
                      size: 14,
                      color: Color(0xFFB5651D),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '$jumlahMhs Mahasiswa',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFB5651D),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSmallChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColorsSoft.fieldFill,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColorsSoft.textGray),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColorsSoft.textGray,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTerkini() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColorsSoft.navy,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppColorsSoft.navy.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Informasi Terkini',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Ujian Tengah Semester dimulai dalam 4 hari.',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => _handlePlaceholder('Detail Informasi'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppColorsSoft.navy,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              minimumSize: const Size(0, 0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: const Text(
              'Lihat Detail',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
