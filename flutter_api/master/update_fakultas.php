<?php
// ============================================================
// update_fakultas.php — Update data fakultas
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

$id           = trim($_POST['id'] ?? '');
$namaFakultas = trim($_POST['nama_fakultas'] ?? '');

if (empty($id) || empty($namaFakultas)) {
    echo json_encode(['status' => 'error', 'message' => 'ID dan nama fakultas wajib diisi']);
    exit();
}

$stmt = $conn->prepare("UPDATE fakultas SET nama_fakultas = ? WHERE id = ?");
$stmt->bind_param('si', $namaFakultas, $id);

if ($stmt->execute()) {
    if ($stmt->affected_rows > 0) {
        echo json_encode(['status' => 'ok', 'message' => 'Fakultas berhasil diupdate']);
    } else {
        echo json_encode(['status' => 'error', 'message' => 'Fakultas tidak ditemukan atau tidak ada perubahan']);
    }
} else {
    echo json_encode(['status' => 'error', 'message' => 'Gagal mengupdate fakultas: ' . $stmt->error]);
}

$stmt->close();
$conn->close();
