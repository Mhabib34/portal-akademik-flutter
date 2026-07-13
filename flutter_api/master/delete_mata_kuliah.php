<?php
// ============================================================
// delete_mata_kuliah.php — Hapus mata kuliah (admin)
//   Akan gagal (FK constraint) kalau masih punya kelas terkait —
//   sengaja dibiarkan begitu supaya data kelas/nilai historis aman
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

$id = trim($_POST['id'] ?? '');

if (empty($id)) {
    echo json_encode(['status' => 'error', 'message' => 'ID mata kuliah wajib diisi']);
    exit();
}

$cekKelas = $conn->prepare("SELECT id FROM kelas WHERE mata_kuliah_id = ? LIMIT 1");
$cekKelas->bind_param('i', $id);
$cekKelas->execute();
$cekKelas->store_result();
if ($cekKelas->num_rows > 0) {
    echo json_encode(['status' => 'error', 'message' => 'Mata kuliah masih memiliki kelas terdaftar, hapus kelas tersebut terlebih dahulu']);
    $cekKelas->close();
    $conn->close();
    exit();
}
$cekKelas->close();

$stmt = $conn->prepare("DELETE FROM mata_kuliah WHERE id = ?");
$stmt->bind_param('i', $id);
$stmt->execute();

if ($stmt->affected_rows > 0) {
    echo json_encode(['status' => 'ok', 'message' => 'Mata kuliah berhasil dihapus']);
} else {
    echo json_encode(['status' => 'error', 'message' => 'Mata kuliah tidak ditemukan']);
}

$stmt->close();
$conn->close();
