<?php
// ============================================================
// get_mata_kuliah.php — Ambil daftar mata kuliah
//   Bisa diakses semua role yang sudah login (admin/dosen/user)
//   Filter opsional: prodi_id, semester_ke
// ============================================================

require_once '../config/koneksi.php';
require_once '../auth/auth_helper.php';

if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    http_response_code(405);
    echo json_encode(['status' => 'error', 'message' => 'Method tidak diizinkan']);
    exit();
}

requireAuth($conn);

$prodiId    = trim($_GET['prodi_id']    ?? '');
$semesterKe = trim($_GET['semester_ke'] ?? '');

$sql = "SELECT mk.id, mk.kode_mk, mk.nama_mk, mk.sks, mk.prodi_id, p.nama_prodi, f.nama_fakultas, mk.semester_ke, mk.deskripsi 
        FROM mata_kuliah mk
        LEFT JOIN prodi p ON p.id = mk.prodi_id
        LEFT JOIN fakultas f ON f.id = p.fakultas_id
        WHERE 1=1";
$params = [];
$types  = '';

if (!empty($prodiId)) {
    $sql .= " AND mk.prodi_id = ?";
    $params[] = $prodiId;
    $types   .= 'i';
}
if (!empty($semesterKe)) {
    $sql .= " AND mk.semester_ke = ?";
    $params[] = $semesterKe;
    $types   .= 'i';
}
$sql .= " ORDER BY mk.semester_ke ASC, mk.nama_mk ASC";

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
        'kode_mk'       => $row['kode_mk'],
        'nama_mk'       => $row['nama_mk'],
        'sks'           => (int)$row['sks'],
        'prodi_id'      => $row['prodi_id'] !== null ? (string)$row['prodi_id'] : null,
        'nama_prodi'    => $row['nama_prodi'] ?? '',
        'nama_fakultas' => $row['nama_fakultas'] ?? '',
        'semester_ke'   => (int)$row['semester_ke'],
        'deskripsi'     => $row['deskripsi'] ?? ''
    ];
}

echo json_encode(['status' => 'ok', 'data' => $data, 'total' => count($data)]);

$stmt->close();
$conn->close();
