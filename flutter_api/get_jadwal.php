<?php
// ============================================================
// get_jadwal.php — Ambil jadwal
//   Mahasiswa : hanya jadwal dari kelas di KRS yang sudah disetujui
//   Dosen     : hanya jadwal kelas yang diampu sendiri
//   Admin     : semua jadwal
//   Filter opsional: hari
// ============================================================

require_once 'koneksi.php';
require_once 'auth_helper.php';

if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    http_response_code(405);
    echo json_encode(['status' => 'error', 'message' => 'Method tidak diizinkan']);
    exit();
}

$currentUser = requireAuth($conn);
$hari = trim($_GET['hari'] ?? '');

$baseSql = "SELECT j.id, j.kelas_id, mk.nama_mk, k.nama_kelas,
                   j.ruang_id, r.nama_ruang, j.hari, j.jam_mulai, j.jam_selesai,
                   d.nama AS dosen
            FROM jadwal j
            JOIN kelas k ON k.id = j.kelas_id
            JOIN mata_kuliah mk ON mk.id = k.mata_kuliah_id
            JOIN ruang r ON r.id = j.ruang_id
            JOIN dosen d ON d.id = k.dosen_id
            WHERE 1=1";

$params = [];
$types  = '';

if ($currentUser['role'] === 'user') {
    $mahasiswaId = getMahasiswaIdFromUserId($conn, $currentUser['id']);
    if (!$mahasiswaId) {
        echo json_encode(['status' => 'error', 'message' => 'Data mahasiswa tidak ditemukan']);
        $conn->close();
        exit();
    }
    $baseSql .= " AND k.id IN (
                    SELECT kd.kelas_id FROM krs_detail kd
                    JOIN krs ON krs.id = kd.krs_id
                    WHERE krs.mahasiswa_id = ? AND krs.status = 'disetujui'
                  )";
    $params[] = $mahasiswaId;
    $types   .= 'i';

} elseif ($currentUser['role'] === 'dosen') {
    $dosenId = getDosenIdFromUserId($conn, $currentUser['id']);
    if (!$dosenId) {
        echo json_encode(['status' => 'error', 'message' => 'Data dosen tidak ditemukan']);
        $conn->close();
        exit();
    }
    $baseSql .= " AND k.dosen_id = ?";
    $params[] = $dosenId;
    $types   .= 'i';
}
// admin: tanpa filter tambahan

if (!empty($hari)) {
    $baseSql .= " AND j.hari = ?";
    $params[] = $hari;
    $types   .= 's';
}

$baseSql .= " ORDER BY FIELD(j.hari,'Senin','Selasa','Rabu','Kamis','Jumat','Sabtu'), j.jam_mulai ASC";

$stmt = $conn->prepare($baseSql);
if (!empty($params)) {
    $stmt->bind_param($types, ...$params);
}
$stmt->execute();
$result = $stmt->get_result();

$data = [];
while ($row = $result->fetch_assoc()) {
    $data[] = [
        'id'          => (string)$row['id'],
        'kelas_id'    => (string)$row['kelas_id'],
        'nama_mk'     => $row['nama_mk'],
        'nama_kelas'  => $row['nama_kelas'],
        'ruang_id'    => (string)$row['ruang_id'],
        'nama_ruang'  => $row['nama_ruang'],
        'hari'        => $row['hari'],
        'jam_mulai'   => substr($row['jam_mulai'], 0, 5),
        'jam_selesai' => substr($row['jam_selesai'], 0, 5),
        'dosen'       => $row['dosen']
    ];
}

echo json_encode(['status' => 'ok', 'data' => $data, 'total' => count($data)]);

$stmt->close();
$conn->close();
