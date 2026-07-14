import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../config/api_config.dart';
import '../../services/api_client.dart';
import '../../widgets/mahasiswa_nav_helper.dart';
import '../../widgets/ajukan_krs_bottom_sheet.dart';
import '../../utils/app_toast.dart';

class MahasiswaJadwalPage extends StatefulWidget {
  final String userId;
  final String nama;
  final String username;
  final String nim;

  const MahasiswaJadwalPage({
    super.key,
    required this.userId,
    required this.nama,
    required this.username,
    required this.nim,
  });

  @override
  State<MahasiswaJadwalPage> createState() => _MahasiswaJadwalPageState();
}

class _MahasiswaJadwalPageState extends State<MahasiswaJadwalPage> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _listJadwal = [];
  
  final List<String> _hariList = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu'];
  late String _selectedHari;

  @override
  void initState() {
    super.initState();
    _determineInitialDay();
    _fetchJadwal();
  }

  void _determineInitialDay() {
    int weekday = DateTime.now().weekday; // 1 = Senin, 7 = Minggu
    if (weekday >= 1 && weekday <= 6) {
      _selectedHari = _hariList[weekday - 1];
    } else {
      _selectedHari = 'Senin'; // Kalau minggu, default ke Senin
    }
  }

  Future<void> _fetchJadwal() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final res = await ApiClient.get(ApiConfig.getJadwal, queryParams: {
        'hari': _selectedHari,
      });

      if (res['status'] == 'ok') {
        final List list = res['data'] as List? ?? [];
        _listJadwal = list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      } else {
        _listJadwal = [];
      }
    } catch (e) {
      _listJadwal = [];
      _showSnackBar('Gagal memuat jadwal perkuliahan', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String msg, {bool isError = false}) {
    AppToast.show(context, msg, isError: isError);
  }

  Color _getCardColorForIndex(int index) {
    final colors = [
      const Color(0xFFFFE8CC), // Light peach
      const Color(0xFFE2E8FF), // Light Blue
      const Color(0xFFF3E8FF), // Light Purple
      const Color(0xFFE2F6EA), // Light Green
    ];
    return colors[index % colors.length];
  }

  Color _getAccentColorForIndex(int index) {
    final colors = [
      const Color(0xFFD35500), // Orange/Brown
      const Color(0xFF2E6FE0), // Blue
      const Color(0xFF8B5CF6), // Purple
      const Color(0xFF12A150), // Green
    ];
    return colors[index % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEEF2FA), // Background tema
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildTopBar(),
            const SizedBox(height: 16),
            _buildHariChips(),
            const SizedBox(height: 16),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppColorsSoft.navy))
                  : _buildTimelineList(),
            ),
          ],
        ),
      ),
      bottomNavigationBar: MahasiswaNavHelper.buildNav(
        context: context,
        currentIndex: 1, // 1 = Jadwal
        userId: widget.userId,
        nama: widget.nama,
        username: widget.username,
        nim: widget.nim,
        centerActionOnTap: () => AjukanKrsBottomSheet.show(context, onSuccess: _fetchJadwal),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          CircleAvatar(
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
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Jadwal Kuliah',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColorsSoft.navy,
              ),
            ),
          ),
          IconButton(
            onPressed: () => _showSnackBar('Notifikasi segera hadir'),
            icon: const Icon(
              Icons.notifications_none_rounded,
              color: AppColorsSoft.navy,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHariChips() {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        itemCount: _hariList.length,
        separatorBuilder: (context, index) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final hari = _hariList[index];
          final isSelected = hari == _selectedHari;

          return GestureDetector(
            onTap: () {
              if (!isSelected) {
                setState(() {
                  _selectedHari = hari;
                });
                _fetchJadwal();
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF1B1A30) : Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                hari,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : AppColorsSoft.textGray,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTimelineList() {
    if (_listJadwal.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy_rounded, size: 60, color: AppColorsSoft.textGray.withOpacity(0.5)),
            const SizedBox(height: 16),
            Text('Tidak ada jadwal di hari $_selectedHari', style: const TextStyle(color: AppColorsSoft.textGray)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20).copyWith(bottom: 20),
      itemCount: _listJadwal.length,
      itemBuilder: (context, index) {
        final j = _listJadwal[index];
        final bool isLast = index == _listJadwal.length - 1;
        
        final jamMulai = j['jam_mulai'] ?? '-';
        final jamSelesai = j['jam_selesai'] ?? '-';
        final namaMk = j['nama_mk'] ?? '-';
        final dosen = j['dosen'] ?? '-';
        final ruang = j['nama_ruang'] ?? '-';
        final kelas = j['nama_kelas'] ?? '-';
        
        final bgColor = _getCardColorForIndex(index);
        final accentColor = _getAccentColorForIndex(index);

        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Waktu di sebelah kiri
              SizedBox(
                width: 50,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const SizedBox(height: 16),
                    Text(
                      jamMulai.toString().padRight(5, '0'), // Handle if it's '8:0' 
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppColorsSoft.navy,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      jamSelesai.toString().padRight(5, '0'),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColorsSoft.textGray,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              
              // Garis Timeline
              Column(
                children: [
                  const SizedBox(height: 18),
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: accentColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: bgColor, width: 3),
                    ),
                  ),
                  if (!isLast)
                    Expanded(
                      child: Container(
                        width: 2,
                        color: AppColorsSoft.textGray.withOpacity(0.2),
                      ),
                    )
                  else 
                    const Expanded(child: SizedBox()),
                ],
              ),
              const SizedBox(width: 16),
              
              // Card Jadwal
              Expanded(
                child: Container(
                  margin: const EdgeInsets.only(bottom: 24),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.02),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.6),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.meeting_room_rounded, size: 12, color: accentColor),
                                const SizedBox(width: 4),
                                Text(
                                  ruang.toString(),
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: accentColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Kelas $kelas',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColorsSoft.navy.withOpacity(0.7),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        namaMk.toString(),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppColorsSoft.navy,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.person, size: 14, color: AppColorsSoft.navy.withOpacity(0.5)),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              dosen.toString(),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColorsSoft.navy.withOpacity(0.6),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
