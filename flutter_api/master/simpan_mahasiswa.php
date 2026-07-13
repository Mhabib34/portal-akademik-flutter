<?php
// ============================================================
// simpan_mahasiswa.php — Tambah mahasiswa + otomatis buat akun (admin)
// ============================================================

require_once '../config/koneksi.php';
require_once '../auth/auth_helper.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode(['status' => 'error', 'message' => 'Method tidak diizinkan']);
    exit();
}

$currentUser = requireAuth($conn);
requireRole($currentUser, ['admin']);

$nim     = trim($_POST['nim']     ?? '');
$nama    = trim($_POST['nama']    ?? '');
$prodiId = trim($_POST['prodi_id'] ?? '');
$alamat  = trim($_POST['alamat']  ?? '');

if (empty($nim) || empty($nama) || empty($prodiId)) {
    echo json_encode(['status' => 'error', 'message' => 'NIM, nama, dan prodi_id wajib diisi']);
    exit();
}

$cek = $conn->prepare("SELECT id FROM mahasiswa WHERE nim = ? LIMIT 1");
$cek->bind_param('s', $nim);
$cek->execute();
$cek->store_result();
if ($cek->num_rows > 0) {
    echo json_encode(['status' => 'error', 'message' => 'NIM sudah terdaftar']);
    $cek->close();
    $conn->close();
    exit();
}
$cek->close();

$cekUser = $conn->prepare("SELECT id FROM users WHERE username = ? LIMIT 1");
$cekUser->bind_param('s', $nim);
$cekUser->execute();
$cekUser->store_result();
if ($cekUser->num_rows > 0) {
    echo json_encode(['status' => 'error', 'message' => 'Username (NIM) sudah digunakan di akun lain']);
    $cekUser->close();
    $conn->close();
    exit();
}
$cekUser->close();

$conn->begin_transaction();

try {
    $stmtUser = $conn->prepare(
        "INSERT INTO users (nama, username, password, role, must_change_password, is_active)
         VALUES (?, ?, ?, 'user', 1, 1)"
    );
    $stmtUser->bind_param('sss', $nama, $nim, $nim);
    $stmtUser->execute();
    $userId = $conn->insert_id;
    $stmtUser->close();

    $stmtMhs = $conn->prepare(
        "INSERT INTO mahasiswa (nim, nama, prodi_id, alamat, user_id)
         VALUES (?, ?, ?, ?, ?)"
    );
    $stmtMhs->bind_param('ssisi', $nim, $nama, $prodiId, $alamat, $userId);
    $stmtMhs->execute();
    $mahasiswaId = $conn->insert_id;
    $stmtMhs->close();

    $conn->commit();

    echo json_encode([
        'status'       => 'ok',
        'message'      => 'Mahasiswa berhasil ditambahkan. Akun dibuat dengan username dan password = NIM.',
        'mahasiswa_id' => (string)$mahasiswaId,
        'user_id'      => (string)$userId
    ]);

} catch (Exception $e) {
    $conn->rollback();
    echo json_encode(['status' => 'error', 'message' => 'Gagal menyimpan data: ' . $e->getMessage()]);
}

$conn->close();
