<?php
// ============================================================
// get_mahasiswa.php — Ambil data mahasiswa
//   Admin  : semua data (JOIN ke users, prodi, fakultas)
//   Mahasiswa (role=user) : data sendiri saja
//   Role/user_id diambil dari token, bukan query param lagi
// ============================================================

require_once '../config/koneksi.php';
require_once '../auth/auth_helper.php';

if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    http_response_code(405);
    echo json_encode(['status' => 'error', 'message' => 'Method tidak diizinkan']);
    exit();
}

$currentUser = requireAuth($conn);

if ($currentUser['role'] === 'admin') {
    $sql = "SELECT m.id, m.nim, m.nama, m.prodi_id, p.nama_prodi, f.nama_fakultas, m.alamat,
                   m.user_id, u.is_active, u.must_change_password
            FROM mahasiswa m
            JOIN users u ON u.id = m.user_id
            LEFT JOIN prodi p ON p.id = m.prodi_id
            LEFT JOIN fakultas f ON f.id = p.fakultas_id
            ORDER BY m.nama ASC";

    $result = $conn->query($sql);

    if (!$result) {
        echo json_encode(['status' => 'error', 'message' => 'Query gagal: ' . $conn->error]);
        $conn->close();
        exit();
    }

    $data = [];
    while ($row = $result->fetch_assoc()) {
        $data[] = [
            'id'                    => (string)$row['id'],
            'nim'                   => $row['nim'],
            'nama'                  => $row['nama'],
            'prodi_id'              => $row['prodi_id'] !== null ? (string)$row['prodi_id'] : null,
            'nama_prodi'            => $row['nama_prodi'] ?? '',
            'nama_fakultas'         => $row['nama_fakultas'] ?? '',
            'alamat'                => $row['alamat'] ?? '',
            'user_id'               => (string)$row['user_id'],
            'is_active'             => (int)$row['is_active'],
            'must_change_password'  => (int)$row['must_change_password']
        ];
    }

    echo json_encode(['status' => 'ok', 'data' => $data, 'total' => count($data)]);

} elseif ($currentUser['role'] === 'user') {
    $stmt = $conn->prepare(
        "SELECT m.id, m.nim, m.nama, m.prodi_id, p.nama_prodi, f.nama_fakultas, m.alamat,
                m.user_id, u.is_active, u.must_change_password
         FROM mahasiswa m
         JOIN users u ON u.id = m.user_id
         LEFT JOIN prodi p ON p.id = m.prodi_id
         LEFT JOIN fakultas f ON f.id = p.fakultas_id
         WHERE m.user_id = ?
         LIMIT 1"
    );
    $stmt->bind_param('i', $currentUser['id']);
    $stmt->execute();
    $result = $stmt->get_result();

    if ($result->num_rows === 0) {
        echo json_encode(['status' => 'error', 'message' => 'Data mahasiswa tidak ditemukan']);
        $stmt->close();
        $conn->close();
        exit();
    }

    $row = $result->fetch_assoc();
    $stmt->close();

    echo json_encode([
        'status' => 'ok',
        'data'   => [
            'id'                    => (string)$row['id'],
            'nim'                   => $row['nim'],
            'nama'                  => $row['nama'],
            'prodi_id'              => $row['prodi_id'] !== null ? (string)$row['prodi_id'] : null,
            'nama_prodi'            => $row['nama_prodi'] ?? '',
            'nama_fakultas'         => $row['nama_fakultas'] ?? '',
            'alamat'                => $row['alamat'] ?? '',
            'user_id'               => (string)$row['user_id'],
            'is_active'             => (int)$row['is_active'],
            'must_change_password'  => (int)$row['must_change_password']
        ]
    ]);

} else {
    http_response_code(403);
    echo json_encode(['status' => 'error', 'message' => 'Role Anda tidak memiliki akses ke data ini']);
}

$conn->close();
