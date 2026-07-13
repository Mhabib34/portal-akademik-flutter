<?php
// ============================================================
// delete_ruang.php — Hapus ruang (admin)
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
    echo json_encode(['status' => 'error', 'message' => 'ID ruang wajib diisi']);
    exit();
}

$cekJadwal = $conn->prepare("SELECT id FROM jadwal WHERE ruang_id = ? LIMIT 1");
$cekJadwal->bind_param('i', $id);
$cekJadwal->execute();
$cekJadwal->store_result();
if ($cekJadwal->num_rows > 0) {
    echo json_encode(['status' => 'error', 'message' => 'Ruang masih dipakai di jadwal, hapus jadwal tersebut terlebih dahulu']);
    $cekJadwal->close();
    $conn->close();
    exit();
}
$cekJadwal->close();

$stmt = $conn->prepare("DELETE FROM ruang WHERE id = ?");
$stmt->bind_param('i', $id);
$stmt->execute();

if ($stmt->affected_rows > 0) {
    echo json_encode(['status' => 'ok', 'message' => 'Ruang berhasil dihapus']);
} else {
    echo json_encode(['status' => 'error', 'message' => 'Ruang tidak ditemukan']);
}

$stmt->close();
$conn->close();
