<?php
// ============================================================
// simpan_fakultas.php — Tambah fakultas
//   Hanya admin yang bisa akses
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

$namaFakultas = trim($_POST['nama_fakultas'] ?? '');

if (empty($namaFakultas)) {
    echo json_encode(['status' => 'error', 'message' => 'Nama fakultas wajib diisi']);
    exit();
}

$stmt = $conn->prepare("INSERT INTO fakultas (nama_fakultas) VALUES (?)");
$stmt->bind_param('s', $namaFakultas);

if ($stmt->execute()) {
    echo json_encode([
        'status'  => 'ok',
        'message' => 'Fakultas berhasil ditambahkan',
        'id'      => (string)$conn->insert_id
    ]);
} else {
    echo json_encode(['status' => 'error', 'message' => 'Gagal menyimpan fakultas: ' . $stmt->error]);
}

$stmt->close();
$conn->close();
