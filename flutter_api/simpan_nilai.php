<?php
// ============================================================
// simpan_nilai.php — Dosen input/update nilai (bulk per kelas)
//   Body: JSON { "kelas_id": "5", "nilai": [
//     { "mahasiswa_id": "1", "tugas": 80, "quiz_1": 70, "quiz_2": 85,
//       "uts": 75, "kehadiran": 100, "uas": 90 }, ...
//   ]}
//   Bobot tetap:
//     Tugas 20% + Quiz1 5% + Quiz2 5% + UTS 25% + Kehadiran 10% + UAS 35%
// ============================================================

require_once 'koneksi.php';
require_once 'auth_helper.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode(['status' => 'error', 'message' => 'Method tidak diizinkan']);
    exit();
}

$currentUser = requireAuth($conn);
requireRole($currentUser, ['dosen']);

$body      = json_decode(file_get_contents('php://input'), true);
$kelasId   = $body['kelas_id'] ?? null;
$nilaiList = $body['nilai']    ?? [];

if (empty($kelasId) || !is_array($nilaiList) || count($nilaiList) === 0) {
    echo json_encode(['status' => 'error', 'message' => 'kelas_id dan nilai (array) wajib diisi']);
    exit();
}

// Pastikan kelas ini benar diampu oleh dosen yang login
$dosenId = getDosenIdFromUserId($conn, $currentUser['id']);
$cekKelas = $conn->prepare("SELECT id FROM kelas WHERE id = ? AND dosen_id = ? LIMIT 1");
$cekKelas->bind_param('ii', $kelasId, $dosenId);
$cekKelas->execute();
$cekKelas->store_result();
if ($cekKelas->num_rows === 0) {
    http_response_code(403);
    echo json_encode(['status' => 'error', 'message' => 'Kelas ini bukan yang Anda ampu']);
    $cekKelas->close();
    $conn->close();
    exit();
}
$cekKelas->close();

function hitungHurufDanBobot(float $angka): array {
    if ($angka >= 85) return ['A', 4.0];
    if ($angka >= 75) return ['B', 3.0];
    if ($angka >= 65) return ['C', 2.0];
    if ($angka >= 50) return ['D', 1.0];
    return ['E', 0.0];
}

$conn->begin_transaction();

try {
    $stmt = $conn->prepare(
        "INSERT INTO nilai
            (mahasiswa_id, kelas_id, tugas, quiz_1, quiz_2, uts, kehadiran, uas, nilai_angka, nilai_huruf, bobot)
         VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
         ON DUPLICATE KEY UPDATE
           tugas = VALUES(tugas), quiz_1 = VALUES(quiz_1), quiz_2 = VALUES(quiz_2),
           uts = VALUES(uts), kehadiran = VALUES(kehadiran), uas = VALUES(uas),
           nilai_angka = VALUES(nilai_angka), nilai_huruf = VALUES(nilai_huruf),
           bobot = VALUES(bobot)"
    );

    foreach ($nilaiList as $item) {
        $mahasiswaId = $item['mahasiswa_id'] ?? null;
        $tugas       = (float)($item['tugas']     ?? 0);
        $quiz1       = (float)($item['quiz_1']    ?? 0);
        $quiz2       = (float)($item['quiz_2']    ?? 0);
        $uts         = (float)($item['uts']       ?? 0);
        $kehadiran   = (float)($item['kehadiran'] ?? 0);
        $uas         = (float)($item['uas']       ?? 0);

        if (!$mahasiswaId) continue;

        $angka = round(
            ($tugas * 0.20) + ($quiz1 * 0.05) + ($quiz2 * 0.05) +
            ($uts * 0.25) + ($kehadiran * 0.10) + ($uas * 0.35),
            2
        );
        [$huruf, $bobot] = hitungHurufDanBobot($angka);

        $stmt->bind_param(
            'iidddddddsd',
            $mahasiswaId, $kelasId, $tugas, $quiz1, $quiz2, $uts, $kehadiran, $uas, $angka, $huruf, $bobot
        );
        $stmt->execute();
    }
    $stmt->close();

    $conn->commit();

    echo json_encode(['status' => 'ok', 'message' => 'Nilai berhasil disimpan']);

} catch (Exception $e) {
    $conn->rollback();
    echo json_encode(['status' => 'error', 'message' => 'Gagal menyimpan nilai: ' . $e->getMessage()]);
}

$conn->close();
