<?php
// ============================================================
// get_khs.php — KHS mahasiswa per semester + IPK kumulatif
//   tahun_ajaran_id kosong = pakai tahun ajaran aktif
//   IP semester   = SUM(bobot*sks) / SUM(sks) untuk semester itu
//   IPK kumulatif = SUM(bobot*sks) / SUM(sks) untuk SEMUA semester
// ============================================================

require_once 'koneksi.php';
require_once 'auth_helper.php';

if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    http_response_code(405);
    echo json_encode(['status' => 'error', 'message' => 'Method tidak diizinkan']);
    exit();
}

$currentUser = requireAuth($conn);
requireRole($currentUser, ['user']);

$mahasiswaId = getMahasiswaIdFromUserId($conn, $currentUser['id']);
if (!$mahasiswaId) {
    echo json_encode(['status' => 'error', 'message' => 'Data mahasiswa tidak ditemukan']);
    $conn->close();
    exit();
}

$tahunAjaranId = trim($_GET['tahun_ajaran_id'] ?? '');

if (empty($tahunAjaranId)) {
    $aktif = $conn->query("SELECT id, nama, semester FROM tahun_ajaran WHERE is_aktif = 1 LIMIT 1");
    if ($aktif->num_rows === 0) {
        echo json_encode(['status' => 'error', 'message' => 'Belum ada tahun ajaran aktif']);
        $conn->close();
        exit();
    }
    $tahun = $aktif->fetch_assoc();
    $tahunAjaranId = $tahun['id'];
} else {
    $cekTahun = $conn->prepare("SELECT id, nama, semester FROM tahun_ajaran WHERE id = ? LIMIT 1");
    $cekTahun->bind_param('i', $tahunAjaranId);
    $cekTahun->execute();
    $resTahun = $cekTahun->get_result();
    if ($resTahun->num_rows === 0) {
        echo json_encode(['status' => 'error', 'message' => 'Tahun ajaran tidak ditemukan']);
        $cekTahun->close();
        $conn->close();
        exit();
    }
    $tahun = $resTahun->fetch_assoc();
    $cekTahun->close();
}

// --- Nilai semester yang diminta ---
$stmtSemester = $conn->prepare(
    "SELECT n.id, n.kelas_id, mk.nama_mk, mk.sks,
            n.tugas, n.quiz_1, n.quiz_2, n.uts, n.kehadiran, n.uas,
            n.nilai_angka, n.nilai_huruf, n.bobot
     FROM nilai n
     JOIN kelas k ON k.id = n.kelas_id
     JOIN mata_kuliah mk ON mk.id = k.mata_kuliah_id
     WHERE n.mahasiswa_id = ? AND k.tahun_ajaran_id = ?
     ORDER BY mk.nama_mk ASC"
);
$stmtSemester->bind_param('ii', $mahasiswaId, $tahunAjaranId);
$stmtSemester->execute();
$resultSemester = $stmtSemester->get_result();

$mataKuliah      = [];
$totalSksSem     = 0;
$totalBobotSksSem = 0;

while ($row = $resultSemester->fetch_assoc()) {
    $sks = (int)$row['sks'];
    $mataKuliah[] = [
        'id'          => (string)$row['id'],
        'kelas_id'    => (string)$row['kelas_id'],
        'nama_mk'     => $row['nama_mk'],
        'sks'         => $sks,
        'tugas'       => (float)$row['tugas'],
        'quiz_1'      => (float)$row['quiz_1'],
        'quiz_2'      => (float)$row['quiz_2'],
        'uts'         => (float)$row['uts'],
        'kehadiran'   => (float)$row['kehadiran'],
        'uas'         => (float)$row['uas'],
        'nilai_angka' => (float)$row['nilai_angka'],
        'nilai_huruf' => $row['nilai_huruf'],
        'bobot'       => (float)$row['bobot']
    ];
    $totalSksSem      += $sks;
    $totalBobotSksSem += $sks * (float)$row['bobot'];
}
$stmtSemester->close();

$ipSemester = $totalSksSem > 0 ? round($totalBobotSksSem / $totalSksSem, 2) : 0;

// --- IPK kumulatif (semua semester) ---
$stmtKumulatif = $conn->prepare(
    "SELECT mk.sks, n.bobot
     FROM nilai n
     JOIN kelas k ON k.id = n.kelas_id
     JOIN mata_kuliah mk ON mk.id = k.mata_kuliah_id
     WHERE n.mahasiswa_id = ?"
);
$stmtKumulatif->bind_param('i', $mahasiswaId);
$stmtKumulatif->execute();
$resultKumulatif = $stmtKumulatif->get_result();

$totalSksKum      = 0;
$totalBobotSksKum = 0;
while ($row = $resultKumulatif->fetch_assoc()) {
    $sks = (int)$row['sks'];
    $totalSksKum      += $sks;
    $totalBobotSksKum += $sks * (float)$row['bobot'];
}
$stmtKumulatif->close();

$ipkKumulatif = $totalSksKum > 0 ? round($totalBobotSksKum / $totalSksKum, 2) : 0;

echo json_encode([
    'status' => 'ok',
    'data'   => [
        'tahun_ajaran'         => $tahun['nama'] . ' ' . $tahun['semester'],
        'ip_semester'          => $ipSemester,
        'ipk_kumulatif'        => $ipkKumulatif,
        'total_sks_semester'   => $totalSksSem,
        'total_sks_kumulatif'  => $totalSksKum,
        'mata_kuliah'          => $mataKuliah
    ]
]);

$conn->close();
