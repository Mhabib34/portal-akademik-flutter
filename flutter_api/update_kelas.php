<?php
// ============================================================
// update_kelas.php — Update kelas (ganti dosen/nama_kelas/kapasitas) (admin)
// ============================================================

require_once 'koneksi.php';
require_once 'auth_helper.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode(['status' => 'error', 'message' => 'Method tidak diizinkan']);
    exit();
}

$currentUser = requireAuth($conn);
requireRole($currentUser, ['admin']);

$id        = trim($_POST['id']         ?? '');
$dosenId   = trim($_POST['dosen_id']   ?? '');
$namaKelas = trim($_POST['nama_kelas'] ?? '');
$kapasitas = trim($_POST['kapasitas']  ?? '');

if (empty($id)) {
    echo json_encode(['status' => 'error', 'message' => 'id wajib diisi']);
    exit();
}

$cek = $conn->prepare("SELECT id FROM kelas WHERE id = ? LIMIT 1");
$cek->bind_param('i', $id);
$cek->execute();
$cek->store_result();
if ($cek->num_rows === 0) {
    echo json_encode(['status' => 'error', 'message' => 'Kelas tidak ditemukan']);
    $cek->close();
    $conn->close();
    exit();
}
$cek->close();

$fields = [];
$params = [];
$types  = '';

if (!empty($dosenId)) {
    $fields[] = "dosen_id = ?";
    $params[] = $dosenId;
    $types   .= 'i';
}
if (!empty($namaKelas)) {
    $fields[] = "nama_kelas = ?";
    $params[] = $namaKelas;
    $types   .= 's';
}
if ($kapasitas !== '') {
    $fields[] = "kapasitas = ?";
    $params[] = $kapasitas;
    $types   .= 'i';
}

if (empty($fields)) {
    echo json_encode(['status' => 'error', 'message' => 'Tidak ada field yang diupdate']);
    exit();
}

$params[] = $id;
$types   .= 'i';

$sql  = "UPDATE kelas SET " . implode(', ', $fields) . " WHERE id = ?";
$stmt = $conn->prepare($sql);
$stmt->bind_param($types, ...$params);
$stmt->execute();

echo json_encode(['status' => 'ok', 'message' => 'Kelas berhasil diperbarui']);

$stmt->close();
$conn->close();
