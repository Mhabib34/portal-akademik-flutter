<?php
// ============================================================
// toggle_aktif.php — Toggle is_active akun user (admin)
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

$userId = trim($_POST['user_id'] ?? '');

if (empty($userId)) {
    echo json_encode(['status' => 'error', 'message' => 'user_id wajib diisi']);
    exit();
}

$cek = $conn->prepare("SELECT is_active FROM users WHERE id = ? LIMIT 1");
$cek->bind_param('i', $userId);
$cek->execute();
$result = $cek->get_result();

if ($result->num_rows === 0) {
    echo json_encode(['status' => 'error', 'message' => 'User tidak ditemukan']);
    $cek->close();
    $conn->close();
    exit();
}

$row      = $result->fetch_assoc();
$isActive = (int)$row['is_active'];
$cek->close();

$newStatus = $isActive === 1 ? 0 : 1;
$label     = $newStatus === 1 ? 'diaktifkan' : 'dinonaktifkan';

$stmt = $conn->prepare("UPDATE users SET is_active = ? WHERE id = ?");
$stmt->bind_param('ii', $newStatus, $userId);
$stmt->execute();

if ($stmt->affected_rows > 0) {
    echo json_encode([
        'status'    => 'ok',
        'message'   => "Akun berhasil $label",
        'is_active' => $newStatus
    ]);
} else {
    echo json_encode(['status' => 'error', 'message' => 'Gagal mengubah status akun']);
}

// Kalau dinonaktifkan, langsung hapus semua token aktif user tsb
if ($newStatus === 0) {
    $delToken = $conn->prepare("DELETE FROM auth_tokens WHERE user_id = ?");
    $delToken->bind_param('i', $userId);
    $delToken->execute();
    $delToken->close();
}

$stmt->close();
$conn->close();
