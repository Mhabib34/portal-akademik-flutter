<?php
// ============================================================
// simpan_kelas.php — Buka kelas baru untuk mata kuliah tertentu (admin)
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

$mataKuliahId  = trim($_POST['mata_kuliah_id']  ?? '');
$tahunAjaranId = trim($_POST['tahun_ajaran_id'] ?? '');
$dosenId       = trim($_POST['dosen_id']        ?? '');
$namaKelas     = trim($_POST['nama_kelas']      ?? 'A');
$kapasitas     = trim($_POST['kapasitas']       ?? '40');

if (empty($mataKuliahId) || empty($tahunAjaranId) || empty($dosenId)) {
    echo json_encode(['status' => 'error', 'message' => 'mata_kuliah_id, tahun_ajaran_id, dan dosen_id wajib diisi']);
    exit();
}

$cek = $conn->prepare(
    "SELECT id FROM kelas WHERE mata_kuliah_id = ? AND tahun_ajaran_id = ? AND nama_kelas = ? LIMIT 1"
);
$cek->bind_param('iis', $mataKuliahId, $tahunAjaranId, $namaKelas);
$cek->execute();
$cek->store_result();
if ($cek->num_rows > 0) {
    echo json_encode(['status' => 'error', 'message' => 'Kelas dengan nama ini sudah ada untuk mata kuliah & tahun ajaran tersebut']);
    $cek->close();
    $conn->close();
    exit();
}
$cek->close();

$stmt = $conn->prepare(
    "INSERT INTO kelas (mata_kuliah_id, tahun_ajaran_id, dosen_id, nama_kelas, kapasitas)
     VALUES (?, ?, ?, ?, ?)"
);
$stmt->bind_param('iiisi', $mataKuliahId, $tahunAjaranId, $dosenId, $namaKelas, $kapasitas);
$stmt->execute();

echo json_encode([
    'status'  => 'ok',
    'message' => 'Kelas berhasil dibuat',
    'id'      => (string)$conn->insert_id
]);

$stmt->close();
$conn->close();
