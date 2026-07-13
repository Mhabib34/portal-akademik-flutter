<?php
// ============================================================
// update_mata_kuliah.php — Update mata kuliah (admin)
// ============================================================

require_once '../config/koneksi.php';
require_once '../auth/auth_helper.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode(['status' => 'error', 'message' => 'Method tidak diizinkan']);
    exit();
}

$currentUser = requireAuth($conn);
requireRole($currentUser, ['admin']);

$id         = trim($_POST['id']          ?? '');
$kodeMk     = trim($_POST['kode_mk']     ?? '');
$namaMk     = trim($_POST['nama_mk']     ?? '');
$sks        = trim($_POST['sks']         ?? '');
$prodiId    = trim($_POST['prodi_id']    ?? '');
$semesterKe = trim($_POST['semester_ke'] ?? '');
$deskripsi  = trim($_POST['deskripsi']   ?? '');

if (empty($id) || empty($kodeMk) || empty($namaMk) || empty($sks) || empty($prodiId) || empty($semesterKe)) {
    echo json_encode(['status' => 'error', 'message' => 'Semua field wajib diisi kecuali deskripsi']);
    exit();
}

$cekDup = $conn->prepare("SELECT id FROM mata_kuliah WHERE kode_mk = ? AND id != ? LIMIT 1");
$cekDup->bind_param('si', $kodeMk, $id);
$cekDup->execute();
$cekDup->store_result();
if ($cekDup->num_rows > 0) {
    echo json_encode(['status' => 'error', 'message' => 'Kode mata kuliah sudah dipakai mata kuliah lain']);
    $cekDup->close();
    $conn->close();
    exit();
}
$cekDup->close();

$stmt = $conn->prepare(
    "UPDATE mata_kuliah SET kode_mk = ?, nama_mk = ?, sks = ?, prodi_id = ?, semester_ke = ?, deskripsi = ?
     WHERE id = ?"
);
$stmt->bind_param('ssiiisi', $kodeMk, $namaMk, $sks, $prodiId, $semesterKe, $deskripsi, $id);
$stmt->execute();

if ($stmt->affected_rows >= 0) {
    echo json_encode(['status' => 'ok', 'message' => 'Mata kuliah berhasil diperbarui']);
} else {
    echo json_encode(['status' => 'error', 'message' => 'Gagal memperbarui mata kuliah']);
}

$stmt->close();
$conn->close();
