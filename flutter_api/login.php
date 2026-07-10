<?php
// ============================================================
// login.php — Autentikasi user (admin & mahasiswa)
// ============================================================

require_once 'koneksi.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode(['status' => 'error', 'message' => 'Method tidak diizinkan']);
    exit();
}

$username = trim($_POST['username'] ?? '');
$password = trim($_POST['password'] ?? '');

// Validasi input
if (empty($username) || empty($password)) {
    echo json_encode(['status' => 'error', 'message' => 'Username dan password wajib diisi']);
    exit();
}

// Cari user berdasarkan username
$stmt = $conn->prepare(
    "SELECT u.id, u.nama, u.username, u.password, u.role,
            u.must_change_password, u.is_active,
            m.nim
     FROM users u
     LEFT JOIN mahasiswa m ON m.user_id = u.id
     WHERE u.username = ?
     LIMIT 1"
);
$stmt->bind_param('s', $username);
$stmt->execute();
$result = $stmt->get_result();

if ($result->num_rows === 0) {
    echo json_encode(['status' => 'error', 'message' => 'Username atau password salah']);
    $stmt->close();
    $conn->close();
    exit();
}

$user = $result->fetch_assoc();
$stmt->close();

// Cek password (plain text sesuai spesifikasi)
if ($user['password'] !== $password) {
    echo json_encode(['status' => 'error', 'message' => 'Username atau password salah']);
    $conn->close();
    exit();
}

// Cek status akun
if ((int)$user['is_active'] === 0) {
    echo json_encode(['status' => 'error', 'message' => 'Akun Anda dinonaktifkan. Hubungi administrator.']);
    $conn->close();
    exit();
}

// Berhasil login
echo json_encode([
    'status'               => 'ok',
    'message'              => 'Login berhasil',
    'id'                   => (string)$user['id'],
    'nama'                 => $user['nama'],
    'username'             => $user['username'],
    'role'                 => $user['role'],
    'nim'                  => $user['nim'] ?? '',
    'must_change_password' => (int)$user['must_change_password'],
    'is_active'            => (int)$user['is_active']
]);

$conn->close();