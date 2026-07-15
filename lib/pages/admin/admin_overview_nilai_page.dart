import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../theme/app_theme.dart';
import '../../services/api_client.dart';
import '../../config/api_config.dart';
import '../../widgets/admin_nav_helper.dart';
import '../../widgets/custom_top_bar.dart';
import '../../utils/app_toast.dart';

class AdminOverviewNilaiPage extends StatefulWidget {
  final String nama;
  const AdminOverviewNilaiPage({super.key, required this.nama});

  @override
  State<AdminOverviewNilaiPage> createState() => _AdminOverviewNilaiPageState();
}

class _AdminOverviewNilaiPageState extends State<AdminOverviewNilaiPage> {
  bool _isLoading = false;
  String _errorMessage = '';

  List<dynamic> _mataKuliahList = [];
  List<dynamic> _kelasList = [];
  List<dynamic> _nilaiList = [];

  String? _selectedMataKuliahId;
  String? _selectedKelasId;

  // Untuk pagination UI statis (opsional, karena data bisa di-scroll)
  int _currentPage = 1;
  final int _itemsPerPage = 10;

  @override
  void initState() {
    super.initState();
    _fetchMataKuliah();
  }

  Future<void> _fetchMataKuliah() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final response = await ApiClient.get(ApiConfig.getMataKuliah);
      if (response['status'] == 'ok') {
        setState(() {
          _mataKuliahList = response['data'] ?? [];
        });
      } else {
        _errorMessage = response['message'] ?? 'Gagal memuat mata kuliah.';
      }
    } catch (e) {
      _errorMessage = 'Terjadi kesalahan: $e';
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchKelas(String mkId) async {
    setState(() {
      _isLoading = true;
      _kelasList = [];
      _selectedKelasId = null;
      _nilaiList = [];
    });

    try {
      final response = await ApiClient.get(ApiConfig.getKelas);
      if (response['status'] == 'ok') {
        final List<dynamic> allKelas = response['data'] ?? [];
        setState(() {
          // Filter kelas berdasarkan mata kuliah
          _kelasList = allKelas.where((k) => k['mata_kuliah_id'].toString() == mkId).toList();
        });
      }
    } catch (e) {
      _errorMessage = 'Gagal memuat kelas: $e';
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchNilai(String kelasId) async {
    setState(() {
      _isLoading = true;
      _nilaiList = [];
    });

    try {
      final response = await ApiClient.get(
        ApiConfig.getNilai,
        queryParams: {'kelas_id': kelasId},
      );
      if (response['status'] == 'ok') {
        setState(() {
          _nilaiList = response['data'] ?? [];
          _currentPage = 1;
        });
      } else {
        _errorMessage = response['message'] ?? 'Gagal memuat nilai.';
      }
    } catch (e) {
      _errorMessage = 'Terjadi kesalahan: $e';
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _exportPdf() async {
    if (_selectedKelasId == null || _nilaiList.isEmpty) {
      AppToast.show(context, 'Tidak ada data nilai untuk di-export.', isError: false);
      return;
    }

    final pdf = pw.Document();
    
    // Cari nama mata kuliah dan kelas
    final mk = _mataKuliahList.firstWhere((m) => m['id'].toString() == _selectedMataKuliahId, orElse: () => {'nama_mk': '-'});
    final kelas = _kelasList.firstWhere((k) => k['id'].toString() == _selectedKelasId, orElse: () => {'nama_kelas': '-'});

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Laporan Overview Nilai', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 10),
              pw.Text('Mata Kuliah: ${mk['nama_mk']}'),
              pw.Text('Kelas: ${kelas['nama_kelas']}'),
              pw.SizedBox(height: 20),
              pw.Table.fromTextArray(
                headers: ['NIM', 'Nama Mahasiswa', 'Tugas', 'UTS', 'UAS', 'Akhir', 'Grade'],
                data: _nilaiList.map((n) => [
                  n['nim'] ?? '-',
                  n['nama_mahasiswa'] ?? '-',
                  n['tugas']?.toString() ?? '0',
                  n['uts']?.toString() ?? '0',
                  n['uas']?.toString() ?? '0',
                  n['nilai_angka']?.toString() ?? '0',
                  n['nilai_huruf'] ?? '-',
                ]).toList(),
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                cellAlignment: pw.Alignment.centerLeft,
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Rekap_Nilai_${kelas['nama_kelas']}.pdf',
    );
  }

  void _showEditSheet(Map<String, dynamic> nilai) {
    final tugasCtrl = TextEditingController(text: nilai['tugas']?.toString() ?? '0');
    final quiz1Ctrl = TextEditingController(text: nilai['quiz_1']?.toString() ?? '0');
    final quiz2Ctrl = TextEditingController(text: nilai['quiz_2']?.toString() ?? '0');
    final utsCtrl = TextEditingController(text: nilai['uts']?.toString() ?? '0');
    final kehadiranCtrl = TextEditingController(text: nilai['kehadiran']?.toString() ?? '0');
    final uasCtrl = TextEditingController(text: nilai['uas']?.toString() ?? '0');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Edit Nilai: ${nilai['nama_mahasiswa']}',
                  style: const TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: AppColorsSoft.navy,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(child: _buildTextField('Tugas', tugasCtrl)),
                    const SizedBox(width: 16),
                    Expanded(child: _buildTextField('Quiz 1', quiz1Ctrl)),
                    const SizedBox(width: 16),
                    Expanded(child: _buildTextField('Quiz 2', quiz2Ctrl)),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: _buildTextField('UTS', utsCtrl)),
                    const SizedBox(width: 16),
                    Expanded(child: _buildTextField('Hadir', kehadiranCtrl)),
                    const SizedBox(width: 16),
                    Expanded(child: _buildTextField('UAS', uasCtrl)),
                  ],
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColorsSoft.navy,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () async {
                      Navigator.pop(context);
                      await _updateNilai(
                        nilai['mahasiswa_id'].toString(),
                        double.tryParse(tugasCtrl.text) ?? 0,
                        double.tryParse(quiz1Ctrl.text) ?? 0,
                        double.tryParse(quiz2Ctrl.text) ?? 0,
                        double.tryParse(utsCtrl.text) ?? 0,
                        double.tryParse(kehadiranCtrl.text) ?? 0,
                        double.tryParse(uasCtrl.text) ?? 0,
                      );
                    },
                    child: const Text(
                      'Simpan Nilai',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTextField(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppColorsSoft.textGray,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ],
    );
  }

  Future<void> _updateNilai(String mahasiswaId, double tugas, double quiz1, double quiz2, double uts, double kehadiran, double uas) async {
    setState(() => _isLoading = true);
    try {
      final payload = {
        'kelas_id': _selectedKelasId,
        'nilai': [
          {
            'mahasiswa_id': mahasiswaId,
            'tugas': tugas,
            'quiz_1': quiz1,
            'quiz_2': quiz2,
            'uts': uts,
            'kehadiran': kehadiran,
            'uas': uas,
          }
        ]
      };
      
      final response = await ApiClient.postJson(ApiConfig.simpanNilai, body: payload);
      if (response['status'] == 'ok') {
        AppToast.show(context, 'Nilai berhasil disimpan', isError: false);
        _fetchNilai(_selectedKelasId!);
      } else {
        AppToast.show(context, response['message'] ?? 'Gagal menyimpan nilai', isError: false);
      }
    } catch (e) {
      AppToast.show(context, 'Error: $e', isError: false);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Client-side pagination logic
    final int totalItems = _nilaiList.length;
    final int totalPages = (totalItems / _itemsPerPage).ceil();
    final int startIndex = (_currentPage - 1) * _itemsPerPage;
    final int endIndex = (startIndex + _itemsPerPage > totalItems) 
        ? totalItems 
        : startIndex + _itemsPerPage;
    final List<dynamic> paginatedNilai = _nilaiList.isNotEmpty 
        ? _nilaiList.sublist(startIndex, endIndex) 
        : [];

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FE), // Soft blueish background from mockup
      body: SafeArea(
        child: Column(
          children: [
            CustomTopBar(
              title: 'Overview Nilai',
              nama: widget.nama,
              onBack: () => Navigator.pop(context),
            ),
            Expanded(
              child: Stack(
                children: [
                  CustomScrollView(
                    slivers: [
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                        const SizedBox(height: 8),
                        const Text(
                          'Kelola dan tinjau performa akademik mahasiswa secara real-time dengan transparansi penuh.',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 14,
                            color: AppColorsSoft.textGray,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 24),
                        
                        // Dropdown Mata Kuliah
                        _buildDropdown(
                          icon: Icons.school_outlined,
                          label: 'MATA KULIAH',
                          value: _selectedMataKuliahId,
                          items: _mataKuliahList.map((m) {
                            return DropdownMenuItem<String>(
                              value: m['id'].toString(),
                              child: Text(m['nama_mk']),
                            );
                          }).toList(),
                          onChanged: (val) {
                            setState(() {
                              _selectedMataKuliahId = val;
                              _fetchKelas(val!);
                            });
                          },
                          hint: 'Pilih Mata Kuliah',
                        ),
                        const SizedBox(height: 16),
                        
                        // Dropdown Kelas
                        _buildDropdown(
                          icon: Icons.people_outline,
                          label: 'KELAS',
                          value: _selectedKelasId,
                          items: _kelasList.map((k) {
                            return DropdownMenuItem<String>(
                              value: k['id'].toString(),
                              child: Text(k['nama_kelas']),
                            );
                          }).toList(),
                          onChanged: (val) {
                            setState(() {
                              _selectedKelasId = val;
                              _fetchNilai(val!);
                            });
                          },
                          hint: 'Pilih Kelas',
                        ),
                        const SizedBox(height: 24),

                        // Export Button
                        Align(
                          alignment: Alignment.centerRight,
                          child: ElevatedButton.icon(
                            onPressed: _exportPdf,
                            icon: const Icon(Icons.download_rounded, size: 18),
                            label: const Text('Export PDF'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColorsSoft.navy,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              textStyle: const TextStyle(
                                fontFamily: 'Outfit',
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),

                // Error Message
                if (_errorMessage.isNotEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        _errorMessage,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  ),

                // Daftar Mahasiswa
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        return _buildNilaiCard(paginatedNilai[index]);
                      },
                      childCount: paginatedNilai.length,
                    ),
                  ),
                ),

                // Pagination
                if (_nilaiList.isNotEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 32),
                      child: Column(
                        children: [
                          Text(
                            'Menampilkan ${endIndex - startIndex} dari $totalItems Mahasiswa',
                            style: const TextStyle(
                              color: AppColorsSoft.textGray,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _buildPaginationButton(
                                icon: Icons.chevron_left,
                                onTap: _currentPage > 1 
                                  ? () => setState(() => _currentPage--) 
                                  : null,
                              ),
                              const SizedBox(width: 8),
                              ...List.generate(totalPages, (index) {
                                final page = index + 1;
                                return Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 4),
                                  child: _buildPaginationNumber(
                                    page: page,
                                    isActive: page == _currentPage,
                                    onTap: () => setState(() => _currentPage = page),
                                  ),
                                );
                              }),
                              const SizedBox(width: 8),
                              _buildPaginationButton(
                                icon: Icons.chevron_right,
                                onTap: _currentPage < totalPages 
                                  ? () => setState(() => _currentPage++) 
                                  : null,
                              ),
                            ],
                          ),
                          const SizedBox(height: 100), // Spasi bawah untuk bottom nav
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              if (_isLoading)
                const Center(
                  child: CircularProgressIndicator(),
                ),
            ],
          ),
          ),
        ],
      ),
      ),
      bottomNavigationBar: AdminNavHelper.buildNav(context: context, currentIndex: -1),
    );
  }

  Widget _buildDropdown({
    required IconData icon,
    required String label,
    required String? value,
    required List<DropdownMenuItem<String>> items,
    required ValueChanged<String?> onChanged,
    required String hint,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: AppColorsSoft.textGray),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: AppColorsSoft.textGray,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              value: value,
              hint: Text(hint, style: const TextStyle(fontSize: 14)),
              icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColorsSoft.textGray),
              items: items,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNilaiCard(Map<String, dynamic> nilai) {
    // Tentukan warna berdasarkan grade
    final grade = nilai['nilai_huruf'] ?? '-';
    Color gradeColor;
    Color gradeBg;

    switch (grade) {
      case 'A':
        gradeColor = const Color(0xFF00B087);
        gradeBg = const Color(0xFFDFFAEA);
        break;
      case 'B':
        gradeColor = const Color(0xFF1C54F2);
        gradeBg = const Color(0xFFE2EAFE);
        break;
      case 'C':
        gradeColor = const Color(0xFFF2994A);
        gradeBg = const Color(0xFFFEF0E2);
        break;
      case 'D':
      case 'E':
        gradeColor = const Color(0xFFEB5757);
        gradeBg = const Color(0xFFFDE4E4);
        break;
      default:
        gradeColor = AppColorsSoft.textGray;
        gradeBg = Colors.grey.shade200;
    }

    final String nama = nilai['nama_mahasiswa'] ?? 'Unknown';
    final String inisial = nama.isNotEmpty ? nama.substring(0, 1).toUpperCase() : '?';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Avatar, Nama, NIM
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColorsSoft.navy.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Text(
                  inisial,
                  style: const TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColorsSoft.navy,
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
                        fontFamily: 'Outfit',
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColorsSoft.navy,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      nilai['nim'] ?? '-',
                      style: const TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 13,
                        color: AppColorsSoft.textGray,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // Komponen Nilai
          const Text(
            'Komponen Nilai',
            style: TextStyle(
              fontSize: 13,
              color: AppColorsSoft.textGray,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _buildNilaiBox('TGS', nilai['tugas']),
              _buildNilaiBox('QZ1', nilai['quiz_1']),
              _buildNilaiBox('QZ2', nilai['quiz_2']),
              _buildNilaiBox('UTS', nilai['uts']),
              _buildNilaiBox('HDR', nilai['kehadiran']),
              _buildNilaiBox('UAS', nilai['uas']),
              _buildNilaiBox('FIN', nilai['nilai_angka'], isFinal: true),
            ],
          ),
          const SizedBox(height: 20),
          
          // Footer: Grade & Edit Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: gradeBg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Grade $grade',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: gradeColor,
                  ),
                ),
              ),
              InkWell(
                onTap: () => _showEditSheet(nilai),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.edit_rounded, size: 18, color: AppColorsSoft.textGray),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNilaiBox(String label, dynamic value, {bool isFinal = false}) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: AppColorsSoft.textGray,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: 55,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isFinal ? const Color(0xFFD4D2E3) : const Color(0xFFF2F4F8),
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: Text(
            value?.toString() ?? '0',
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: isFinal ? AppColorsSoft.navy : AppColorsSoft.navy,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPaginationNumber({required int page, required bool isActive, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: isActive ? AppColorsSoft.navy : Colors.white,
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Text(
          page.toString(),
          style: TextStyle(
            fontFamily: 'Outfit',
            fontWeight: FontWeight.bold,
            color: isActive ? Colors.white : AppColorsSoft.textGray,
          ),
        ),
      ),
    );
  }

  Widget _buildPaginationButton({required IconData icon, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Icon(
          icon,
          size: 20,
          color: onTap != null ? AppColorsSoft.textGray : Colors.grey.shade300,
        ),
      ),
    );
  }
}
