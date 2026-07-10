<?php
// ============================================================
// get_mahasiswa.php — Ambil data mahasiswa
//   Admin  : GET semua (JOIN ke users untuk is_active, must_change_password)
//   User   : GET berdasarkan user_id
// ============================================================

require_once 'koneksi.php';

if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    http_response_code(405);
    echo json_encode(['status' => 'error', 'message' => 'Method tidak diizinkan']);
    exit();
}

$role   = trim($_GET['role']    ?? '');
$userId = trim($_GET['user_id'] ?? '');

if ($role === 'admin') {
    // --- Admin: ambil semua mahasiswa + info akun ---
    $sql = "SELECT m.id, m.nim, m.nama, m.jurusan, m.alamat,
                   m.user_id,
                   u.is_active,
                   u.must_change_password
            FROM mahasiswa m
            JOIN users u ON u.id = m.user_id
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
            'id'                  => (string)$row['id'],
            'nim'                 => $row['nim'],
            'nama'                => $row['nama'],
            'jurusan'             => $row['jurusan'],
            'alamat'              => $row['alamat'] ?? '',
            'user_id'             => (string)$row['user_id'],
            'is_active'           => (int)$row['is_active'],
            'must_change_password' => (int)$row['must_change_password']
        ];
    }

    echo json_encode([
        'status' => 'ok',
        'data'   => $data,
        'total'  => count($data)
    ]);

} elseif ($role === 'user' && !empty($userId)) {
    // --- Mahasiswa: ambil data diri sendiri ---
    $stmt = $conn->prepare(
        "SELECT m.id, m.nim, m.nama, m.jurusan, m.alamat,
                m.user_id,
                u.is_active,
                u.must_change_password
         FROM mahasiswa m
         JOIN users u ON u.id = m.user_id
         WHERE m.user_id = ?
         LIMIT 1"
    );
    $stmt->bind_param('i', $userId);
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
            'id'                   => (string)$row['id'],
            'nim'                  => $row['nim'],
            'nama'                 => $row['nama'],
            'jurusan'              => $row['jurusan'],
            'alamat'               => $row['alamat'] ?? '',
            'user_id'              => (string)$row['user_id'],
            'is_active'            => (int)$row['is_active'],
            'must_change_password' => (int)$row['must_change_password']
        ]
    ]);

} else {
    echo json_encode(['status' => 'error', 'message' => 'Parameter role atau user_id tidak valid']);
}

$conn->close();