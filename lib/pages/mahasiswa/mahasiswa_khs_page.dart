import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../theme/app_theme.dart';
import '../../config/api_config.dart';
import '../../services/api_client.dart';
import '../../widgets/mahasiswa_nav_helper.dart';
import '../../widgets/ajukan_krs_bottom_sheet.dart';
import '../../utils/app_toast.dart';

class MahasiswaKhsPage extends StatefulWidget {
  final String userId;
  final String nama;
  final String username;
  final String nim;

  const MahasiswaKhsPage({
    super.key,
    required this.userId,
    required this.nama,
    required this.username,
    required this.nim,
  });

  @override
  State<MahasiswaKhsPage> createState() => _MahasiswaKhsPageState();
}

class _MahasiswaKhsPageState extends State<MahasiswaKhsPage> {
  bool _isLoading = true;
  String? _selectedTahunAjaranId;
  List<Map<String, dynamic>> _listTahunAjaran = [];
  Map<String, dynamic>? _khsData;

  @override
  void initState() {
    super.initState();
    _loadTahunAjaran();
  }

  Future<void> _loadTahunAjaran() async {
    try {
      final res = await ApiClient.get(ApiConfig.getTahunAjaran);
      if (res['status'] == 'ok') {
        final List list = res['data'] as List? ?? [];
        _listTahunAjaran = list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        
        if (_listTahunAjaran.isNotEmpty) {
          // Pilih yang aktif, atau default yang pertama
          final aktif = _listTahunAjaran.firstWhere(
            (e) => int.tryParse(e['is_aktif']?.toString() ?? '0') == 1, 
            orElse: () => _listTahunAjaran.first
          );
          _selectedTahunAjaranId = aktif['id']?.toString();
        }
      }
    } catch (e) {
      _showSnackBar('Gagal memuat daftar semester', isError: true);
    }

    if (_selectedTahunAjaranId != null) {
      await _loadKhs();
    } else {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadKhs() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final res = await ApiClient.get(ApiConfig.getKhs, queryParams: {
        'tahun_ajaran_id': _selectedTahunAjaranId ?? '',
      });
      if (res['status'] == 'ok') {
        _khsData = res['data'] != null ? Map<String, dynamic>.from(res['data']) : null;
      } else {
        _khsData = null;
      }
    } catch (e) {
      _khsData = null;
      _showSnackBar('Gagal memuat data KHS', isError: true);
    }

    if (mounted) setState(() => _isLoading = false);
  }

  void _showSnackBar(String msg, {bool isError = false}) {
    AppToast.show(context, msg, isError: isError);
  }

  Future<void> _cetakKhs() async {
    if (_khsData == null) {
      _showSnackBar('Tidak ada data KHS untuk dicetak', isError: true);
      return;
    }

    try {
      final doc = pw.Document();

      final List mkList = _khsData?['mata_kuliah'] as List? ?? [];
      final tahunAjaranStr = _khsData?['tahun_ajaran'] ?? '-';
      final ipSemester = (_khsData?['ip_semester'] ?? 0).toString();
      final totalSksSemester = (_khsData?['total_sks_semester'] ?? 0).toString();
      final ipkKumulatif = (_khsData?['ipk_kumulatif'] ?? 0).toString();
      final totalSksKumulatif = (_khsData?['total_sks_kumulatif'] ?? 0).toString();

      doc.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (pw.Context context) {
            return [
              pw.Center(
                child: pw.Text(
                  'KARTU HASIL STUDI (KHS)',
                  style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
                ),
              ),
              pw.SizedBox(height: 20),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Nama: ${widget.nama}'),
                      pw.Text('NIM: ${widget.nim}'),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('Tahun Ajaran: $tahunAjaranStr'),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 20),
              pw.Table.fromTextArray(
                headers: ['No', 'Mata Kuliah', 'SKS', 'Nilai Huruf', 'Nilai Angka'],
                data: List<List<String>>.generate(
                  mkList.length,
                  (index) {
                    final mk = mkList[index];
                    return [
                      '${index + 1}',
                      mk['nama_mk']?.toString() ?? '-',
                      mk['sks']?.toString() ?? '0',
                      mk['nilai_huruf']?.toString() ?? '-',
                      (mk['nilai_angka'] ?? 0).toString(),
                    ];
                  },
                ),
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                cellAlignment: pw.Alignment.center,
              ),
              pw.SizedBox(height: 20),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('IP Semester: $ipSemester', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.Text('SKS Semester: $totalSksSemester'),
                      pw.SizedBox(height: 10),
                      pw.Text('IPK Kumulatif: $ipkKumulatif', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.Text('Total SKS: $totalSksKumulatif'),
                    ],
                  ),
                ],
              ),
            ];
          },
        ),
      );

      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => doc.save(),
        name: 'KHS_${widget.nim}_$tahunAjaranStr.pdf',
      );
    } catch (e) {
      _showSnackBar('Terjadi kesalahan saat membuat PDF', isError: true);
    }
  }

  Color _getGradeColor(String grade) {
    if (grade.startsWith('A')) return const Color(0xFFFFDAB9); // Light peach like the design
    if (grade.startsWith('B')) return const Color(0xFFE2EFFB);
    if (grade.startsWith('C')) return const Color(0xFFFFF4D9);
    if (grade.startsWith('D')) return const Color(0xFFFFEAD9);
    return const Color(0xFFFFD9D9);
  }

  Color _getGradeTextColor(String grade) {
    if (grade.startsWith('A')) return const Color(0xFFD35500); // Darker orange/brown
    if (grade.startsWith('B')) return const Color(0xFF2E6FE0);
    if (grade.startsWith('C')) return const Color(0xFFD38B00);
    if (grade.startsWith('D')) return const Color(0xFFD35500);
    return const Color(0xFFE05252);
  }

  IconData _getIconForSubject(int index) {
    // Memberikan variasi icon berdasarkan index
    final icons = [
      Icons.code_rounded,
      Icons.storage_rounded,
      Icons.psychology_rounded,
      Icons.security_rounded,
      Icons.design_services_rounded,
    ];
    return icons[index % icons.length];
  }

  Color _getIconBgColorForSubject(int index) {
    final colors = [
      const Color(0xFFFFE8CC), // Peach
      const Color(0xFFE2E8FF), // Light Blue
      const Color(0xFFF3E8FF), // Light Purple
      const Color(0xFFF1F5F9), // Light Grey
    ];
    return colors[index % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    final totalSks = (_khsData?['total_sks_semester'] ?? 0).toString();
    final ipSemester = (_khsData?['ip_semester'] ?? 0.0).toStringAsFixed(2);
    final ipkKumulatif = (_khsData?['ipk_kumulatif'] ?? 0.0).toStringAsFixed(2);
    final semesterName = _khsData?['tahun_ajaran'] ?? '-';
    
    final mkList = (_khsData?['mata_kuliah'] as List?) ?? [];

    return Scaffold(
      backgroundColor: const Color(0xFFEEF2FA), // Warna background biru muda sesuai desain
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildTopBar(),
            const SizedBox(height: 16),
            if (_listTahunAjaran.isNotEmpty) _buildSemesterChips(),
            const SizedBox(height: 20),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppColorsSoft.navy))
                  : ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10).copyWith(bottom: 120),
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        _buildStatusAkademikCard(semesterName, totalSks, ipSemester, ipkKumulatif),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Detail Nilai',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppColorsSoft.navy,
                              ),
                            ),
                            Text(
                              '${mkList.length} Matakuliah',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColorsSoft.textGray,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        ...mkList.asMap().entries.map((entry) => _buildMataKuliahItem(entry.value, entry.key)).toList(),
                        if (mkList.isEmpty)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.all(32.0),
                              child: Text('Belum ada nilai KHS di semester ini', style: TextStyle(color: AppColorsSoft.textGray)),
                            ),
                          )
                      ],
                    ),
            ),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: FloatingActionButton.extended(
          onPressed: _cetakKhs,
          backgroundColor: const Color(0xFF1B1A30), // Warna tombol dark sesuai gambar
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          icon: const Icon(Icons.download_rounded, color: Colors.white, size: 20),
          label: const Text(
            'Cetak KHS',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ),
      ),
      // Di gambar Bottom Nav Grades (index 2) menyala, tapi halaman ini diakses dari Dashboard
      // Kita set index 2 agar sesuai design jika memang ini menggantikan / setara dengan Nilai.
      bottomNavigationBar: MahasiswaNavHelper.buildNav(
        context: context,
        currentIndex: 2, 
        userId: widget.userId,
        nama: widget.nama,
        username: widget.username,
        nim: widget.nim,
        centerActionOnTap: () => AjukanKrsBottomSheet.show(context, onSuccess: _loadTahunAjaran),
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
              'Portal Akademik',
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

  Widget _buildSemesterChips() {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        itemCount: _listTahunAjaran.length,
        separatorBuilder: (context, index) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final ta = _listTahunAjaran[index];
          final id = ta['id']?.toString();
          // Singkat nama: "Semester Ganjil 2024" -> "Smt 1 2024"
          String semesterShort = ta['semester'] == 'Ganjil' ? 'Smt 1' : 'Smt 2';
          // Kalau format namanya misal "2024/2025", ambil tahun pertama
          String tahunShort = ta['nama']?.toString().split('/').first ?? ta['nama'] ?? '';
          final label = '$semesterShort $tahunShort';
          final isSelected = id == _selectedTahunAjaranId;

          return GestureDetector(
            onTap: () {
              if (!isSelected && id != null) {
                setState(() {
                  _selectedTahunAjaranId = id;
                });
                _loadKhs();
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
                label,
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

  Widget _buildStatusAkademikCard(String semesterName, String totalSks, String ipSemester, String ipkKumulatif) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: 20,
            right: 20,
            width: 80,
            height: 60,
            child: Opacity(
              opacity: 0.9,
              child: Image.asset(
                'assets/images/diploma.png',
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(Icons.school, size: 60, color: Colors.grey.withOpacity(0.2));
                },
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Status Akademik',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColorsSoft.textGray,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  semesterName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColorsSoft.navy,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFCFCFC), // abu-abu sangat muda
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Total SKS',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColorsSoft.textGray,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '$totalSks SKS',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: AppColorsSoft.navy,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFCFCFC),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'IP Semester',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColorsSoft.textGray,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              ipSemester,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: AppColorsSoft.navy,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFCFCFC),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'IP Kumulatif (IPK)',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColorsSoft.textGray,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            ipkKumulatif,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: AppColorsSoft.navy,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFBE4CD),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.military_tech_rounded,
                          color: Color(0xFFB96C17), // Warna perunggu/emas tua
                          size: 28,
                        ),
                      )
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMataKuliahItem(Map mk, int index) {
    final grade = mk['nilai_huruf']?.toString() ?? '-';
    final gradeScore = (mk['nilai_angka'] ?? 0.0).toStringAsFixed(1);
    final namaMk = mk['nama_mk']?.toString() ?? '-';
    final sks = mk['sks']?.toString() ?? '0';
    final kodeMk = mk['kode_mk']?.toString() ?? 'IF-XXX'; // default jika tidak ada kode mk 

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: AppColorsSoft.card().copyWith(
        color: Colors.white,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _getIconBgColorForSubject(index),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              _getIconForSubject(index),
              color: AppColorsSoft.navy,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  namaMk,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColorsSoft.navy,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$sks SKS • Kode: $kodeMk',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColorsSoft.textGray,
                  ),
                ),
              ],
            ),
          ),
          Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _getGradeColor(grade),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  grade,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: _getGradeTextColor(grade),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                gradeScore,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColorsSoft.textGray,
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
}
