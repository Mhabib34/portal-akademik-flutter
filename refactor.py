import os
import shutil
import glob

# Mapping dart pages
pages_map = {
    'login_page.dart': 'auth',
    'change_password.dart': 'auth',

    'admin_home_page.dart': 'admin',
    'admin_krs_page.dart': 'admin',
    'admin_overview_nilai_page.dart': 'admin',
    'manajemen_user_page.dart': 'admin',
    'penjadwalan_page.dart': 'admin',
    'fakultas_prodi_hub_page.dart': 'admin',

    'data_dosen_page.dart': 'admin/master',
    'data_fakultas_page.dart': 'admin/master',
    'data_kelas_page.dart': 'admin/master',
    'data_mahasiswa_page.dart': 'admin/master',
    'data_mata_kuliah_page.dart': 'admin/master',
    'data_prodi_page.dart': 'admin/master',
    'data_ruang_page.dart': 'admin/master',

    'dosen_home_page.dart': 'dosen',

    'mahasiswa_home_page.dart': 'mahasiswa',
    'mahasiswa_profil_page.dart': 'mahasiswa',

    'splash_page.dart': 'common',
    'home_router.dart': 'common'
}

# Mapping php files
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
}

base_dir = '/home/mhabib/Muhammad-Habib/latihan/belajar-flutter/app_input'

# 1. Create directories and move files
for file, folder in pages_map.items():
    src = os.path.join(base_dir, 'lib', 'pages', file)
    dst_dir = os.path.join(base_dir, 'lib', 'pages', folder)
    os.makedirs(dst_dir, exist_ok=True)
    dst = os.path.join(dst_dir, file)
    if os.path.exists(src):
        shutil.move(src, dst)

for file, folder in api_map.items():
    src = os.path.join(base_dir, 'flutter_api', file)
    dst_dir = os.path.join(base_dir, 'flutter_api', folder)
    os.makedirs(dst_dir, exist_ok=True)
    dst = os.path.join(dst_dir, file)
    if os.path.exists(src):
        shutil.move(src, dst)

# 2. Build absolute maps for all dart files
all_dart_files = glob.glob(os.path.join(base_dir, 'lib', '**', '*.dart'), recursive=True)

dart_file_paths = {}
for d in all_dart_files:
    basename = os.path.basename(d)
    dart_file_paths[basename] = d

# Replace imports in dart files
import re

for dart_file in all_dart_files:
    with open(dart_file, 'r') as f:
        content = f.read()
    
    # We will find all imports like `import '../pages/login_page.dart';`
    # and replace them with the correct relative path.
    # Actually, it's easier to just find the basename of the imported dart file,
    # look up its new absolute path, and calculate the new relative path!
    
    def repl_import(match):
        full_match = match.group(0)
        import_path = match.group(1)
        
        # If it's a package import or dart import, leave it
        if import_path.startswith('package:') or import_path.startswith('dart:'):
            return full_match
            
        basename = os.path.basename(import_path)
        if basename in dart_file_paths:
            target_abs = dart_file_paths[basename]
            source_dir = os.path.dirname(dart_file)
            
            # Calculate new relative path
            rel_path = os.path.relpath(target_abs, source_dir)
            if not rel_path.startswith('.'):
                rel_path = './' + rel_path
                
            return f"import '{rel_path}';"
        
        return full_match

    new_content = re.sub(r"import\s+['\"]([^'\"]+\.dart)['\"];", repl_import, content)
    
    if new_content != content:
        with open(dart_file, 'w') as f:
            f.write(new_content)

# 3. Rewrite PHP requires
all_php_files = glob.glob(os.path.join(base_dir, 'flutter_api', '**', '*.php'), recursive=True)
php_file_paths = {}
for p in all_php_files:
    php_file_paths[os.path.basename(p)] = p

for php_file in all_php_files:
    with open(php_file, 'r') as f:
        content = f.read()

    def repl_php(match):
        prefix = match.group(1)
        import_path = match.group(2)
        basename = os.path.basename(import_path)
        if basename in php_file_paths:
            target_abs = php_file_paths[basename]
            source_dir = os.path.dirname(php_file)
            rel_path = os.path.relpath(target_abs, source_dir)
            if not rel_path.startswith('.'):
                rel_path = './' + rel_path
            return f"{prefix}'{rel_path}'"
        return match.group(0)

    new_content = re.sub(r"(require_once\s+)['\"]([^'\"]+\.php)['\"]", repl_php, content)
    if new_content != content:
        with open(php_file, 'w') as f:
            f.write(new_content)

# 4. Update api_config.dart URLs
api_config_path = os.path.join(base_dir, 'lib', 'config', 'api_config.dart')
if os.path.exists(api_config_path):
    with open(api_config_path, 'r') as f:
        content = f.read()
    
    def repl_url(match):
        prefix = match.group(1)
        php_file = match.group(2)
        if php_file in api_map:
            folder = api_map[php_file]
            return f"{prefix}'$baseUrl/{folder}/{php_file}'"
        return match.group(0)

    # matches: static const String login = '$baseUrl/login.php';
    new_content = re.sub(r"(static\s+const\s+String\s+\w+\s*=\s*)'\$baseUrl/([^']+)'", repl_url, content)
    
    if new_content != content:
        with open(api_config_path, 'w') as f:
            f.write(new_content)

print("Refactoring complete!")
