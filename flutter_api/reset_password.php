<?php
// ============================================================
// reset_password.php — Admin reset password mahasiswa ke NIM
//   Set must_change_password = 1
// ============================================================

require_once 'koneksi.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode(['status' => 'error', 'message' => 'Method tidak diizinkan']);
    exit();
}

$userId = trim($_POST['user_id'] ?? '');

if (empty($userId)) {
    echo json_encode(['status' => 'error', 'message' => 'user_id wajib diisi']);
    exit();
}

// Ambil NIM mahasiswa berdasarkan user_id
$cek = $conn->prepare(
    "SELECT m.nim FROM mahasiswa m WHERE m.user_id = ? LIMIT 1"
);
$cek->bind_param('i', $userId);
$cek->execute();
$result = $cek->get_result();

if ($result->num_rows === 0) {
    echo json_encode(['status' => 'error', 'message' => 'Data mahasiswa tidak ditemukan untuk user_id ini']);
    $cek->close();
    $conn->close();
    exit();
}

$row = $result->fetch_assoc();
$nim = $row['nim'];
$cek->close();

// Reset password = NIM, must_change_password = 1
$stmt = $conn->prepare(
    "UPDATE users SET password = ?, must_change_password = 1 WHERE id = ?"
);
$stmt->bind_param('si', $nim, $userId);
$stmt->execute();

if ($stmt->affected_rows >= 0) {
    echo json_encode([
        'status'  => 'ok',
        'message' => 'Password berhasil direset ke NIM. Mahasiswa harus ganti password saat login berikutnya.'
    ]);
} else {
    echo json_encode([
        'status'  => 'error',
        'message' => 'Gagal mereset password'
    ]);
}

$stmt->close();
$conn->close();