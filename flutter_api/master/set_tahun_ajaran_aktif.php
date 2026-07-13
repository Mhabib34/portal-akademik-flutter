<?php
// ============================================================
// set_tahun_ajaran_aktif.php — Set 1 tahun ajaran jadi aktif (admin)
//   Otomatis nonaktifkan semua tahun ajaran lain
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
    echo json_encode(['status' => 'error', 'message' => 'id wajib diisi']);
    exit();
}

$cek = $conn->prepare("SELECT id FROM tahun_ajaran WHERE id = ? LIMIT 1");
$cek->bind_param('i', $id);
$cek->execute();
$cek->store_result();
if ($cek->num_rows === 0) {
    echo json_encode(['status' => 'error', 'message' => 'Tahun ajaran tidak ditemukan']);
    $cek->close();
    $conn->close();
    exit();
}
$cek->close();

$conn->begin_transaction();

try {
    $conn->query("UPDATE tahun_ajaran SET is_aktif = 0");

    $stmt = $conn->prepare("UPDATE tahun_ajaran SET is_aktif = 1 WHERE id = ?");
    $stmt->bind_param('i', $id);
    $stmt->execute();
    $stmt->close();

    $conn->commit();

    echo json_encode(['status' => 'ok', 'message' => 'Tahun ajaran aktif berhasil diubah']);

} catch (Exception $e) {
    $conn->rollback();
    echo json_encode(['status' => 'error', 'message' => 'Gagal mengubah tahun ajaran aktif: ' . $e->getMessage()]);
}

$conn->close();
