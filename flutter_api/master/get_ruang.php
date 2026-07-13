<?php
// ============================================================
// get_ruang.php — Ambil daftar ruang
// ============================================================

require_once '../config/koneksi.php';
require_once '../auth/auth_helper.php';

if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    http_response_code(405);
    echo json_encode(['status' => 'error', 'message' => 'Method tidak diizinkan']);
    exit();
}

requireAuth($conn);

$result = $conn->query("SELECT id, nama_ruang, gedung, kapasitas FROM ruang ORDER BY nama_ruang ASC");

$data = [];
while ($row = $result->fetch_assoc()) {
    $data[] = [
        'id'         => (string)$row['id'],
        'nama_ruang' => $row['nama_ruang'],
        'gedung'     => $row['gedung'] ?? '',
        'kapasitas'  => (int)$row['kapasitas']
    ];
}

echo json_encode(['status' => 'ok', 'data' => $data, 'total' => count($data)]);

$conn->close();
