import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/api_client.dart';
import '../../config/api_config.dart';

class DosenInputNilaiPage extends StatefulWidget {
  final String dosenId;
  final String nama;

  const DosenInputNilaiPage({
    super.key,
    required this.dosenId,
    required this.nama,
  });

  @override
  State<DosenInputNilaiPage> createState() => _DosenInputNilaiPageState();
}

class _DosenInputNilaiPageState extends State<DosenInputNilaiPage> {
  bool _isLoading = false;
  String _errorMessage = '';

  List<dynamic> _allKelasDosen = [];
  List<Map<String, dynamic>> _mataKuliahList = [];
  List<dynamic> _kelasList = []; // Kelas for selected MK
  List<dynamic> _nilaiList = []; // Students in selected Kelas

  String? _selectedMataKuliahId;
  String? _selectedKelasId;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _fetchKelasDosen();
  }

  Future<void> _fetchKelasDosen() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final response = await ApiClient.get(
        ApiConfig.getKelas,
        queryParams: {'dosen_id': widget.dosenId},
      );
      if (response['status'] == 'ok') {
        _allKelasDosen = response['data'] ?? [];
        
        // Ekstrak unique Mata Kuliah
        final Map<String, String> mkMap = {};
        for (var k in _allKelasDosen) {
          final mkId = k['mata_kuliah_id']?.toString() ?? '';
          final mkNama = k['nama_mk']?.toString() ?? 'Unknown';
          if (mkId.isNotEmpty) {
            mkMap[mkId] = mkNama;
          }
        }
        
        _mataKuliahList = mkMap.entries.map((e) => {
          'id': e.key,
          'nama_mk': e.value
        }).toList();

      } else {
        _errorMessage = response['message'] ?? 'Gagal memuat daftar kelas.';
      }
    } catch (e) {
      _errorMessage = 'Terjadi kesalahan: $e';
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _onMataKuliahSelected(String mkId) {
    setState(() {
      _selectedMataKuliahId = mkId;
      _selectedKelasId = null;
      _nilaiList = [];
      _kelasList = _allKelasDosen.where((k) => k['mata_kuliah_id'].toString() == mkId).toList();
    });
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nilai berhasil disimpan')),
        );
        _fetchNilai(_selectedKelasId!);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response['message'] ?? 'Gagal menyimpan nilai')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Filter pencarian nama/NIM
    final filteredNilaiList = _nilaiList.where((n) {
      final nama = (n['nama_mahasiswa'] ?? '').toLowerCase();
      final nim = (n['nim'] ?? '').toLowerCase();
      final q = _searchQuery.toLowerCase();
      return nama.contains(q) || nim.contains(q);
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FE),
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 24, 16),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: AppColorsSoft.navy),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Text(
                    'Input Nilai',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColorsSoft.navy,
                    ),
                  ),
                  const Spacer(),
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: AppColorsSoft.navy,
                    child: Text(
                      widget.nama.isNotEmpty ? widget.nama[0].toUpperCase() : 'D',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            Expanded(
              child: Stack(
                children: [
                  CustomScrollView(
                    slivers: [
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Dropdown Mata Kuliah
                              _buildDropdown(
                                label: 'Mata Kuliah',
                                value: _selectedMataKuliahId,
                                items: _mataKuliahList.map((m) {
                                  return DropdownMenuItem<String>(
                                    value: m['id'].toString(),
                                    child: Text(m['nama_mk']),
                                  );
                                }).toList(),
                                onChanged: (val) => _onMataKuliahSelected(val!),
                                hint: 'Pilih Mata Kuliah',
                              ),
                              const SizedBox(height: 16),
                              
                              // Dropdown Kelas
                              _buildDropdown(
                                label: 'Kelas',
                                value: _selectedKelasId,
                                items: _kelasList.map((k) {
                                  return DropdownMenuItem<String>(
                                    value: k['id'].toString(),
                                    child: Text('${k['nama_kelas']} - Ruang ${k['nama_ruang'] ?? '-'}'),
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

                              // Search Bar
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.5),
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(color: Colors.grey.shade200),
                                ),
                                child: TextField(
                                  onChanged: (val) => setState(() => _searchQuery = val),
                                  decoration: const InputDecoration(
                                    border: InputBorder.none,
                                    icon: Icon(Icons.search, color: AppColorsSoft.textGray, size: 20),
                                    hintText: 'Cari nama atau NIM mahasiswa...',
                                    hintStyle: TextStyle(
                                      color: AppColorsSoft.textGray,
                                      fontSize: 14,
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

                      // List Mahasiswa
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              return _buildNilaiCard(filteredNilaiList[index]);
                            },
                            childCount: filteredNilaiList.length,
                          ),
                        ),
                      ),
                      
                      // Bottom Spacing
                      const SliverToBoxAdapter(child: SizedBox(height: 100)),
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
    );
  }

  Widget _buildDropdown({
    required String label,
    required String? value,
    required List<DropdownMenuItem<String>> items,
    required ValueChanged<String?> onChanged,
    required String hint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColorsSoft.textGray,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
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
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              value: value,
              hint: Text(hint, style: const TextStyle(fontSize: 14)),
              icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColorsSoft.textGray),
              items: items,
              onChanged: onChanged,
            ),
          ),
        ),
      ],
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
        gradeColor = const Color(0xFFE26A2E); // Orange-ish for B in the design mockup
        gradeBg = const Color(0xFFFCE3D6);
        break;
      case 'C':
        gradeColor = const Color(0xFFF2994A);
        gradeBg = const Color(0xFFFEF0E2);
        break;
      case 'D':
      case 'E':
        gradeColor = const Color(0xFFEB5757); // Red for D/E
        gradeBg = const Color(0xFFFDE4E4);
        break;
      default:
        gradeColor = AppColorsSoft.textGray;
        gradeBg = Colors.grey.shade200;
    }

    final String nama = nilai['nama_mahasiswa'] ?? 'Unknown';
    // Get up to 2 initials (e.g. Budi Santoso -> BS)
    final parts = nama.split(' ');
    String inisial = '';
    if (parts.isNotEmpty) {
      inisial += parts[0][0].toUpperCase();
      if (parts.length > 1) {
        inisial += parts[1][0].toUpperCase();
      }
    }

    return GestureDetector(
      onTap: () => _showEditSheet(nilai),
      child: Container(
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
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColorsSoft.navy.withOpacity(0.05),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    inisial,
                    style: const TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 16,
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
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColorsSoft.navy,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        nilai['nim'] ?? '-',
                        style: const TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 12,
                          color: AppColorsSoft.textGray,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.spaceEvenly,
              children: [
                _buildNilaiBox('TGS', nilai['tugas']),
                _buildNilaiBox('QZ1', nilai['quiz_1']),
                _buildNilaiBox('QZ2', nilai['quiz_2']),
                _buildNilaiBox('UTS', nilai['uts']),
                _buildNilaiBox('HDR', nilai['kehadiran']),
                _buildNilaiBox('UAS', nilai['uas']),
                _buildNilaiBox('GRADE', grade, bgColor: gradeBg, textColor: gradeColor, isString: true),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNilaiBox(String label, dynamic value, {Color? bgColor, Color? textColor, bool isString = false}) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.bold,
            color: AppColorsSoft.textGray,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: 40,
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: bgColor ?? const Color(0xFFF2F4F8),
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Text(
            isString ? value.toString() : (value?.toString() ?? '0'),
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: textColor ?? AppColorsSoft.navy,
            ),
          ),
        ),
      ],
    );
  }
}
