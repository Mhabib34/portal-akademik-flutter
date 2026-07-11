<?php
// ============================================================
// get_fakultas.php — Ambil daftar fakultas
//   Bisa diakses admin, dosen, mahasiswa untuk referensi dropdown
// ============================================================

require_once 'koneksi.php';
require_once 'auth_helper.php';

if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    http_response_code(405);
    echo json_encode(['status' => 'error', 'message' => 'Method tidak diizinkan']);
    exit();
}

requireAuth($conn); // Login diperlukan

$sql = "SELECT id, nama_fakultas FROM fakultas ORDER BY nama_fakultas ASC";
$result = $conn->query($sql);

if (!$result) {
    echo json_encode(['status' => 'error', 'message' => 'Query gagal: ' . $conn->error]);
    $conn->close();
    exit();
}

$data = [];
while ($row = $result->fetch_assoc()) {
    $data[] = [
        'id'            => (string)$row['id'],
        'nama_fakultas' => $row['nama_fakultas']
    ];
}

echo json_encode(['status' => 'ok', 'data' => $data, 'total' => count($data)]);

$conn->close();
