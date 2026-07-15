import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../theme/app_theme.dart';
import '../../config/api_config.dart';
import '../../services/api_client.dart';
import '../../widgets/mahasiswa_nav_helper.dart';
import '../../widgets/ajukan_krs_bottom_sheet.dart';
import '../../widgets/custom_top_bar.dart';
import '../../utils/app_toast.dart';

class MahasiswaNilaiPage extends StatefulWidget {
  final String userId;
  final String nama;
  final String username;
  final String nim;

  const MahasiswaNilaiPage({
    super.key,
    required this.userId,
    required this.nama,
    required this.username,
    required this.nim,
  });

  @override
  State<MahasiswaNilaiPage> createState() => _MahasiswaNilaiPageState();
}

class _MahasiswaNilaiPageState extends State<MahasiswaNilaiPage> {
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
          // Cari yang aktif
          final aktif = _listTahunAjaran.firstWhere((e) => int.tryParse(e['is_aktif']?.toString() ?? '0') == 1, orElse: () => _listTahunAjaran.first);
          _selectedTahunAjaranId = aktif['id']?.toString();
        }
      }
    } catch (e) {
      _showSnackBar('Gagal memuat tahun ajaran', isError: true);
    }

    if (_selectedTahunAjaranId != null) {
      await _loadKhs();
    } else {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadKhs() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

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

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
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
    if (grade.startsWith('A')) return const Color(0xFFE2F6EA);
    if (grade.startsWith('B')) return const Color(0xFFE2EFFB);
    if (grade.startsWith('C')) return const Color(0xFFFFF4D9);
    if (grade.startsWith('D')) return const Color(0xFFFFEAD9);
    return const Color(0xFFFFD9D9); // E
  }

  Color _getGradeTextColor(String grade) {
    if (grade.startsWith('A')) return const Color(0xFF12A150);
    if (grade.startsWith('B')) return const Color(0xFF2E6FE0);
    if (grade.startsWith('C')) return const Color(0xFFD38B00);
    if (grade.startsWith('D')) return const Color(0xFFD35500);
    return const Color(0xFFE05252); // E
  }

  @override
  Widget build(BuildContext context) {
    final ipkTotal = (_khsData?['ipk_kumulatif'] ?? 0.0).toStringAsFixed(2);
    final sksLulus = (_khsData?['total_sks_kumulatif'] ?? 0).toString();
    final ipkVal = double.tryParse(ipkTotal) ?? 0.0;
    String predikat = 'MEMUASKAN';
    if (ipkVal >= 3.5) predikat = 'CUMLAUDE';
    else if (ipkVal >= 3.0) predikat = 'SANGAT MEMUASKAN';

    final mkList = (_khsData?['mata_kuliah'] as List?) ?? [];

    return Scaffold(
      extendBody: true,
      body: Container(
        decoration: BoxDecoration(gradient: AppColorsSoft.backgroundGradient),
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              CustomTopBar(
                title: 'Nilai Mata Kuliah',
                nama: widget.nama,
                onBack: () => Navigator.popUntil(context, (route) => route.isFirst),
              ),
              if (_listTahunAjaran.isNotEmpty) _buildSemesterDropdown(),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator(color: AppColorsSoft.navy))
                    : ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(20, 10, 20, 160),
                        children: [
                          _buildStatCard(ipkTotal, sksLulus, predikat, ipkVal),
                          const SizedBox(height: 24),
                          ...mkList.map((mk) => _buildMataKuliahItem(mk)).toList(),
                          if (mkList.isEmpty)
                            const Center(
                              child: Padding(
                                padding: EdgeInsets.all(32.0),
                                child: Text('Belum ada nilai di semester ini', style: TextStyle(color: AppColorsSoft.textGray)),
                              ),
                            )
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: MahasiswaNavHelper.buildNav(
        context: context,
        currentIndex: 2, // 2 = Nilai
        userId: widget.userId,
        nama: widget.nama,
        username: widget.username,
        nim: widget.nim,
        centerActionOnTap: () => AjukanKrsBottomSheet.show(context),
      ),
    );
  }


  Widget _buildSemesterDropdown() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedTahunAjaranId,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColorsSoft.textGray),
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColorsSoft.navy,
          ),
          onChanged: (val) {
            if (val != null && val != _selectedTahunAjaranId) {
              setState(() {
                _selectedTahunAjaranId = val;
              });
              _loadKhs();
            }
          },
          items: _listTahunAjaran.map((ta) {
            final label = '${ta['semester']} ${ta['nama']}';
            return DropdownMenuItem<String>(
              value: ta['id']?.toString(),
              child: Text(label),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildStatCard(String ipkTotal, String sksLulus, String predikat, double ipkVal) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: AppColorsSoft.card(),
      child: Stack(
        children: [
          Positioned(
            top: -10,
            right: -10,
            child: Icon(
              Icons.school_outlined,
              size: 80,
              color: AppColorsSoft.navy.withOpacity(0.05),
            ),
          ),
          Column(
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 140,
                    height: 140,
                    child: CircularProgressIndicator(
                      value: ipkVal / 4.0,
                      strokeWidth: 10,
                      backgroundColor: AppColorsSoft.fieldFill,
                      color: AppColorsSoft.navy,
                      strokeCap: StrokeCap.round,
                    ),
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        ipkTotal,
                        style: const TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.w800,
                          color: AppColorsSoft.navy,
                        ),
                      ),
                      const Text(
                        'IPK Total',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColorsSoft.textGray,
                        ),
                      ),
                    ],
                  )
                ],
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          sksLulus,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColorsSoft.navy,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'SKS LULUS',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColorsSoft.textGray,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(width: 1, height: 40, color: AppColorsSoft.fieldFill),
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          _getGradeByIpk(ipkVal),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColorsSoft.navy,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'PREDIKAT',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColorsSoft.textGray,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              )
            ],
          ),
        ],
      ),
    );
  }

  String _getGradeByIpk(double ipk) {
    if (ipk >= 3.5) return 'A';
    if (ipk >= 3.0) return 'B';
    if (ipk >= 2.0) return 'C';
    if (ipk >= 1.0) return 'D';
    return 'E';
  }

  Widget _buildMataKuliahItem(Map mk) {
    final grade = mk['nilai_huruf']?.toString() ?? '-';
    final namaMk = mk['nama_mk']?.toString() ?? '-';
    final sks = mk['sks']?.toString() ?? '0';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: AppColorsSoft.card(),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColorsSoft.fieldFill,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.class_outlined,
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
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColorsSoft.navy,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$sks SKS • MK Wajib', // Asumsi MK Wajib krn tidak ada field tipe mk
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: AppColorsSoft.textGray,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _getGradeColor(grade),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                grade,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: _getGradeTextColor(grade),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}
