<?php
// ============================================================
// simpan_jadwal.php — Tambah jadwal untuk sebuah kelas (admin)
//   Cek bentrok: ruang & dosen tidak boleh overlap waktu
//   di hari yang sama
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

$kelasId     = trim($_POST['kelas_id']    ?? '');
$ruangId     = trim($_POST['ruang_id']    ?? '');
$hari        = trim($_POST['hari']        ?? '');
$jamMulai    = trim($_POST['jam_mulai']   ?? '');
$jamSelesai  = trim($_POST['jam_selesai'] ?? '');

$hariValid = ['Senin','Selasa','Rabu','Kamis','Jumat','Sabtu'];

if (empty($kelasId) || empty($ruangId) || !in_array($hari, $hariValid, true) || empty($jamMulai) || empty($jamSelesai)) {
    echo json_encode(['status' => 'error', 'message' => 'kelas_id, ruang_id, hari, jam_mulai, dan jam_selesai wajib diisi dengan benar']);
    exit();
}

if ($jamMulai >= $jamSelesai) {
    echo json_encode(['status' => 'error', 'message' => 'jam_mulai harus lebih awal dari jam_selesai']);
    exit();
}

// Ambil dosen_id dari kelas ini, untuk cek bentrok dosen
$kelasStmt = $conn->prepare("SELECT dosen_id FROM kelas WHERE id = ? LIMIT 1");
$kelasStmt->bind_param('i', $kelasId);
$kelasStmt->execute();
$kelasResult = $kelasStmt->get_result();
if ($kelasResult->num_rows === 0) {
    echo json_encode(['status' => 'error', 'message' => 'Kelas tidak ditemukan']);
    $kelasStmt->close();
    $conn->close();
    exit();
}
$dosenId = $kelasResult->fetch_assoc()['dosen_id'];
$kelasStmt->close();

// --- Cek bentrok RUANG: hari sama, ruang sama, waktu overlap ---
$cekRuang = $conn->prepare(
    "SELECT j.id FROM jadwal j
     WHERE j.ruang_id = ? AND j.hari = ?
       AND j.jam_mulai < ? AND j.jam_selesai > ?
     LIMIT 1"
);
$cekRuang->bind_param('isss', $ruangId, $hari, $jamSelesai, $jamMulai);
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

// --- Cek bentrok DOSEN: hari sama, dosen sama (lewat join kelas), waktu overlap ---
$cekDosen = $conn->prepare(
    "SELECT j.id FROM jadwal j
     JOIN kelas k ON k.id = j.kelas_id
     WHERE k.dosen_id = ? AND j.hari = ?
       AND j.jam_mulai < ? AND j.jam_selesai > ?
     LIMIT 1"
);
$cekDosen->bind_param('isss', $dosenId, $hari, $jamSelesai, $jamMulai);
$cekDosen->execute();
$cekDosen->store_result();
if ($cekDosen->num_rows > 0) {
    http_response_code(409);
    echo json_encode(['status' => 'error', 'message' => 'Dosen pengampu kelas ini sudah mengajar kelas lain di jam yang sama']);
    $cekDosen->close();
    $conn->close();
    exit();
}
$cekDosen->close();

$stmt = $conn->prepare(
    "INSERT INTO jadwal (kelas_id, ruang_id, hari, jam_mulai, jam_selesai) VALUES (?, ?, ?, ?, ?)"
);
$stmt->bind_param('iisss', $kelasId, $ruangId, $hari, $jamMulai, $jamSelesai);
$stmt->execute();

echo json_encode([
    'status'  => 'ok',
    'message' => 'Jadwal berhasil ditambahkan',
    'id'      => (string)$conn->insert_id
]);

$stmt->close();
$conn->close();
