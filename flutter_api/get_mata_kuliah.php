<?php
// ============================================================
// get_mata_kuliah.php — Ambil daftar mata kuliah
//   Bisa diakses semua role yang sudah login (admin/dosen/user)
//   Filter opsional: jurusan, semester_ke
// ============================================================

require_once 'koneksi.php';
require_once 'auth_helper.php';

if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    http_response_code(405);
    echo json_encode(['status' => 'error', 'message' => 'Method tidak diizinkan']);
    exit();
}

requireAuth($conn);

$jurusan    = trim($_GET['jurusan']     ?? '');
$semesterKe = trim($_GET['semester_ke'] ?? '');

$sql = "SELECT id, kode_mk, nama_mk, sks, jurusan, semester_ke, deskripsi FROM mata_kuliah WHERE 1=1";
$params = [];
$types  = '';

if (!empty($jurusan)) {
    $sql .= " AND jurusan = ?";
    $params[] = $jurusan;
    $types   .= 's';
}
if (!empty($semesterKe)) {
    $sql .= " AND semester_ke = ?";
    $params[] = $semesterKe;
    $types   .= 'i';
}
$sql .= " ORDER BY semester_ke ASC, nama_mk ASC";

$stmt = $conn->prepare($sql);
if (!empty($params)) {
    $stmt->bind_param($types, ...$params);
}
$stmt->execute();
$result = $stmt->get_result();

$data = [];
while ($row = $result->fetch_assoc()) {
    $data[] = [
        'id'          => (string)$row['id'],
        'kode_mk'     => $row['kode_mk'],
        'nama_mk'     => $row['nama_mk'],
        'sks'         => (int)$row['sks'],
        'jurusan'     => $row['jurusan'],
        'semester_ke' => (int)$row['semester_ke'],
        'deskripsi'   => $row['deskripsi'] ?? ''
    ];
}

echo json_encode(['status' => 'ok', 'data' => $data, 'total' => count($data)]);

$stmt->close();
$conn->close();
