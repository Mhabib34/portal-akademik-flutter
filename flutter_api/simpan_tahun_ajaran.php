<?php
// ============================================================
// simpan_tahun_ajaran.php — Tambah tahun ajaran baru (admin)
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

$nama     = trim($_POST['nama']     ?? '');
$semester = trim($_POST['semester'] ?? '');

if (empty($nama) || !in_array($semester, ['Ganjil', 'Genap'], true)) {
    echo json_encode(['status' => 'error', 'message' => 'nama wajib diisi dan semester harus Ganjil atau Genap']);
    exit();
}

$cek = $conn->prepare("SELECT id FROM tahun_ajaran WHERE nama = ? AND semester = ? LIMIT 1");
$cek->bind_param('ss', $nama, $semester);
$cek->execute();
$cek->store_result();
if ($cek->num_rows > 0) {
    echo json_encode(['status' => 'error', 'message' => 'Tahun ajaran + semester ini sudah ada']);
    $cek->close();
    $conn->close();
    exit();
}
$cek->close();

$stmt = $conn->prepare("INSERT INTO tahun_ajaran (nama, semester, is_aktif) VALUES (?, ?, 0)");
$stmt->bind_param('ss', $nama, $semester);
$stmt->execute();

echo json_encode([
    'status'  => 'ok',
    'message' => 'Tahun ajaran berhasil ditambahkan',
    'id'      => (string)$conn->insert_id
]);

$stmt->close();
$conn->close();
