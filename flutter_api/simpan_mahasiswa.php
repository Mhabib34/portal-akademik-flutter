<?php
// ============================================================
// simpan_mahasiswa.php — Tambah mahasiswa + otomatis buat akun
// ============================================================

require_once 'koneksi.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode(['status' => 'error', 'message' => 'Method tidak diizinkan']);
    exit();
}

$nim     = trim($_POST['nim']     ?? '');
$nama    = trim($_POST['nama']    ?? '');
$jurusan = trim($_POST['jurusan'] ?? '');
$alamat  = trim($_POST['alamat']  ?? '');

// Validasi input
if (empty($nim) || empty($nama) || empty($jurusan)) {
    echo json_encode(['status' => 'error', 'message' => 'NIM, nama, dan jurusan wajib diisi']);
    exit();
}

// Cek duplikat NIM
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

// Cek duplikat username (username = NIM)
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

// Mulai transaksi
$conn->begin_transaction();

try {
    // 1. Insert ke tabel users (username = NIM, password = NIM)
    $stmtUser = $conn->prepare(
        "INSERT INTO users (nama, username, password, role, must_change_password, is_active)
         VALUES (?, ?, ?, 'user', 1, 1)"
    );
    $stmtUser->bind_param('sss', $nama, $nim, $nim);
    $stmtUser->execute();
    $userId = $conn->insert_id;
    $stmtUser->close();

    // 2. Insert ke tabel mahasiswa
    $stmtMhs = $conn->prepare(
        "INSERT INTO mahasiswa (nim, nama, jurusan, alamat, user_id)
         VALUES (?, ?, ?, ?, ?)"
    );
    $stmtMhs->bind_param('ssssi', $nim, $nama, $jurusan, $alamat, $userId);
    $stmtMhs->execute();
    $mahasiswaId = $conn->insert_id;
    $stmtMhs->close();

    $conn->commit();

    echo json_encode([
        'status'      => 'ok',
        'message'     => 'Mahasiswa berhasil ditambahkan. Akun dibuat dengan username dan password = NIM.',
        'mahasiswa_id' => (string)$mahasiswaId,
        'user_id'     => (string)$userId
    ]);

} catch (Exception $e) {
    $conn->rollback();
    echo json_encode(['status' => 'error', 'message' => 'Gagal menyimpan data: ' . $e->getMessage()]);
}

$conn->close();