<?php
// ============================================================
// update_prodi.php — Update data prodi
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

$id         = trim($_POST['id'] ?? '');
$fakultasId = trim($_POST['fakultas_id'] ?? '');
$namaProdi  = trim($_POST['nama_prodi'] ?? '');

if (empty($id) || empty($fakultasId) || empty($namaProdi)) {
    echo json_encode(['status' => 'error', 'message' => 'ID, fakultas ID, dan nama prodi wajib diisi']);
    exit();
}

$stmt = $conn->prepare("UPDATE prodi SET fakultas_id = ?, nama_prodi = ? WHERE id = ?");
$stmt->bind_param('isi', $fakultasId, $namaProdi, $id);

if ($stmt->execute()) {
    if ($stmt->affected_rows > 0) {
        echo json_encode(['status' => 'ok', 'message' => 'Prodi berhasil diupdate']);
    } else {
        echo json_encode(['status' => 'error', 'message' => 'Prodi tidak ditemukan atau tidak ada perubahan']);
    }
} else {
    echo json_encode(['status' => 'error', 'message' => 'Gagal mengupdate prodi: ' . $stmt->error]);
}

$stmt->close();
$conn->close();
