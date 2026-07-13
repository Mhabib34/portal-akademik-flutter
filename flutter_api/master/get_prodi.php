<?php
// ============================================================
// get_prodi.php — Ambil daftar prodi
//   Bisa diakses admin, dosen, mahasiswa untuk referensi dropdown
//   Filter opsional: fakultas_id
// ============================================================

require_once '../config/koneksi.php';
require_once '../auth/auth_helper.php';

if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    http_response_code(405);
    echo json_encode(['status' => 'error', 'message' => 'Method tidak diizinkan']);
    exit();
}

requireAuth($conn);

$fakultasId = trim($_GET['fakultas_id'] ?? '');

$sql = "SELECT p.id, p.fakultas_id, p.nama_prodi, f.nama_fakultas 
        FROM prodi p 
        JOIN fakultas f ON f.id = p.fakultas_id 
        WHERE 1=1";
$params = [];
$types  = '';

if (!empty($fakultasId)) {
    $sql .= " AND p.fakultas_id = ?";
    $params[] = $fakultasId;
    $types   .= 'i';
}
$sql .= " ORDER BY f.nama_fakultas ASC, p.nama_prodi ASC";

$stmt = $conn->prepare($sql);
if (!empty($params)) {
    $stmt->bind_param($types, ...$params);
}
$stmt->execute();
$result = $stmt->get_result();

$data = [];
while ($row = $result->fetch_assoc()) {
    $data[] = [
        'id'            => (string)$row['id'],
        'fakultas_id'   => (string)$row['fakultas_id'],
        'nama_prodi'    => $row['nama_prodi'],
        'nama_fakultas' => $row['nama_fakultas']
    ];
}

echo json_encode(['status' => 'ok', 'data' => $data, 'total' => count($data)]);

$stmt->close();
$conn->close();
