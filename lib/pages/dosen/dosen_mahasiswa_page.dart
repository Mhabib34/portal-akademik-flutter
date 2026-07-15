import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../config/api_config.dart';
import '../../services/api_client.dart';
import '../../services/auth_service.dart';
import '../../widgets/dosen_nav_helper.dart';
import '../../widgets/logout_dialog.dart';
import '../auth/login_page.dart';
import 'dosen_profil_page.dart';
import 'dosen_jadwal_page.dart';
import 'dosen_input_nilai_page.dart';
import 'dosen_mahasiswa_detail_page.dart';
import '../../widgets/custom_top_bar.dart';
import '../../utils/app_toast.dart';

// ============================================================
// dosen_mahasiswa_page.dart — Halaman Daftar Mahasiswa Dosen
// ============================================================

class DosenMahasiswaPage extends StatefulWidget {
  final String userId;
  final String nama;
  final String username;

  const DosenMahasiswaPage({
    super.key,
    required this.userId,
    required this.nama,
    required this.username,
  });

  @override
  State<DosenMahasiswaPage> createState() => _DosenMahasiswaPageState();
}

class _DosenMahasiswaPageState extends State<DosenMahasiswaPage> {
  final int _navIndex = -1; // Standalone page, no active tab highlight
  bool _isLoading = true;
  String _dosenId = '';

  List<Map<String, dynamic>> _kelasList = [];
  String? _selectedKelasId;
  String _selectedKelasName = '';

  List<Map<String, dynamic>> _mahasiswaList = [];
  List<Map<String, dynamic>> _filteredMahasiswaList = [];
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
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

      // 2. Load Kelas untuk Filter
      if (_dosenId.isNotEmpty) {
        final kelasRes = await ApiClient.get(
          ApiConfig.getKelas,
          queryParams: {'dosen_id': _dosenId},
        );
        if (kelasRes['status'] == 'ok') {
          final List kList = kelasRes['data'] as List? ?? [];
          _kelasList = kList.map((k) => Map<String, dynamic>.from(k as Map)).toList();
          
          if (_kelasList.isNotEmpty) {
            _selectedKelasId = _kelasList.first['id']?.toString();
            _selectedKelasName = '${_kelasList.first['nama_mk']} ${_kelasList.first['nama_kelas']}';
          }
        }
      }

      if (_selectedKelasId != null) {
        await _loadMahasiswa();
      }
    } catch (_) {
      // ignore
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadMahasiswa() async {
    if (_selectedKelasId == null) return;
    
    setState(() => _isLoading = true);
    try {
      final res = await ApiClient.get(
        ApiConfig.getNilai,
        queryParams: {'kelas_id': _selectedKelasId!},
      );
      if (res['status'] == 'ok') {
        final List mList = res['data'] as List? ?? [];
        _mahasiswaList = mList.map((m) => Map<String, dynamic>.from(m as Map)).toList();
        _applySearch();
      } else {
        _mahasiswaList = [];
        _filteredMahasiswaList = [];
      }
    } catch (_) {
      _mahasiswaList = [];
      _filteredMahasiswaList = [];
    }
    
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  void _onKelasChanged(String? kelasId) {
    if (kelasId == null || kelasId == _selectedKelasId) return;
    
    final selectedKelas = _kelasList.firstWhere((k) => k['id'].toString() == kelasId);
    setState(() {
      _selectedKelasId = kelasId;
      _selectedKelasName = '${selectedKelas['nama_mk']} ${selectedKelas['nama_kelas']}';
      // reset search
      _searchQuery = '';
    });
    
    _loadMahasiswa();
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
      _applySearch();
    });
  }

  void _applySearch() {
    if (_searchQuery.isEmpty) {
      _filteredMahasiswaList = List.from(_mahasiswaList);
      return;
    }
    
    final q = _searchQuery.toLowerCase();
    _filteredMahasiswaList = _mahasiswaList.where((m) {
      final nama = (m['nama_mahasiswa'] ?? '').toString().toLowerCase();
      final nim = (m['nim'] ?? '').toString().toLowerCase();
      return nama.contains(q) || nim.contains(q);
    }).toList();
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
                title: _selectedKelasName.isNotEmpty ? 'Daftar Mahasiswa – $_selectedKelasName' : 'Daftar Mahasiswa',
                nama: widget.nama,
                onBack: () => Navigator.pop(context), // this is a sub-page accessed from home
              ),
              _buildFilterAndSearch(),
              const SizedBox(height: 12),
              Expanded(
                child: RefreshIndicator(
                  color: AppColorsSoft.navy,
                  onRefresh: _loadMahasiswa,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 110),
                    children: [
                      _buildHeaderInfo(),
                      const SizedBox(height: 16),
                      _buildMahasiswaList(),
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
        onJadwalTap: () {
          Navigator.pushReplacement(
            context,
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) => DosenJadwalPage(
                userId: widget.userId,
                nama: widget.nama,
                username: widget.username,
              ),
              transitionDuration: Duration.zero,
              reverseTransitionDuration: Duration.zero,
            ),
          );
        },
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


  Widget _buildFilterAndSearch() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          // Class Dropdown
          if (_kelasList.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColorsSoft.navy.withOpacity(0.1)),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedKelasId,
                  isExpanded: true,
                  icon: const Icon(Icons.arrow_drop_down_rounded, color: AppColorsSoft.navy),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColorsSoft.navy,
                  ),
                  onChanged: _onKelasChanged,
                  items: _kelasList.map((k) {
                    final label = '${k['nama_mk']} - Kelas ${k['nama_kelas']}';
                    return DropdownMenuItem<String>(
                      value: k['id']?.toString(),
                      child: Text(label, overflow: TextOverflow.ellipsis),
                    );
                  }).toList(),
                ),
              ),
            ),
            
          // Search Bar
          TextField(
            onChanged: _onSearchChanged,
            decoration: InputDecoration(
              hintText: 'Cari nama atau NIM...',
              hintStyle: const TextStyle(color: AppColorsSoft.textGrayLight, fontSize: 14),
              prefixIcon: const Icon(Icons.search_rounded, color: AppColorsSoft.textGrayLight, size: 20),
              filled: true,
              fillColor: AppColorsSoft.fieldFill.withOpacity(0.8),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderInfo() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Peserta Kelas',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColorsSoft.navy,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFFFE8D6),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '${_filteredMahasiswaList.length} Mahasiswa',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Color(0xFFB5651D),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMahasiswaList() {
    if (_isLoading) {
      return Container(
        padding: const EdgeInsets.all(40),
        child: const Center(
          child: CircularProgressIndicator(color: AppColorsSoft.navy),
        ),
      );
    }

    if (_kelasList.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: AppColorsSoft.card(),
        child: const Center(
          child: Text(
            'Belum ada kelas yang diampu.',
            style: TextStyle(color: AppColorsSoft.textGray, fontSize: 14),
          ),
        ),
      );
    }

    if (_filteredMahasiswaList.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: AppColorsSoft.card(),
        child: const Center(
          child: Text(
            'Tidak ada mahasiswa ditemukan.',
            style: TextStyle(color: AppColorsSoft.textGray, fontSize: 14),
          ),
        ),
      );
    }

    return Column(
      children: _filteredMahasiswaList.map((m) {
        final nama = m['nama_mahasiswa']?.toString() ?? '-';
        final nim = m['nim']?.toString() ?? '-';
        final prodi = m['nama_prodi']?.toString() ?? 'Informatika'; // Default if empty
        
        // Generate Avatar Initials
        final names = nama.split(' ');
        String initials = '';
        if (names.isNotEmpty) initials += names[0][0].toUpperCase();
        if (names.length > 1) initials += names[1][0].toUpperCase();

        // Consistent Avatar Color based on NIM length/value or name
        final colorIndex = nama.length % 5;
        final avatarColors = [
          const Color(0xFF1A1A2E), // Dark Navy
          const Color(0xFF512DA8), // Deep Purple
          const Color(0xFFF57C00), // Orange
          const Color(0xFFB39DDB), // Light Purple
          const Color(0xFF90CAF9), // Light Blue
        ];
        final avatarBg = avatarColors[colorIndex];
        final avatarText = colorIndex == 4 ? AppColorsSoft.navy : Colors.white; // dark text for light bg

        return InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => DosenMahasiswaDetailPage(
                  mahasiswaData: m,
                  dosenNama: widget.nama,
                ),
              ),
            );
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: AppColorsSoft.card(),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: avatarBg,
                  child: Text(
                    initials,
                    style: TextStyle(
                      color: avatarText,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        nama,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppColorsSoft.navy,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(
                            Icons.badge_outlined,
                            size: 13,
                            color: AppColorsSoft.textGrayLight,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            nim,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColorsSoft.textGrayLight,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        prodi.isEmpty ? 'Informatika' : prodi,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFB5651D),
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
    );
  }
}
