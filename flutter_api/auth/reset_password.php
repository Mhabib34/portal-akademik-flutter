<?php
// ============================================================
// reset_password.php — Admin reset password mahasiswa/dosen
//   Mahasiswa -> reset ke NIM, Dosen -> reset ke NIDN
//   Set must_change_password = 1
// ============================================================

require_once '../config/koneksi.php';
require_once './auth_helper.php';

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

// Cek dulu apakah target user itu mahasiswa
$cekMhs = $conn->prepare("SELECT nim FROM mahasiswa WHERE user_id = ? LIMIT 1");
$cekMhs->bind_param('i', $userId);
$cekMhs->execute();
$resMhs = $cekMhs->get_result();

$passwordBaru = null;

if ($resMhs->num_rows > 0) {
    $passwordBaru = $resMhs->fetch_assoc()['nim'];
}
$cekMhs->close();

// Kalau bukan mahasiswa, cek apakah dosen
if ($passwordBaru === null) {
    $cekDosen = $conn->prepare("SELECT nidn FROM dosen WHERE user_id = ? LIMIT 1");
    $cekDosen->bind_param('i', $userId);
    $cekDosen->execute();
    $resDosen = $cekDosen->get_result();
    if ($resDosen->num_rows > 0) {
        $passwordBaru = $resDosen->fetch_assoc()['nidn'];
    }
    $cekDosen->close();
}

if ($passwordBaru === null) {
    echo json_encode(['status' => 'error', 'message' => 'User ini bukan mahasiswa atau dosen, tidak bisa direset otomatis']);
    $conn->close();
    exit();
}

$stmt = $conn->prepare(
    "UPDATE users SET password = ?, must_change_password = 1 WHERE id = ?"
);
$stmt->bind_param('si', $passwordBaru, $userId);
$stmt->execute();

if ($stmt->affected_rows >= 0) {
    echo json_encode([
        'status'  => 'ok',
        'message' => 'Password berhasil direset. User harus ganti password saat login berikutnya.'
    ]);
} else {
    echo json_encode(['status' => 'error', 'message' => 'Gagal mereset password']);
}

$stmt->close();
$conn->close();
