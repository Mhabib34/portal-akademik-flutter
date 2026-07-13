// ============================================================
// api_config.dart — Konfigurasi URL API
//   SATU-SATUNYA tempat base URL didefinisikan. Kalau server
//   pindah IP/domain, cukup ubah `baseUrl` di sini saja.
// ============================================================

class ApiConfig {
  ApiConfig._();

  static const String baseUrl = 'http://192.168.1.10/flutter_api/';

  // --- Sistem ---
  static const String cekKoneksi = '${baseUrl}config/cek_koneksi.php';

  // --- Auth ---
  static const String login = '${baseUrl}auth/login.php';
  static const String logout = '${baseUrl}auth/logout.php';
  static const String changePassword = '${baseUrl}auth/change_password.php';
  static const String resetPassword = '${baseUrl}auth/reset_password.php';
  static const String toggleAktif = '${baseUrl}master/toggle_aktif.php';

  // --- Mahasiswa ---
  static const String getMahasiswa = '${baseUrl}master/get_mahasiswa.php';
  static const String simpanMahasiswa = '${baseUrl}master/simpan_mahasiswa.php';
  static const String updateMahasiswa = '${baseUrl}master/update_mahasiswa.php';
  static const String deleteMahasiswa = '${baseUrl}master/delete_mahasiswa.php';

  // --- Dosen ---
  static const String getDosen = '${baseUrl}master/get_dosen.php';
  static const String simpanDosen = '${baseUrl}master/simpan_dosen.php';
  static const String updateDosen = '${baseUrl}master/update_dosen.php';
  static const String deleteDosen = '${baseUrl}master/delete_dosen.php';

  // --- Mata Kuliah ---
  static const String getMataKuliah = '${baseUrl}master/get_mata_kuliah.php';
  static const String simpanMataKuliah = '${baseUrl}master/simpan_mata_kuliah.php';
  static const String updateMataKuliah = '${baseUrl}master/update_mata_kuliah.php';
  static const String deleteMataKuliah = '${baseUrl}master/delete_mata_kuliah.php';

  // --- Ruang ---
  static const String getRuang = '${baseUrl}master/get_ruang.php';
  static const String simpanRuang = '${baseUrl}master/simpan_ruang.php';
  static const String updateRuang = '${baseUrl}master/update_ruang.php';
  static const String deleteRuang = '${baseUrl}master/delete_ruang.php';

  // --- Tahun Ajaran ---
  static const String getTahunAjaran = '${baseUrl}master/get_tahun_ajaran.php';
  static const String simpanTahunAjaran = '${baseUrl}master/simpan_tahun_ajaran.php';
  static const String setTahunAjaranAktif =
      '${baseUrl}master/set_tahun_ajaran_aktif.php';

  // --- Kelas (rombel) ---
  static const String getKelas = '${baseUrl}master/get_kelas.php';
  static const String simpanKelas = '${baseUrl}master/simpan_kelas.php';
  static const String updateKelas = '${baseUrl}master/update_kelas.php';
  static const String deleteKelas = '${baseUrl}master/delete_kelas.php';

  // --- Jadwal ---
  static const String getJadwal = '${baseUrl}akademik/get_jadwal.php';
  static const String simpanJadwal = '${baseUrl}akademik/simpan_jadwal.php';
  static const String updateJadwal = '${baseUrl}akademik/update_jadwal.php';
  static const String deleteJadwal = '${baseUrl}akademik/delete_jadwal.php';

  // --- KRS ---
  static const String getKelasTersedia = '${baseUrl}akademik/get_kelas_tersedia.php';
  static const String getKrs = '${baseUrl}akademik/get_krs.php';
  static const String ajukanKrs = '${baseUrl}akademik/ajukan_krs.php';
  static const String approveKrs = '${baseUrl}akademik/approve_krs.php';

  // --- Nilai ---
  static const String getNilai = '${baseUrl}akademik/get_nilai.php';
  static const String simpanNilai = '${baseUrl}akademik/simpan_nilai.php';
  static const String getKhs = '${baseUrl}akademik/get_khs.php';

  // --- Fakultas ---
  static const String getFakultas = '${baseUrl}master/get_fakultas.php';
  static const String simpanFakultas = '${baseUrl}master/simpan_fakultas.php';
  static const String updateFakultas = '${baseUrl}master/update_fakultas.php';
  static const String deleteFakultas = '${baseUrl}master/delete_fakultas.php';

  // --- Prodi ---
  static const String getProdi = '${baseUrl}master/get_prodi.php';
  static const String simpanProdi = '${baseUrl}master/simpan_prodi.php';
  static const String updateProdi = '${baseUrl}master/update_prodi.php';
  static const String deleteProdi = '${baseUrl}master/delete_prodi.php';
}
