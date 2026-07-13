<?php
// ============================================================
// simpan_dosen.php — Tambah dosen + otomatis buat akun (admin)
//   username & password akun = NIDN
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

$nidn  = trim($_POST['nidn']  ?? '');
$nama  = trim($_POST['nama']  ?? '');
$noHp  = trim($_POST['no_hp'] ?? '');

if (empty($nidn) || empty($nama)) {
    echo json_encode(['status' => 'error', 'message' => 'NIDN dan nama wajib diisi']);
    exit();
}

$cek = $conn->prepare("SELECT id FROM dosen WHERE nidn = ? LIMIT 1");
$cek->bind_param('s', $nidn);
$cek->execute();
$cek->store_result();
if ($cek->num_rows > 0) {
    echo json_encode(['status' => 'error', 'message' => 'NIDN sudah terdaftar']);
    $cek->close();
    $conn->close();
    exit();
}
$cek->close();

$cekUser = $conn->prepare("SELECT id FROM users WHERE username = ? LIMIT 1");
$cekUser->bind_param('s', $nidn);
$cekUser->execute();
$cekUser->store_result();
if ($cekUser->num_rows > 0) {
    echo json_encode(['status' => 'error', 'message' => 'Username (NIDN) sudah digunakan di akun lain']);
    $cekUser->close();
    $conn->close();
    exit();
}
$cekUser->close();

$conn->begin_transaction();

try {
    $stmtUser = $conn->prepare(
        "INSERT INTO users (nama, username, password, role, must_change_password, is_active)
         VALUES (?, ?, ?, 'dosen', 1, 1)"
    );
    $stmtUser->bind_param('sss', $nama, $nidn, $nidn);
    $stmtUser->execute();
    $userId = $conn->insert_id;
    $stmtUser->close();

    $stmtDosen = $conn->prepare(
        "INSERT INTO dosen (nidn, nama, no_hp, user_id) VALUES (?, ?, ?, ?)"
    );
    $stmtDosen->bind_param('sssi', $nidn, $nama, $noHp, $userId);
    $stmtDosen->execute();
    $dosenId = $conn->insert_id;
    $stmtDosen->close();

    $conn->commit();

    echo json_encode([
        'status'   => 'ok',
        'message'  => 'Dosen berhasil ditambahkan. Akun dibuat dengan username dan password = NIDN.',
        'dosen_id' => (string)$dosenId,
        'user_id'  => (string)$userId
    ]);

} catch (Exception $e) {
    $conn->rollback();
    echo json_encode(['status' => 'error', 'message' => 'Gagal menyimpan data: ' . $e->getMessage()]);
}

$conn->close();
