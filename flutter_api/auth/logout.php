<?php
// ============================================================
// logout.php — Invalidasi token yang sedang dipakai
// ============================================================

require_once '../config/koneksi.php';
require_once './auth_helper.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode(['status' => 'error', 'message' => 'Method tidak diizinkan']);
    exit();
}

$user = requireAuth($conn);

$stmt = $conn->prepare("DELETE FROM auth_tokens WHERE token = ?");
$stmt->bind_param('s', $user['token']);
$stmt->execute();
$stmt->close();

echo json_encode(['status' => 'ok', 'message' => 'Logout berhasil']);

$conn->close();
