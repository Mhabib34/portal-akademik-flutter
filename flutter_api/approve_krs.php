<?php
// ============================================================
// approve_krs.php — Admin menyetujui/menolak pengajuan KRS
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

$krsId        = trim($_POST['krs_id']        ?? '');
$status       = trim($_POST['status']        ?? '');
$catatanAdmin = trim($_POST['catatan_admin'] ?? '');

if (empty($krsId) || !in_array($status, ['disetujui', 'ditolak'], true)) {
    echo json_encode(['status' => 'error', 'message' => 'krs_id wajib diisi dan status harus disetujui/ditolak']);
    exit();
}

$cek = $conn->prepare("SELECT status FROM krs WHERE id = ? LIMIT 1");
$cek->bind_param('i', $krsId);
$cek->execute();
$result = $cek->get_result();
if ($result->num_rows === 0) {
    echo json_encode(['status' => 'error', 'message' => 'KRS tidak ditemukan']);
    $cek->close();
    $conn->close();
    exit();
}
$existing = $result->fetch_assoc();
$cek->close();

if ($existing['status'] !== 'menunggu') {
    echo json_encode(['status' => 'error', 'message' => 'KRS ini sudah pernah diproses sebelumnya']);
    $conn->close();
    exit();
}

// Kalau mau disetujui, cek ulang kapasitas kelas (jaga-jaga ada perubahan sejak diajukan)
if ($status === 'disetujui') {
    $cekKapasitas = $conn->prepare(
        "SELECT k.id, k.kapasitas,
                (SELECT COUNT(*) FROM krs_detail kd2
                   JOIN krs ON krs.id = kd2.krs_id
                   WHERE kd2.kelas_id = k.id AND krs.status = 'disetujui') AS jumlah_terisi
         FROM krs_detail kd
         JOIN kelas k ON k.id = kd.kelas_id
         WHERE kd.krs_id = ?"
    );
    $cekKapasitas->bind_param('i', $krsId);
    $cekKapasitas->execute();
    $resKapasitas = $cekKapasitas->get_result();
    while ($row = $resKapasitas->fetch_assoc()) {
        if ((int)$row['jumlah_terisi'] >= (int)$row['kapasitas']) {
            echo json_encode(['status' => 'error', 'message' => 'Salah satu kelas di KRS ini sudah penuh, tidak bisa disetujui']);
            $cekKapasitas->close();
            $conn->close();
            exit();
        }
    }
    $cekKapasitas->close();
}

$stmt = $conn->prepare(
    "UPDATE krs SET status = ?, catatan_admin = ?, tanggal_keputusan = NOW() WHERE id = ?"
);
$stmt->bind_param('ssi', $status, $catatanAdmin, $krsId);
$stmt->execute();

echo json_encode(['status' => 'ok', 'message' => "KRS berhasil di-$status"]);

$stmt->close();
$conn->close();
