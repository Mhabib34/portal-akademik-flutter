<?php
// ============================================================
// change_password.php — Ganti password akun sendiri
//   user_id diambil dari token (bukan dari body request lagi)
//   Set must_change_password = 0 setelah berhasil
// ============================================================

require_once 'koneksi.php';
require_once 'auth_helper.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode(['status' => 'error', 'message' => 'Method tidak diizinkan']);
    exit();
}

$user = requireAuth($conn);

$passwordBaru = trim($_POST['password_baru'] ?? '');

if (empty($passwordBaru)) {
    echo json_encode(['status' => 'error', 'message' => 'password_baru wajib diisi']);
    exit();
}

if (strlen($passwordBaru) < 6) {
    echo json_encode(['status' => 'error', 'message' => 'Password minimal 6 karakter']);
    exit();
}

$stmt = $conn->prepare(
    "UPDATE users SET password = ?, must_change_password = 0 WHERE id = ?"
);
$stmt->bind_param('si', $passwordBaru, $user['id']);
$stmt->execute();

if ($stmt->affected_rows > 0) {
    echo json_encode(['status' => 'ok', 'message' => 'Password berhasil diubah']);
} else {
    echo json_encode(['status' => 'ok', 'message' => 'Password berhasil diubah (tidak ada perubahan nilai)']);
}

$stmt->close();
$conn->close();
