<?php
// ============================================================
// get_nilai.php — Ambil data nilai
//   Dosen     : nilai kelas yang diampu (wajib kirim kelas_id)
//   Mahasiswa : nilai milik sendiri
//   Admin     : semua/filter kelas_id & tahun_ajaran_id
// ============================================================

require_once '../config/koneksi.php';
require_once '../auth/auth_helper.php';

if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    http_response_code(405);
    echo json_encode(['status' => 'error', 'message' => 'Method tidak diizinkan']);
    exit();
}

$currentUser  = requireAuth($conn);
$kelasId      = trim($_GET['kelas_id']       ?? '');
$tahunAjaranId = trim($_GET['tahun_ajaran_id'] ?? '');

$sql = "SELECT n.id, n.mahasiswa_id, m.nim, m.nama AS nama_mahasiswa,
               n.kelas_id, mk.nama_mk, mk.sks,
               n.tugas, n.quiz_1, n.quiz_2, n.uts, n.kehadiran, n.uas,
               n.nilai_angka, n.nilai_huruf, n.bobot
        FROM nilai n
        JOIN mahasiswa m ON m.id = n.mahasiswa_id
        JOIN kelas k ON k.id = n.kelas_id
        JOIN mata_kuliah mk ON mk.id = k.mata_kuliah_id
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
    $sql .= " AND n.mahasiswa_id = ?";
    $params[] = $mahasiswaId;
    $types   .= 'i';

} elseif ($currentUser['role'] === 'dosen') {
    $dosenId = getDosenIdFromUserId($conn, $currentUser['id']);
    if (!$dosenId) {
        echo json_encode(['status' => 'error', 'message' => 'Data dosen tidak ditemukan']);
        $conn->close();
        exit();
    }
    $sql .= " AND k.dosen_id = ?";
    $params[] = $dosenId;
    $types   .= 'i';
}
// admin: tanpa filter role tambahan

if (!empty($kelasId)) {
    $sql .= " AND n.kelas_id = ?";
    $params[] = $kelasId;
    $types   .= 'i';
}
if (!empty($tahunAjaranId)) {
    $sql .= " AND k.tahun_ajaran_id = ?";
    $params[] = $tahunAjaranId;
    $types   .= 'i';
}

$sql .= " ORDER BY mk.nama_mk ASC, m.nama ASC";

$stmt = $conn->prepare($sql);
if (!empty($params)) {
    $stmt->bind_param($types, ...$params);
}
$stmt->execute();
$result = $stmt->get_result();

$data = [];
while ($row = $result->fetch_assoc()) {
    $data[] = [
        'id'              => (string)$row['id'],
        'mahasiswa_id'    => (string)$row['mahasiswa_id'],
        'nim'             => $row['nim'],
        'nama_mahasiswa'  => $row['nama_mahasiswa'],
        'kelas_id'        => (string)$row['kelas_id'],
        'nama_mk'         => $row['nama_mk'],
        'sks'             => (int)$row['sks'],
        'tugas'           => (float)$row['tugas'],
        'quiz_1'          => (float)$row['quiz_1'],
        'quiz_2'          => (float)$row['quiz_2'],
        'uts'             => (float)$row['uts'],
        'kehadiran'       => (float)$row['kehadiran'],
        'uas'             => (float)$row['uas'],
        'nilai_angka'     => (float)$row['nilai_angka'],
        'nilai_huruf'     => $row['nilai_huruf'],
        'bobot'           => (float)$row['bobot']
    ];
}

echo json_encode(['status' => 'ok', 'data' => $data, 'total' => count($data)]);

$stmt->close();
$conn->close();
