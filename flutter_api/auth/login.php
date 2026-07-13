<?php
// ============================================================
// login.php — Autentikasi user (admin, dosen, mahasiswa)
//   Sekarang generate & simpan token di auth_tokens
// ============================================================

require_once '../config/koneksi.php';
require_once './auth_helper.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode(['status' => 'error', 'message' => 'Method tidak diizinkan']);
    exit();
}

$username = trim($_POST['username'] ?? '');
$password = trim($_POST['password'] ?? '');

if (empty($username) || empty($password)) {
    echo json_encode(['status' => 'error', 'message' => 'Username dan password wajib diisi']);
    exit();
}

// Cari user + info mahasiswa/dosen sekaligus
$stmt = $conn->prepare(
    "SELECT u.id, u.nama, u.username, u.password, u.role,
            u.must_change_password, u.is_active,
            m.nim, d.nidn
     FROM users u
     LEFT JOIN mahasiswa m ON m.user_id = u.id
     LEFT JOIN dosen d ON d.user_id = u.id
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

if ($user['password'] !== $password) {
    echo json_encode(['status' => 'error', 'message' => 'Username atau password salah']);
    $conn->close();
    exit();
}

if ((int)$user['is_active'] === 0) {
    echo json_encode(['status' => 'error', 'message' => 'Akun Anda dinonaktifkan. Hubungi administrator.']);
    $conn->close();
    exit();
}

// --- Generate token, berlaku 7 hari ---
$token     = generateToken();
$expiresAt = date('Y-m-d H:i:s', strtotime('+7 days'));

$stmtToken = $conn->prepare(
    "INSERT INTO auth_tokens (user_id, token, expires_at) VALUES (?, ?, ?)"
);
$stmtToken->bind_param('iss', $user['id'], $token, $expiresAt);
$stmtToken->execute();
$stmtToken->close();

echo json_encode([
    'status'  => 'ok',
    'message' => 'Login berhasil',
    'data'    => [
        'token'                 => $token,
        'expires_at'            => $expiresAt,
        'id'                    => (string)$user['id'],
        'nama'                  => $user['nama'],
        'username'              => $user['username'],
        'role'                  => $user['role'],
        'nim'                   => $user['nim'] ?? '',
        'nidn'                  => $user['nidn'] ?? '',
        'must_change_password'  => (int)$user['must_change_password'],
        'is_active'             => (int)$user['is_active']
    ]
]);

$conn->close();
