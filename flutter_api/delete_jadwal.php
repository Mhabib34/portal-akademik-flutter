<?php
// ============================================================
// delete_jadwal.php — Hapus jadwal (admin)
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
    echo json_encode(['status' => 'error', 'message' => 'ID jadwal wajib diisi']);
    exit();
}

$stmt = $conn->prepare("DELETE FROM jadwal WHERE id = ?");
$stmt->bind_param('i', $id);
$stmt->execute();

if ($stmt->affected_rows > 0) {
    echo json_encode(['status' => 'ok', 'message' => 'Jadwal berhasil dihapus']);
} else {
    echo json_encode(['status' => 'error', 'message' => 'Jadwal tidak ditemukan']);
}

$stmt->close();
$conn->close();
