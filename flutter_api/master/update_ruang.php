<?php
// ============================================================
// update_ruang.php — Update ruang (admin)
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

$id        = trim($_POST['id']         ?? '');
$namaRuang = trim($_POST['nama_ruang'] ?? '');
$gedung    = trim($_POST['gedung']     ?? '');
$kapasitas = trim($_POST['kapasitas']  ?? '');

if (empty($id) || empty($namaRuang)) {
    echo json_encode(['status' => 'error', 'message' => 'id dan nama_ruang wajib diisi']);
    exit();
}

$cekDup = $conn->prepare("SELECT id FROM ruang WHERE nama_ruang = ? AND id != ? LIMIT 1");
$cekDup->bind_param('si', $namaRuang, $id);
$cekDup->execute();
$cekDup->store_result();
if ($cekDup->num_rows > 0) {
    echo json_encode(['status' => 'error', 'message' => 'Nama ruang sudah dipakai ruang lain']);
    $cekDup->close();
    $conn->close();
    exit();
}
$cekDup->close();

$stmt = $conn->prepare("UPDATE ruang SET nama_ruang = ?, gedung = ?, kapasitas = ? WHERE id = ?");
$stmt->bind_param('ssii', $namaRuang, $gedung, $kapasitas, $id);
$stmt->execute();

echo json_encode(['status' => 'ok', 'message' => 'Ruang berhasil diperbarui']);

$stmt->close();
$conn->close();
