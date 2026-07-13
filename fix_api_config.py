import re
import os

api_map = {
    'koneksi.php': 'config',
    'cek_koneksi.php': 'config',
    'auth_helper.php': 'auth',
    'login.php': 'auth',
    'logout.php': 'auth',
    'change_password.php': 'auth',
    'reset_password.php': 'auth',
    'get_krs.php': 'akademik',
    'ajukan_krs.php': 'akademik',
    'approve_krs.php': 'akademik',
    'get_khs.php': 'akademik',
    'get_jadwal.php': 'akademik',
    'simpan_jadwal.php': 'akademik',
    'update_jadwal.php': 'akademik',
    'delete_jadwal.php': 'akademik',
    'get_nilai.php': 'akademik',
    'simpan_nilai.php': 'akademik',
    'get_kelas_tersedia.php': 'akademik',
    'get_dosen.php': 'master',
    'simpan_dosen.php': 'master',
    'update_dosen.php': 'master',
    'delete_dosen.php': 'master',
    'get_mahasiswa.php': 'master',
    'simpan_mahasiswa.php': 'master',
    'update_mahasiswa.php': 'master',
    'delete_mahasiswa.php': 'master',
    'get_fakultas.php': 'master',
    'simpan_fakultas.php': 'master',
    'update_fakultas.php': 'master',
    'delete_fakultas.php': 'master',
    'get_prodi.php': 'master',
    'simpan_prodi.php': 'master',
    'update_prodi.php': 'master',
    'delete_prodi.php': 'master',
    'get_mata_kuliah.php': 'master',
    'simpan_mata_kuliah.php': 'master',
    'update_mata_kuliah.php': 'master',
    'delete_mata_kuliah.php': 'master',
    'get_ruang.php': 'master',
    'simpan_ruang.php': 'master',
    'update_ruang.php': 'master',
    'delete_ruang.php': 'master',
    'get_kelas.php': 'master',
    'simpan_kelas.php': 'master',
    'update_kelas.php': 'master',
    'delete_kelas.php': 'master',
    'get_tahun_ajaran.php': 'master',
    'simpan_tahun_ajaran.php': 'master',
    'set_tahun_ajaran_aktif.php': 'master',
    'toggle_aktif.php': 'master',
}

api_config_path = 'lib/config/api_config.dart'

with open(api_config_path, 'r') as f:
    content = f.read()

def repl_url(match):
    prefix = match.group(1)
    php_file = match.group(2)
    if php_file in api_map:
        folder = api_map[php_file]
        return f"{prefix}'${{baseUrl}}{folder}/{php_file}'"
    return match.group(0)

# Matches: static const String cekKoneksi = '${baseUrl}cek_koneksi.php';
new_content = re.sub(r"(static\s+const\s+String\s+\w+\s*=\s*)'\$\{baseUrl\}([^']+)'", repl_url, content)

with open(api_config_path, 'w') as f:
    f.write(new_content)
print("Updated api_config.dart")
