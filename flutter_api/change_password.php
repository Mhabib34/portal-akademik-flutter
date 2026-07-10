<?php
// ============================================================
// change_password.php — Ganti password user
//   Set must_change_password = 0 setelah berhasil
// ============================================================

require_once 'koneksi.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode(['status' => 'error', 'message' => 'Method tidak diizinkan']);
    exit();
}

$userId      = trim($_POST['user_id']      ?? '');
$passwordBaru = trim($_POST['password_baru'] ?? '');

// Validasi
if (empty($userId) || empty($passwordBaru)) {
    echo json_encode(['status' => 'error', 'message' => 'user_id dan password_baru wajib diisi']);
    exit();
}

if (strlen($passwordBaru) < 6) {
    echo json_encode(['status' => 'error', 'message' => 'Password minimal 6 karakter']);
    exit();
}

// Cek user ada
$cek = $conn->prepare("SELECT id FROM users WHERE id = ? LIMIT 1");
$cek->bind_param('i', $userId);
$cek->execute();
$cek->store_result();
if ($cek->num_rows === 0) {
    echo json_encode(['status' => 'error', 'message' => 'User tidak ditemukan']);
    $cek->close();
    $conn->close();
    exit();
}
$cek->close();

// Update password dan set must_change_password = 0
$stmt = $conn->prepare(
    "UPDATE users SET password = ?, must_change_password = 0 WHERE id = ?"
);
$stmt->bind_param('si', $passwordBaru, $userId);
$stmt->execute();

if ($stmt->affected_rows > 0) {
    echo json_encode([
        'status'  => 'ok',
        'message' => 'Password berhasil diubah'
    ]);
} else {
    echo json_encode([
        'status'  => 'error',
        'message' => 'Gagal mengubah password atau tidak ada perubahan'
    ]);
}

$stmt->close();
$conn->close();