<?php
// ============================================================
// delete_fakultas.php — Hapus fakultas
//   Hanya admin yang bisa akses
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
    echo json_encode(['status' => 'error', 'message' => 'ID wajib diisi']);
    exit();
}

$stmt = $conn->prepare("DELETE FROM fakultas WHERE id = ?");
$stmt->bind_param('i', $id);

if ($stmt->execute()) {
    if ($stmt->affected_rows > 0) {
        echo json_encode(['status' => 'ok', 'message' => 'Fakultas berhasil dihapus']);
    } else {
        echo json_encode(['status' => 'error', 'message' => 'Fakultas tidak ditemukan']);
    }
} else {
    echo json_encode(['status' => 'error', 'message' => 'Gagal menghapus fakultas: ' . $stmt->error]);
}

$stmt->close();
$conn->close();
