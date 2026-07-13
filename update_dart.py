import re

path = 'lib/pages/admin_overview_nilai_page.dart'
with open(path, 'r') as f:
    content = f.read()

# Replace Edit Sheet controllers
old_ctrls = """    final tugasCtrl = TextEditingController(text: nilai['tugas']?.toString() ?? '0');
    final utsCtrl = TextEditingController(text: nilai['uts']?.toString() ?? '0');
    final uasCtrl = TextEditingController(text: nilai['uas']?.toString() ?? '0');"""

new_ctrls = """    final tugasCtrl = TextEditingController(text: nilai['tugas']?.toString() ?? '0');
    final quiz1Ctrl = TextEditingController(text: nilai['quiz_1']?.toString() ?? '0');
    final quiz2Ctrl = TextEditingController(text: nilai['quiz_2']?.toString() ?? '0');
    final utsCtrl = TextEditingController(text: nilai['uts']?.toString() ?? '0');
    final kehadiranCtrl = TextEditingController(text: nilai['kehadiran']?.toString() ?? '0');
    final uasCtrl = TextEditingController(text: nilai['uas']?.toString() ?? '0');"""
content = content.replace(old_ctrls, new_ctrls)

# Replace Edit Sheet rows
old_rows = """                Row(
                  children: [
                    Expanded(child: _buildTextField('Tugas', tugasCtrl)),
                    const SizedBox(width: 16),
                    Expanded(child: _buildTextField('UTS', utsCtrl)),
                    const SizedBox(width: 16),
                    Expanded(child: _buildTextField('UAS', uasCtrl)),
                  ],
                ),"""

new_rows = """                Row(
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
                ),"""
content = content.replace(old_rows, new_rows)

# Replace _updateNilai call
old_call = """                      await _updateNilai(
                        nilai['mahasiswa_id'].toString(),
                        double.tryParse(tugasCtrl.text) ?? 0,
                        double.tryParse(utsCtrl.text) ?? 0,
                        double.tryParse(uasCtrl.text) ?? 0,
                      );"""

new_call = """                      await _updateNilai(
                        nilai['mahasiswa_id'].toString(),
                        double.tryParse(tugasCtrl.text) ?? 0,
                        double.tryParse(quiz1Ctrl.text) ?? 0,
                        double.tryParse(quiz2Ctrl.text) ?? 0,
                        double.tryParse(utsCtrl.text) ?? 0,
                        double.tryParse(kehadiranCtrl.text) ?? 0,
                        double.tryParse(uasCtrl.text) ?? 0,
                      );"""
content = content.replace(old_call, new_call)

# Replace _updateNilai signature
old_sig = "Future<void> _updateNilai(String mahasiswaId, double tugas, double uts, double uas) async {"
new_sig = "Future<void> _updateNilai(String mahasiswaId, double tugas, double quiz1, double quiz2, double uts, double kehadiran, double uas) async {"
content = content.replace(old_sig, new_sig)

# Replace _updateNilai payload
old_payload = """          {
            'mahasiswa_id': mahasiswaId,
            'tugas': tugas,
            'uts': uts,
            'uas': uas,
          }"""
new_payload = """          {
            'mahasiswa_id': mahasiswaId,
            'tugas': tugas,
            'quiz_1': quiz1,
            'quiz_2': quiz2,
            'uts': uts,
            'kehadiran': kehadiran,
            'uas': uas,
          }"""
content = content.replace(old_payload, new_payload)

# Replace NilaiCard components
old_card = """          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildNilaiBox('TGS', nilai['tugas']),
              _buildNilaiBox('UTS', nilai['uts']),
              _buildNilaiBox('UAS', nilai['uas']),
              _buildNilaiBox('FIN', nilai['nilai_angka'], isFinal: true),
            ],
          ),"""

new_card = """          Wrap(
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
          ),"""
content = content.replace(old_card, new_card)

with open(path, 'w') as f:
    f.write(content)
