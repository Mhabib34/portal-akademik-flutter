<?php
// ============================================================
// delete_kelas.php — Hapus kelas (admin)
//   Ditolak kalau sudah ada mahasiswa yang KRS di kelas ini,
//   supaya data KRS/nilai historis tidak hilang tiba-tiba
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

$id = trim($_POST['id'] ?? '');

if (empty($id)) {
    echo json_encode(['status' => 'error', 'message' => 'ID kelas wajib diisi']);
    exit();
}

$cekKrs = $conn->prepare("SELECT id FROM krs_detail WHERE kelas_id = ? LIMIT 1");
$cekKrs->bind_param('i', $id);
$cekKrs->execute();
$cekKrs->store_result();
if ($cekKrs->num_rows > 0) {
    echo json_encode(['status' => 'error', 'message' => 'Kelas sudah punya mahasiswa yang KRS, tidak bisa dihapus']);
    $cekKrs->close();
    $conn->close();
    exit();
}
$cekKrs->close();

$stmt = $conn->prepare("DELETE FROM kelas WHERE id = ?");
$stmt->bind_param('i', $id);
$stmt->execute();

if ($stmt->affected_rows > 0) {
    echo json_encode(['status' => 'ok', 'message' => 'Kelas berhasil dihapus']);
} else {
    echo json_encode(['status' => 'error', 'message' => 'Kelas tidak ditemukan']);
}

$stmt->close();
$conn->close();
