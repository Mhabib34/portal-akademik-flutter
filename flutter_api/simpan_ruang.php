<?php
// ============================================================
// simpan_ruang.php — Tambah ruang baru (admin)
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

$namaRuang = trim($_POST['nama_ruang'] ?? '');
$gedung    = trim($_POST['gedung']     ?? '');
$kapasitas = trim($_POST['kapasitas']  ?? '40');

if (empty($namaRuang)) {
    echo json_encode(['status' => 'error', 'message' => 'nama_ruang wajib diisi']);
    exit();
}

$cek = $conn->prepare("SELECT id FROM ruang WHERE nama_ruang = ? LIMIT 1");
$cek->bind_param('s', $namaRuang);
$cek->execute();
$cek->store_result();
if ($cek->num_rows > 0) {
    echo json_encode(['status' => 'error', 'message' => 'Nama ruang sudah terdaftar']);
    $cek->close();
    $conn->close();
    exit();
}
$cek->close();

$stmt = $conn->prepare("INSERT INTO ruang (nama_ruang, gedung, kapasitas) VALUES (?, ?, ?)");
$stmt->bind_param('ssi', $namaRuang, $gedung, $kapasitas);
$stmt->execute();

echo json_encode([
    'status'  => 'ok',
    'message' => 'Ruang berhasil ditambahkan',
    'id'      => (string)$conn->insert_id
]);

$stmt->close();
$conn->close();
