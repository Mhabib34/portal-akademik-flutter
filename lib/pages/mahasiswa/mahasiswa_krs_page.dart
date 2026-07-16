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

class MahasiswaKrsPage extends StatefulWidget {
  final String userId;
  final String nama;
  final String username;
  final String nim;

  const MahasiswaKrsPage({
    super.key,
    required this.userId,
    required this.nama,
    required this.username,
    required this.nim,
  });

  @override
  State<MahasiswaKrsPage> createState() => _MahasiswaKrsPageState();
}

class _MahasiswaKrsPageState extends State<MahasiswaKrsPage> {
  bool _isLoading = true;
  String? _selectedTahunAjaranId;
  List<Map<String, dynamic>> _listTahunAjaran = [];
  List<Map<String, dynamic>> _allKrsData = [];
  Map<String, dynamic>? _krsSayaData; 

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

    await _fetchKrsSaya();
  }

  Future<void> _fetchKrsSaya() async {
    setState(() => _isLoading = true);
    try {
      if (_allKrsData.isEmpty) {
        final res = await ApiClient.get(ApiConfig.getKrs);
        if (res['status'] == 'ok' && res['data'] != null) {
          var data = res['data'];
          if (data is List) {
            _allKrsData = data.map((e) => Map<String, dynamic>.from(e as Map)).toList();
          } else if (data is Map) {
            _allKrsData = [Map<String, dynamic>.from(data)];
          }
        }
      }
      
      _filterKrsData();
    } catch (e) {
      _showSnackBar('Gagal memuat KRS Anda', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _filterKrsData() {
    if (_selectedTahunAjaranId == null || _allKrsData.isEmpty) {
      _krsSayaData = null;
      return;
    }
    
    try {
      _krsSayaData = _allKrsData.firstWhere(
        (k) => k['tahun_ajaran_id']?.toString() == _selectedTahunAjaranId,
      );
    } catch (e) {
      _krsSayaData = null; // if not found
    }
  }

  void _showSnackBar(String msg, {bool isError = false}) {
    AppToast.show(context, msg, isError: isError);
  }

  Future<void> _cetakKrs() async {
    if (_krsSayaData == null || (_krsSayaData?['mata_kuliah'] as List?)?.isEmpty == true) {
      _showSnackBar('Tidak ada data KRS untuk dicetak', isError: true);
      return;
    }

    try {
      final doc = pw.Document();

      final List mkList = _krsSayaData?['mata_kuliah'] as List? ?? [];
      final status = _krsSayaData?['status'] ?? '-';
      
      final ta = _listTahunAjaran.firstWhere((e) => e['id']?.toString() == _selectedTahunAjaranId, orElse: () => {});
      final tahunAjaranStr = ta['nama'] ?? '-';
      final semesterStr = ta['semester'] ?? '-';

      int totalSks = 0;
      for (var mk in mkList) {
        totalSks += int.tryParse(mk['sks']?.toString() ?? '0') ?? 0;
      }

      doc.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (pw.Context context) {
            return [
              pw.Center(
                child: pw.Text(
                  'KARTU RENCANA STUDI (KRS)',
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
                      pw.Text('Semester: $semesterStr'),
                      pw.Text('Status: ${status.toString().toUpperCase()}'),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 20),
              pw.Table.fromTextArray(
                headers: ['No', 'Mata Kuliah', 'SKS', 'Dosen', 'Kelas'],
                data: List<List<String>>.generate(
                  mkList.length,
                  (index) {
                    final mk = mkList[index];
                    return [
                      '${index + 1}',
                      mk['nama_mk']?.toString() ?? '-',
                      mk['sks']?.toString() ?? '0',
                      mk['dosen']?.toString() ?? '-',
                      mk['nama_kelas']?.toString() ?? '-',
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
                  pw.Text('Total SKS: $totalSks', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                ],
              ),
            ];
          },
        ),
      );

      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => doc.save(),
        name: 'KRS_${widget.nim}_$tahunAjaranStr.pdf',
      );
    } catch (e) {
      _showSnackBar('Terjadi kesalahan saat membuat PDF', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEEF2FA), // Warna background biru muda sesuai desain
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            CustomTopBar(
              title: 'KRS Saya',
              nama: widget.nama,
              onBack: () => Navigator.popUntil(context, (route) => route.isFirst),
            ),
            const SizedBox(height: 16),
            if (_listTahunAjaran.isNotEmpty) _buildSemesterChips(),
            const SizedBox(height: 16),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppColorsSoft.navy))
                  : _buildListKrsSaya(),
            ),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: FloatingActionButton.extended(
          onPressed: _cetakKrs,
          backgroundColor: const Color(0xFF1B1A30),
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          icon: const Icon(Icons.print_rounded, color: Colors.white, size: 20),
          label: const Text(
            'Cetak KRS',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ),
      ),
      bottomNavigationBar: MahasiswaNavHelper.buildNav(
        context: context,
        currentIndex: 0, 
        userId: widget.userId,
        nama: widget.nama,
        username: widget.username,
        nim: widget.nim,
        centerActionOnTap: () => AjukanKrsBottomSheet.show(context, onSuccess: _loadTahunAjaran),
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
          String semesterShort = ta['semester']?.toString() ?? '';
          String tahunShort = ta['nama']?.toString().split('/').first ?? ta['nama'] ?? '';
          final label = '$semesterShort $tahunShort';
          final isSelected = id == _selectedTahunAjaranId;

          return GestureDetector(
            onTap: () {
              if (!isSelected && id != null) {
                setState(() {
                  _selectedTahunAjaranId = id;
                  _filterKrsData();
                });
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

  Widget _buildListKrsSaya() {
    if (_krsSayaData == null || (_krsSayaData?['mata_kuliah'] as List?)?.isEmpty == true) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.assignment_outlined, size: 60, color: AppColorsSoft.textGray.withOpacity(0.5)),
            const SizedBox(height: 16),
            const Text('Anda belum mengajukan KRS', style: TextStyle(color: AppColorsSoft.textGray)),
          ],
        ),
      );
    }

    final mkList = _krsSayaData?['mata_kuliah'] as List;
    final status = _krsSayaData?['status'] ?? '-';
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Row(
            children: [
              const Text('Status Pengajuan: ', style: TextStyle(color: AppColorsSoft.textGray)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: status == 'disetujui' ? const Color(0xFFE2F6EA) : const Color(0xFFFFF4D9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  status.toString().toUpperCase(),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: status == 'disetujui' ? const Color(0xFF12A150) : const Color(0xFFD38B00),
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20).copyWith(bottom: 20),
            itemCount: mkList.length,
            itemBuilder: (context, index) {
              final k = mkList[index];
              final namaMk = k['nama_mk'] ?? '-';
              final sks = k['sks']?.toString() ?? '0';
              final dosen = k['dosen'] ?? '-';
              final kelas = k['nama_kelas'] ?? '-';

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            namaMk.toString(),
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColorsSoft.navy,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(Icons.person_outline_rounded, size: 14, color: AppColorsSoft.textGray),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  dosen.toString(),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: AppColorsSoft.textGray,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFEAD9), // Light peach
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            kelas.toString(),
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFFD35500),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '$sks SKS',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColorsSoft.navy,
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
      ],
    );
  }
}
