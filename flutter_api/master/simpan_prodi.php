<?php
// ============================================================
// simpan_prodi.php — Tambah prodi
//   Hanya admin yang bisa akses
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

$fakultasId = trim($_POST['fakultas_id'] ?? '');
$namaProdi  = trim($_POST['nama_prodi'] ?? '');

if (empty($fakultasId) || empty($namaProdi)) {
    echo json_encode(['status' => 'error', 'message' => 'Fakultas ID dan nama prodi wajib diisi']);
    exit();
}

$stmt = $conn->prepare("INSERT INTO prodi (fakultas_id, nama_prodi) VALUES (?, ?)");
$stmt->bind_param('is', $fakultasId, $namaProdi);

if ($stmt->execute()) {
    echo json_encode([
        'status'  => 'ok',
        'message' => 'Prodi berhasil ditambahkan',
        'id'      => (string)$conn->insert_id
    ]);
} else {
    echo json_encode(['status' => 'error', 'message' => 'Gagal menyimpan prodi: ' . $stmt->error]);
}

$stmt->close();
$conn->close();
