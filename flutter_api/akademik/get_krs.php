<?php
// ============================================================
// get_krs.php — Ambil data KRS
//   Mahasiswa : KRS milik sendiri (tahun ajaran aktif)
//   Admin     : semua KRS, bisa difilter by status
// ============================================================

require_once '../config/koneksi.php';
require_once '../auth/auth_helper.php';

if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    http_response_code(405);
    echo json_encode(['status' => 'error', 'message' => 'Method tidak diizinkan']);
    exit();
}

$currentUser = requireAuth($conn);
$status = trim($_GET['status'] ?? '');

if ($currentUser['role'] === 'user') {
    $mahasiswaId = getMahasiswaIdFromUserId($conn, $currentUser['id']);
    if (!$mahasiswaId) {
        echo json_encode(['status' => 'error', 'message' => 'Data mahasiswa tidak ditemukan']);
        $conn->close();
        exit();
    }

    $stmt = $conn->prepare(
        "SELECT krs.id, krs.mahasiswa_id, krs.tahun_ajaran_id, krs.status,
                krs.catatan_admin, krs.tanggal_ajuan, krs.tanggal_keputusan
         FROM krs
         WHERE krs.mahasiswa_id = ?
         ORDER BY krs.tanggal_ajuan DESC"
    );
    $stmt->bind_param('i', $mahasiswaId);
    $stmt->execute();
    $result = $stmt->get_result();
    $rows = $result->fetch_all(MYSQLI_ASSOC);
    $stmt->close();

} elseif ($currentUser['role'] === 'admin') {
    $sql = "SELECT krs.id, krs.mahasiswa_id, m.nama AS nama_mahasiswa, m.nim,
                   krs.tahun_ajaran_id, krs.status, krs.catatan_admin,
                   krs.tanggal_ajuan, krs.tanggal_keputusan
            FROM krs
            JOIN mahasiswa m ON m.id = krs.mahasiswa_id
            WHERE 1=1";
    $params = [];
    $types  = '';

    if (!empty($status)) {
        $sql .= " AND krs.status = ?";
        $params[] = $status;
        $types   .= 's';
    }
    $sql .= " ORDER BY krs.tanggal_ajuan DESC";

    $stmt = $conn->prepare($sql);
    if (!empty($params)) {
        $stmt->bind_param($types, ...$params);
    }
    $stmt->execute();
    $result = $stmt->get_result();
    $rows = $result->fetch_all(MYSQLI_ASSOC);
    $stmt->close();

} else {
    http_response_code(403);
    echo json_encode(['status' => 'error', 'message' => 'Role Anda tidak memiliki akses ke data ini']);
    $conn->close();
    exit();
}

// Ambil detail mata kuliah untuk tiap KRS
$data = [];
foreach ($rows as $row) {
    $detailStmt = $conn->prepare(
        "SELECT kd.kelas_id, mk.nama_mk, k.nama_kelas, mk.sks, d.nama AS dosen
         FROM krs_detail kd
         JOIN kelas k ON k.id = kd.kelas_id
         JOIN mata_kuliah mk ON mk.id = k.mata_kuliah_id
         JOIN dosen d ON d.id = k.dosen_id
         WHERE kd.krs_id = ?"
    );
    $detailStmt->bind_param('i', $row['id']);
    $detailStmt->execute();
    $detailResult = $detailStmt->get_result();

    $mataKuliah = [];
    $totalSks   = 0;
    while ($d = $detailResult->fetch_assoc()) {
        $mataKuliah[] = [
            'kelas_id'   => (string)$d['kelas_id'],
            'nama_mk'    => $d['nama_mk'],
            'nama_kelas' => $d['nama_kelas'],
            'sks'        => (int)$d['sks'],
            'dosen'      => $d['dosen']
        ];
        $totalSks += (int)$d['sks'];
    }
    $detailStmt->close();

    $item = [
        'id'                => (string)$row['id'],
        'mahasiswa_id'      => (string)$row['mahasiswa_id'],
        'tahun_ajaran_id'   => (string)$row['tahun_ajaran_id'],
        'status'            => $row['status'],
        'catatan_admin'     => $row['catatan_admin'],
        'tanggal_ajuan'     => $row['tanggal_ajuan'],
        'tanggal_keputusan' => $row['tanggal_keputusan'],
        'total_sks'         => $totalSks,
        'mata_kuliah'       => $mataKuliah
    ];

    if (isset($row['nama_mahasiswa'])) {
        $item['nama_mahasiswa'] = $row['nama_mahasiswa'];
        $item['nim']            = $row['nim'];
    }

    $data[] = $item;
}

echo json_encode(['status' => 'ok', 'data' => $data, 'total' => count($data)]);

$conn->close();
