<?php
// ============================================================
// get_dosen.php — Ambil data dosen
//   Admin : semua data
//   Dosen : data sendiri saja
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
    $sql = "SELECT d.id, d.nidn, d.nama, d.no_hp,
                   d.user_id, u.is_active, u.must_change_password
            FROM dosen d
            JOIN users u ON u.id = d.user_id
            ORDER BY d.nama ASC";

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
            'nidn'                  => $row['nidn'],
            'nama'                  => $row['nama'],
            'no_hp'                 => $row['no_hp'] ?? '',
            'user_id'               => (string)$row['user_id'],
            'is_active'             => (int)$row['is_active'],
            'must_change_password'  => (int)$row['must_change_password']
        ];
    }

    echo json_encode(['status' => 'ok', 'data' => $data, 'total' => count($data)]);

} elseif ($currentUser['role'] === 'dosen') {
    $stmt = $conn->prepare(
        "SELECT d.id, d.nidn, d.nama, d.no_hp,
                d.user_id, u.is_active, u.must_change_password
         FROM dosen d
         JOIN users u ON u.id = d.user_id
         WHERE d.user_id = ?
         LIMIT 1"
    );
    $stmt->bind_param('i', $currentUser['id']);
    $stmt->execute();
    $result = $stmt->get_result();

    if ($result->num_rows === 0) {
        echo json_encode(['status' => 'error', 'message' => 'Data dosen tidak ditemukan']);
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
            'nidn'                  => $row['nidn'],
            'nama'                  => $row['nama'],
            'no_hp'                 => $row['no_hp'] ?? '',
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
