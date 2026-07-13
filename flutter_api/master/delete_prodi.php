<?php
// ============================================================
// delete_prodi.php — Hapus prodi
//   Hanya admin yang bisa akses
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
    echo json_encode(['status' => 'error', 'message' => 'ID wajib diisi']);
    exit();
}

$stmt = $conn->prepare("DELETE FROM prodi WHERE id = ?");
$stmt->bind_param('i', $id);

if ($stmt->execute()) {
    if ($stmt->affected_rows > 0) {
        echo json_encode(['status' => 'ok', 'message' => 'Prodi berhasil dihapus']);
    } else {
        echo json_encode(['status' => 'error', 'message' => 'Prodi tidak ditemukan']);
    }
} else {
    echo json_encode(['status' => 'error', 'message' => 'Gagal menghapus prodi: ' . $stmt->error]);
}

$stmt->close();
$conn->close();
