import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_top_bar.dart';

// ============================================================
// dosen_mahasiswa_detail_page.dart — Halaman Detail Mahasiswa
//   Halaman Read-Only untuk melihat detail dan rincian nilai
//   mahasiswa dari perspektif Dosen.
// ============================================================

class DosenMahasiswaDetailPage extends StatelessWidget {
  final Map<String, dynamic> mahasiswaData;
  final String dosenNama;

  const DosenMahasiswaDetailPage({
    super.key,
    required this.mahasiswaData,
    required this.dosenNama,
  });

  @override
  Widget build(BuildContext context) {
    // Ekstraksi data
    final nama = mahasiswaData['nama_mahasiswa']?.toString() ?? 'Unknown';
    final nim = mahasiswaData['nim']?.toString() ?? '-';
    final prodi = mahasiswaData['nama_prodi']?.toString() ?? 'Informatika';
    final fakultas = mahasiswaData['nama_fakultas']?.toString() ?? 'Ilmu Komputer';
    final namaMk = mahasiswaData['nama_mk']?.toString() ?? '-';
    final sks = mahasiswaData['sks']?.toString() ?? '-';

    // Nilai
    final double tugas = _parseNilai(mahasiswaData['tugas']);
    final double quiz1 = _parseNilai(mahasiswaData['quiz_1']);
    final double quiz2 = _parseNilai(mahasiswaData['quiz_2']);
    final double uts = _parseNilai(mahasiswaData['uts']);
    final double kehadiran = _parseNilai(mahasiswaData['kehadiran']);
    final double uas = _parseNilai(mahasiswaData['uas']);
    
    final double nilaiAngka = _parseNilai(mahasiswaData['nilai_angka']);
    final String nilaiHuruf = mahasiswaData['nilai_huruf']?.toString() ?? '-';
    final double bobot = _parseNilai(mahasiswaData['bobot']);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FE),
      body: SafeArea(
        child: Column(
          children: [
            CustomTopBar(
              title: 'Detail Mahasiswa',
              nama: dosenNama,
              onBack: () => Navigator.pop(context),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _buildProfileHeader(nama, nim, prodi, fakultas),
                    const SizedBox(height: 24),
                    _buildCourseInfo(namaMk, sks),
                    const SizedBox(height: 24),
                    _buildFinalGradeSummary(nilaiHuruf, nilaiAngka, bobot),
                    const SizedBox(height: 24),
                    _buildDetailedGrades(
                      tugas: tugas,
                      quiz1: quiz1,
                      quiz2: quiz2,
                      uts: uts,
                      kehadiran: kehadiran,
                      uas: uas,
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  double _parseNilai(dynamic val) {
    if (val == null) return 0.0;
    if (val is double) return val;
    if (val is int) return val.toDouble();
    if (val is String) return double.tryParse(val) ?? 0.0;
    return 0.0;
  }

  Widget _buildProfileHeader(String nama, String nim, String prodi, String fakultas) {
    // Generate Initials
    final names = nama.split(' ');
    String initials = '';
    if (names.isNotEmpty) initials += names[0][0].toUpperCase();
    if (names.length > 1) initials += names[1][0].toUpperCase();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      decoration: AppColorsSoft.card(),
      child: Column(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: AppColorsSoft.navy.withOpacity(0.1),
            child: Text(
              initials,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppColorsSoft.navy,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            nama,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColorsSoft.navy,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: AppColorsSoft.fieldFill,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.badge_outlined, size: 14, color: AppColorsSoft.textGray),
                const SizedBox(width: 6),
                Text(
                  nim,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColorsSoft.textGray,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Divider(color: Color(0xFFE2E8F0)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Expanded(child: _buildSmallInfo(Icons.menu_book_rounded, prodi)),
              Container(width: 1, height: 30, color: const Color(0xFFE2E8F0)),
              Expanded(child: _buildSmallInfo(Icons.account_balance_rounded, fakultas)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSmallInfo(IconData icon, String text) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 16, color: AppColorsSoft.navy),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            text,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColorsSoft.navy,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCourseInfo(String namaMk, String sks) {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: AppColorsSoft.card(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Mata Kuliah',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColorsSoft.textGrayLight,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  namaMk,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColorsSoft.navy,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: AppColorsSoft.card(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                'SKS',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColorsSoft.textGrayLight,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                sks,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColorsSoft.navy,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFinalGradeSummary(String nilaiHuruf, double nilaiAngka, double bobot) {
    Color gradeColor;
    Color gradeBg;

    switch (nilaiHuruf) {
      case 'A':
        gradeColor = const Color(0xFF00B087);
        gradeBg = const Color(0xFFDFFAEA);
        break;
      case 'B':
        gradeColor = const Color(0xFFE26A2E);
        gradeBg = const Color(0xFFFCE3D6);
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

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: AppColorsSoft.card(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Hasil Akhir',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColorsSoft.navy,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildSummaryItem('Nilai Angka', nilaiAngka.toStringAsFixed(1), AppColorsSoft.navy, AppColorsSoft.navy.withOpacity(0.1)),
              _buildSummaryItem('Nilai Huruf', nilaiHuruf, gradeColor, gradeBg),
              _buildSummaryItem('Bobot', bobot.toStringAsFixed(2), const Color(0xFFB5651D), const Color(0xFFFFE8D6)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, Color textColor, Color bgColor) {
    return Column(
      children: [
        Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            color: bgColor,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: textColor,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColorsSoft.textGray,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailedGrades({
    required double tugas,
    required double quiz1,
    required double quiz2,
    required double uts,
    required double kehadiran,
    required double uas,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: AppColorsSoft.card(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Rincian Komponen Nilai',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColorsSoft.navy,
            ),
          ),
          const SizedBox(height: 20),
          _buildProgressRow('Tugas', tugas),
          const SizedBox(height: 16),
          _buildProgressRow('Quiz 1', quiz1),
          const SizedBox(height: 16),
          _buildProgressRow('Quiz 2', quiz2),
          const SizedBox(height: 16),
          _buildProgressRow('UTS', uts),
          const SizedBox(height: 16),
          _buildProgressRow('UAS', uas),
          const SizedBox(height: 16),
          _buildProgressRow('Kehadiran', kehadiran, color: const Color(0xFF00B087)),
        ],
      ),
    );
  }

  Widget _buildProgressRow(String label, double value, {Color? color}) {
    final clampValue = value.clamp(0.0, 100.0);
    final progressColor = color ?? AppColorsSoft.navy;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColorsSoft.navy,
              ),
            ),
            Text(
              clampValue.toStringAsFixed(1),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColorsSoft.navy,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: clampValue / 100.0,
            backgroundColor: progressColor.withOpacity(0.15),
            color: progressColor,
            minHeight: 8,
          ),
        ),
      ],
    );
  }
}
