<?php
// ============================================================
// get_kelas.php — Ambil daftar kelas (rombel)
//   Filter opsional: tahun_ajaran_id, mata_kuliah_id, dosen_id
// ============================================================

require_once '../config/koneksi.php';
require_once '../auth/auth_helper.php';

if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    http_response_code(405);
    echo json_encode(['status' => 'error', 'message' => 'Method tidak diizinkan']);
    exit();
}

requireAuth($conn);

$tahunAjaranId = trim($_GET['tahun_ajaran_id'] ?? '');
$mataKuliahId  = trim($_GET['mata_kuliah_id']  ?? '');
$dosenId       = trim($_GET['dosen_id']        ?? '');

$sql = "SELECT k.id, k.mata_kuliah_id, mk.kode_mk, mk.nama_mk, mk.sks,
               k.tahun_ajaran_id, k.dosen_id, d.nama AS nama_dosen,
               k.nama_kelas, k.kapasitas,
               (SELECT COUNT(*) FROM krs_detail kd
                  JOIN krs ON krs.id = kd.krs_id
                  WHERE kd.kelas_id = k.id AND krs.status = 'disetujui') AS jumlah_terisi
        FROM kelas k
        JOIN mata_kuliah mk ON mk.id = k.mata_kuliah_id
        JOIN dosen d ON d.id = k.dosen_id
        WHERE 1=1";

$params = [];
$types  = '';

if (!empty($tahunAjaranId)) {
    $sql .= " AND k.tahun_ajaran_id = ?";
    $params[] = $tahunAjaranId;
    $types   .= 'i';
}
if (!empty($mataKuliahId)) {
    $sql .= " AND k.mata_kuliah_id = ?";
    $params[] = $mataKuliahId;
    $types   .= 'i';
}
if (!empty($dosenId)) {
    $sql .= " AND k.dosen_id = ?";
    $params[] = $dosenId;
    $types   .= 'i';
}
$sql .= " ORDER BY mk.nama_mk ASC, k.nama_kelas ASC";

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
        'mata_kuliah_id'  => (string)$row['mata_kuliah_id'],
        'kode_mk'         => $row['kode_mk'],
        'nama_mk'         => $row['nama_mk'],
        'sks'             => (int)$row['sks'],
        'tahun_ajaran_id' => (string)$row['tahun_ajaran_id'],
        'dosen_id'        => (string)$row['dosen_id'],
        'nama_dosen'      => $row['nama_dosen'],
        'nama_kelas'      => $row['nama_kelas'],
        'kapasitas'       => (int)$row['kapasitas'],
        'jumlah_terisi'   => (int)$row['jumlah_terisi']
    ];
}

echo json_encode(['status' => 'ok', 'data' => $data, 'total' => count($data)]);

$stmt->close();
$conn->close();
