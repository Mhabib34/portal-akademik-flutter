<?php
// ============================================================
// ajukan_krs.php — Mahasiswa mengajukan KRS (satu submission sekaligus)
//   Body: JSON { "kelas_ids": ["3","7","12"] }
//   Validasi: belum pernah KRS di tahun ajaran ini, total SKS <= batas
//   maksimal, tidak bentrok jadwal antar kelas yang dipilih,
//   kapasitas kelas belum penuh.
// ============================================================

require_once 'koneksi.php';
require_once 'auth_helper.php';

const MAX_SKS = 24;

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode(['status' => 'error', 'message' => 'Method tidak diizinkan']);
    exit();
}

$currentUser = requireAuth($conn);
requireRole($currentUser, ['user']);

$body      = json_decode(file_get_contents('php://input'), true);
$kelasIds  = $body['kelas_ids'] ?? [];

if (!is_array($kelasIds) || count($kelasIds) === 0) {
    echo json_encode(['status' => 'error', 'message' => 'kelas_ids wajib diisi dan berupa array']);
    exit();
}

$mahasiswaId = getMahasiswaIdFromUserId($conn, $currentUser['id']);
if (!$mahasiswaId) {
    echo json_encode(['status' => 'error', 'message' => 'Data mahasiswa tidak ditemukan']);
    $conn->close();
    exit();
}

$tahunAktif = $conn->query("SELECT id FROM tahun_ajaran WHERE is_aktif = 1 LIMIT 1");
if ($tahunAktif->num_rows === 0) {
    echo json_encode(['status' => 'error', 'message' => 'Belum ada tahun ajaran aktif']);
    $conn->close();
    exit();
}
$tahunAjaranId = $tahunAktif->fetch_assoc()['id'];

// Cek sudah pernah KRS di tahun ajaran ini
$cekKrs = $conn->prepare("SELECT id FROM krs WHERE mahasiswa_id = ? AND tahun_ajaran_id = ? LIMIT 1");
$cekKrs->bind_param('ii', $mahasiswaId, $tahunAjaranId);
$cekKrs->execute();
$cekKrs->store_result();
if ($cekKrs->num_rows > 0) {
    http_response_code(409);
    echo json_encode(['status' => 'error', 'message' => 'Anda sudah mengajukan KRS untuk tahun ajaran ini']);
    $cekKrs->close();
    $conn->close();
    exit();
}
$cekKrs->close();

// Ambil detail kelas yang dipilih + validasi semua milik tahun ajaran aktif
$placeholders = implode(',', array_fill(0, count($kelasIds), '?'));
$types        = str_repeat('i', count($kelasIds));

$sqlKelas = "SELECT k.id, k.tahun_ajaran_id, k.kapasitas, mk.sks,
                    (SELECT COUNT(*) FROM krs_detail kd
                       JOIN krs ON krs.id = kd.krs_id
                       WHERE kd.kelas_id = k.id AND krs.status = 'disetujui') AS jumlah_terisi
             FROM kelas k
             JOIN mata_kuliah mk ON mk.id = k.mata_kuliah_id
             WHERE k.id IN ($placeholders)";
$stmtKelas = $conn->prepare($sqlKelas);
$stmtKelas->bind_param($types, ...$kelasIds);
$stmtKelas->execute();
$resultKelas = $stmtKelas->get_result();

$kelasData = [];
$totalSks  = 0;
while ($row = $resultKelas->fetch_assoc()) {
    if ((int)$row['tahun_ajaran_id'] !== (int)$tahunAjaranId) {
        echo json_encode(['status' => 'error', 'message' => 'Ada kelas yang bukan dari tahun ajaran aktif']);
        $stmtKelas->close();
        $conn->close();
        exit();
    }
    if ((int)$row['jumlah_terisi'] >= (int)$row['kapasitas']) {
        echo json_encode(['status' => 'error', 'message' => 'Salah satu kelas yang dipilih sudah penuh']);
        $stmtKelas->close();
        $conn->close();
        exit();
    }
    $kelasData[$row['id']] = $row;
    $totalSks += (int)$row['sks'];
}
$stmtKelas->close();

if (count($kelasData) !== count($kelasIds)) {
    echo json_encode(['status' => 'error', 'message' => 'Ada kelas_id yang tidak valid']);
    $conn->close();
    exit();
}

if ($totalSks > MAX_SKS) {
    echo json_encode(['status' => 'error', 'message' => "Total SKS ($totalSks) melebihi batas maksimal (" . MAX_SKS . ")"]);
    $conn->close();
    exit();
}

// Cek bentrok jadwal antar kelas yang dipilih
$sqlJadwal = "SELECT kelas_id, hari, jam_mulai, jam_selesai FROM jadwal WHERE kelas_id IN ($placeholders)";
$stmtJadwal = $conn->prepare($sqlJadwal);
$stmtJadwal->bind_param($types, ...$kelasIds);
$stmtJadwal->execute();
$jadwalList = $stmtJadwal->get_result()->fetch_all(MYSQLI_ASSOC);
$stmtJadwal->close();

for ($i = 0; $i < count($jadwalList); $i++) {
    for ($j = $i + 1; $j < count($jadwalList); $j++) {
        $a = $jadwalList[$i];
        $b = $jadwalList[$j];
        if ($a['hari'] === $b['hari'] && $a['jam_mulai'] < $b['jam_selesai'] && $a['jam_selesai'] > $b['jam_mulai']) {
            http_response_code(409);
            echo json_encode(['status' => 'error', 'message' => 'Ada 2 kelas yang dipilih jadwalnya bentrok']);
            $conn->close();
            exit();
        }
    }
}

// --- Simpan KRS ---
$conn->begin_transaction();

try {
    $stmtKrs = $conn->prepare(
        "INSERT INTO krs (mahasiswa_id, tahun_ajaran_id, status) VALUES (?, ?, 'menunggu')"
    );
    $stmtKrs->bind_param('ii', $mahasiswaId, $tahunAjaranId);
    $stmtKrs->execute();
    $krsId = $conn->insert_id;
    $stmtKrs->close();

    $stmtDetail = $conn->prepare("INSERT INTO krs_detail (krs_id, kelas_id) VALUES (?, ?)");
    foreach ($kelasIds as $kelasId) {
        $stmtDetail->bind_param('ii', $krsId, $kelasId);
        $stmtDetail->execute();
    }
    $stmtDetail->close();

    $conn->commit();

    echo json_encode([
        'status'  => 'ok',
        'message' => 'KRS berhasil diajukan, menunggu persetujuan admin',
        'krs_id'  => (string)$krsId
    ]);

} catch (Exception $e) {
    $conn->rollback();
    echo json_encode(['status' => 'error', 'message' => 'Gagal mengajukan KRS: ' . $e->getMessage()]);
}

$conn->close();
