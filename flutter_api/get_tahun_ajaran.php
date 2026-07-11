<?php
// ============================================================
// get_tahun_ajaran.php — Ambil daftar tahun ajaran
// ============================================================

require_once 'koneksi.php';
require_once 'auth_helper.php';

if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    http_response_code(405);
    echo json_encode(['status' => 'error', 'message' => 'Method tidak diizinkan']);
    exit();
}

requireAuth($conn);

$result = $conn->query(
    "SELECT id, nama, semester, is_aktif FROM tahun_ajaran ORDER BY nama DESC, semester DESC"
);

$data = [];
while ($row = $result->fetch_assoc()) {
    $data[] = [
        'id'       => (string)$row['id'],
        'nama'     => $row['nama'],
        'semester' => $row['semester'],
        'is_aktif' => (int)$row['is_aktif']
    ];
}

echo json_encode(['status' => 'ok', 'data' => $data, 'total' => count($data)]);

$conn->close();
