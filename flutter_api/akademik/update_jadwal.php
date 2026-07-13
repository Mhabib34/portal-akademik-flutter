<?php
// ============================================================
// update_jadwal.php — Update jadwal (admin)
//   Cek bentrok ruang & dosen, kecualikan baris jadwal ini sendiri
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
$ruangId    = trim($_POST['ruang_id']    ?? '');
$hari       = trim($_POST['hari']        ?? '');
$jamMulai   = trim($_POST['jam_mulai']   ?? '');
$jamSelesai = trim($_POST['jam_selesai'] ?? '');

$hariValid = ['Senin','Selasa','Rabu','Kamis','Jumat','Sabtu'];

if (empty($id) || empty($ruangId) || !in_array($hari, $hariValid, true) || empty($jamMulai) || empty($jamSelesai)) {
    echo json_encode(['status' => 'error', 'message' => 'Semua field wajib diisi dengan benar']);
    exit();
}

if ($jamMulai >= $jamSelesai) {
    echo json_encode(['status' => 'error', 'message' => 'jam_mulai harus lebih awal dari jam_selesai']);
    exit();
}

$jadwalStmt = $conn->prepare(
    "SELECT j.kelas_id, k.dosen_id FROM jadwal j JOIN kelas k ON k.id = j.kelas_id WHERE j.id = ? LIMIT 1"
);
$jadwalStmt->bind_param('i', $id);
$jadwalStmt->execute();
$jadwalResult = $jadwalStmt->get_result();
if ($jadwalResult->num_rows === 0) {
    echo json_encode(['status' => 'error', 'message' => 'Jadwal tidak ditemukan']);
    $jadwalStmt->close();
    $conn->close();
    exit();
}
$dosenId = $jadwalResult->fetch_assoc()['dosen_id'];
$jadwalStmt->close();

$cekRuang = $conn->prepare(
    "SELECT j.id FROM jadwal j
     WHERE j.ruang_id = ? AND j.hari = ? AND j.id != ?
       AND j.jam_mulai < ? AND j.jam_selesai > ?
     LIMIT 1"
);
$cekRuang->bind_param('isiss', $ruangId, $hari, $id, $jamSelesai, $jamMulai);
$cekRuang->execute();
$cekRuang->store_result();
if ($cekRuang->num_rows > 0) {
    http_response_code(409);
    echo json_encode(['status' => 'error', 'message' => 'Ruang sudah dipakai jadwal lain di jam yang sama']);
    $cekRuang->close();
    $conn->close();
    exit();
}
$cekRuang->close();

$cekDosen = $conn->prepare(
    "SELECT j.id FROM jadwal j
     JOIN kelas k ON k.id = j.kelas_id
     WHERE k.dosen_id = ? AND j.hari = ? AND j.id != ?
       AND j.jam_mulai < ? AND j.jam_selesai > ?
     LIMIT 1"
);
$cekDosen->bind_param('isiss', $dosenId, $hari, $id, $jamSelesai, $jamMulai);
$cekDosen->execute();
$cekDosen->store_result();
if ($cekDosen->num_rows > 0) {
    http_response_code(409);
    echo json_encode(['status' => 'error', 'message' => 'Dosen sudah mengajar kelas lain di jam yang sama']);
    $cekDosen->close();
    $conn->close();
    exit();
}
$cekDosen->close();

$stmt = $conn->prepare(
    "UPDATE jadwal SET ruang_id = ?, hari = ?, jam_mulai = ?, jam_selesai = ? WHERE id = ?"
);
$stmt->bind_param('isssi', $ruangId, $hari, $jamMulai, $jamSelesai, $id);
$stmt->execute();

echo json_encode(['status' => 'ok', 'message' => 'Jadwal berhasil diperbarui']);

$stmt->close();
$conn->close();
