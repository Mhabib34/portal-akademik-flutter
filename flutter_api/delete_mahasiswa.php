<?php
// ============================================================
// delete_mahasiswa.php — Hapus mahasiswa + akun user
// ============================================================

require_once 'koneksi.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode(['status' => 'error', 'message' => 'Method tidak diizinkan']);
    exit();
}

$id = trim($_POST['id'] ?? '');

if (empty($id)) {
    echo json_encode(['status' => 'error', 'message' => 'ID mahasiswa wajib diisi']);
    exit();
}

// Ambil user_id sebelum hapus
$cek = $conn->prepare("SELECT user_id FROM mahasiswa WHERE id = ? LIMIT 1");
$cek->bind_param('i', $id);
$cek->execute();
$result = $cek->get_result();

if ($result->num_rows === 0) {
    echo json_encode(['status' => 'error', 'message' => 'Data mahasiswa tidak ditemukan']);
    $cek->close();
    $conn->close();
    exit();
}

$row    = $result->fetch_assoc();
$userId = $row['user_id'];
$cek->close();

// Mulai transaksi
$conn->begin_transaction();

try {
    // Hapus mahasiswa terlebih dahulu (karena ada FK ke users)
    $stmtMhs = $conn->prepare("DELETE FROM mahasiswa WHERE id = ?");
    $stmtMhs->bind_param('i', $id);
    $stmtMhs->execute();
    $stmtMhs->close();

    // Hapus akun user (CASCADE sudah diset, tapi kita hapus manual untuk kejelasan)
    $stmtUser = $conn->prepare("DELETE FROM users WHERE id = ?");
    $stmtUser->bind_param('i', $userId);
    $stmtUser->execute();
    $stmtUser->close();

    $conn->commit();

    echo json_encode([
        'status'  => 'ok',
        'message' => 'Data mahasiswa dan akun berhasil dihapus'
    ]);

} catch (Exception $e) {
    $conn->rollback();
    echo json_encode(['status' => 'error', 'message' => 'Gagal menghapus data: ' . $e->getMessage()]);
}

$conn->close();