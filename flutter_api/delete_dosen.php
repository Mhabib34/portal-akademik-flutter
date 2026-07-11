<?php
// ============================================================
// delete_dosen.php — Hapus dosen + akun user (admin only)
//   Ditolak kalau dosen masih mengampu kelas aktif, supaya data
//   kelas/jadwal/nilai historis tidak yatim (orphan FK RESTRICT)
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
    echo json_encode(['status' => 'error', 'message' => 'ID dosen wajib diisi']);
    exit();
}

$cek = $conn->prepare("SELECT user_id FROM dosen WHERE id = ? LIMIT 1");
$cek->bind_param('i', $id);
$cek->execute();
$result = $cek->get_result();

if ($result->num_rows === 0) {
    echo json_encode(['status' => 'error', 'message' => 'Data dosen tidak ditemukan']);
    $cek->close();
    $conn->close();
    exit();
}

$row    = $result->fetch_assoc();
$userId = $row['user_id'];
$cek->close();

$conn->begin_transaction();

try {
    $stmtDosen = $conn->prepare("DELETE FROM dosen WHERE id = ?");
    $stmtDosen->bind_param('i', $id);
    $stmtDosen->execute();

    if ($stmtDosen->errno) {
        throw new Exception('Dosen masih mengampu kelas aktif, tidak bisa dihapus');
    }
    $stmtDosen->close();

    $stmtUser = $conn->prepare("DELETE FROM users WHERE id = ?");
    $stmtUser->bind_param('i', $userId);
    $stmtUser->execute();
    $stmtUser->close();

    $conn->commit();

    echo json_encode(['status' => 'ok', 'message' => 'Data dosen dan akun berhasil dihapus']);

} catch (Exception $e) {
    $conn->rollback();
    echo json_encode(['status' => 'error', 'message' => 'Gagal menghapus data: ' . $e->getMessage()]);
}

$conn->close();
