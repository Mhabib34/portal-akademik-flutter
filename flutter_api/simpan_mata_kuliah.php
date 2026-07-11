<?php
// ============================================================
// simpan_mata_kuliah.php — Tambah mata kuliah baru (admin)
// ============================================================

require_once 'koneksi.php';
require_once 'auth_helper.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode(['status' => 'error', 'message' => 'Method tidak diizinkan']);
    exit();
}

$currentUser = requireAuth($conn);
requireRole($currentUser, ['admin']);

$kodeMk     = trim($_POST['kode_mk']     ?? '');
$namaMk     = trim($_POST['nama_mk']     ?? '');
$sks        = trim($_POST['sks']         ?? '');
$prodiId    = trim($_POST['prodi_id']    ?? '');
$semesterKe = trim($_POST['semester_ke'] ?? '');
$deskripsi  = trim($_POST['deskripsi']   ?? '');

if (empty($kodeMk) || empty($namaMk) || empty($sks) || empty($prodiId) || empty($semesterKe)) {
    echo json_encode(['status' => 'error', 'message' => 'kode_mk, nama_mk, sks, prodi_id, dan semester_ke wajib diisi']);
    exit();
}

$cek = $conn->prepare("SELECT id FROM mata_kuliah WHERE kode_mk = ? LIMIT 1");
$cek->bind_param('s', $kodeMk);
$cek->execute();
$cek->store_result();
if ($cek->num_rows > 0) {
    echo json_encode(['status' => 'error', 'message' => 'Kode mata kuliah sudah terdaftar']);
    $cek->close();
    $conn->close();
    exit();
}
$cek->close();

$stmt = $conn->prepare(
    "INSERT INTO mata_kuliah (kode_mk, nama_mk, sks, prodi_id, semester_ke, deskripsi)
     VALUES (?, ?, ?, ?, ?, ?)"
);
$stmt->bind_param('ssiiis', $kodeMk, $namaMk, $sks, $prodiId, $semesterKe, $deskripsi);
$stmt->execute();

if ($stmt->affected_rows > 0) {
    echo json_encode([
        'status'  => 'ok',
        'message' => 'Mata kuliah berhasil ditambahkan',
        'id'      => (string)$conn->insert_id
    ]);
} else {
    echo json_encode(['status' => 'error', 'message' => 'Gagal menambahkan mata kuliah']);
}

$stmt->close();
$conn->close();
