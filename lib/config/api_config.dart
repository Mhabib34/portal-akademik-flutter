// ============================================================
// api_config.dart — Konfigurasi URL API
//   SATU-SATUNYA tempat base URL didefinisikan. Kalau server
//   pindah IP/domain, cukup ubah `baseUrl` di sini saja.
// ============================================================

class ApiConfig {
  ApiConfig._();

  static const String baseUrl = 'http://192.168.1.10/flutter_api/';

  // --- Sistem ---
  static const String cekKoneksi = '${baseUrl}cek_koneksi.php';

  // --- Auth ---
  static const String login = '${baseUrl}login.php';
  static const String logout = '${baseUrl}logout.php';
  static const String changePassword = '${baseUrl}change_password.php';
  static const String resetPassword = '${baseUrl}reset_password.php';
  static const String toggleAktif = '${baseUrl}toggle_aktif.php';

  // --- Mahasiswa ---
  static const String getMahasiswa = '${baseUrl}get_mahasiswa.php';
  static const String simpanMahasiswa = '${baseUrl}simpan_mahasiswa.php';
  static const String updateMahasiswa = '${baseUrl}update_mahasiswa.php';
  static const String deleteMahasiswa = '${baseUrl}delete_mahasiswa.php';

  // --- Dosen ---
  static const String getDosen = '${baseUrl}get_dosen.php';
  static const String simpanDosen = '${baseUrl}simpan_dosen.php';
  static const String updateDosen = '${baseUrl}update_dosen.php';
  static const String deleteDosen = '${baseUrl}delete_dosen.php';

  // --- Mata Kuliah ---
  static const String getMataKuliah = '${baseUrl}get_mata_kuliah.php';
  static const String simpanMataKuliah = '${baseUrl}simpan_mata_kuliah.php';
  static const String updateMataKuliah = '${baseUrl}update_mata_kuliah.php';
  static const String deleteMataKuliah = '${baseUrl}delete_mata_kuliah.php';

  // --- Ruang ---
  static const String getRuang = '${baseUrl}get_ruang.php';
  static const String simpanRuang = '${baseUrl}simpan_ruang.php';
  static const String updateRuang = '${baseUrl}update_ruang.php';
  static const String deleteRuang = '${baseUrl}delete_ruang.php';

  // --- Tahun Ajaran ---
  static const String getTahunAjaran = '${baseUrl}get_tahun_ajaran.php';
  static const String simpanTahunAjaran = '${baseUrl}simpan_tahun_ajaran.php';
  static const String setTahunAjaranAktif =
      '${baseUrl}set_tahun_ajaran_aktif.php';

  // --- Kelas (rombel) ---
  static const String getKelas = '${baseUrl}get_kelas.php';
  static const String simpanKelas = '${baseUrl}simpan_kelas.php';
  static const String updateKelas = '${baseUrl}update_kelas.php';
  static const String deleteKelas = '${baseUrl}delete_kelas.php';

  // --- Jadwal ---
  static const String getJadwal = '${baseUrl}get_jadwal.php';
  static const String simpanJadwal = '${baseUrl}simpan_jadwal.php';
  static const String updateJadwal = '${baseUrl}update_jadwal.php';
  static const String deleteJadwal = '${baseUrl}delete_jadwal.php';

  // --- KRS ---
  static const String getKelasTersedia = '${baseUrl}get_kelas_tersedia.php';
  static const String getKrs = '${baseUrl}get_krs.php';
  static const String ajukanKrs = '${baseUrl}ajukan_krs.php';
  static const String approveKrs = '${baseUrl}approve_krs.php';

  // --- Nilai ---
  static const String getNilai = '${baseUrl}get_nilai.php';
  static const String simpanNilai = '${baseUrl}simpan_nilai.php';
  static const String getKhs = '${baseUrl}get_khs.php';

  // --- Fakultas ---
  static const String getFakultas = '${baseUrl}get_fakultas.php';
  static const String simpanFakultas = '${baseUrl}simpan_fakultas.php';
  static const String updateFakultas = '${baseUrl}update_fakultas.php';
  static const String deleteFakultas = '${baseUrl}delete_fakultas.php';

  // --- Prodi ---
  static const String getProdi = '${baseUrl}get_prodi.php';
  static const String simpanProdi = '${baseUrl}simpan_prodi.php';
  static const String updateProdi = '${baseUrl}update_prodi.php';
  static const String deleteProdi = '${baseUrl}delete_prodi.php';
}
