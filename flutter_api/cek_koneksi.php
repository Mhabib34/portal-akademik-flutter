<?php
// ============================================================
// cek_koneksi.php — Cek status API & database
// ============================================================

require_once 'koneksi.php';

// Coba query sederhana untuk memastikan DB berjalan
$result = $conn->query("SELECT 1 AS ok");

if ($result && $result->fetch_assoc()['ok'] == 1) {
    echo json_encode([
        'status'  => 'ok',
        'message' => 'API dan database berjalan normal',
        'time'    => date('Y-m-d H:i:s')
    ]);
} else {
    http_response_code(500);
    echo json_encode([
        'status'  => 'error',
        'message' => 'Database tidak merespons'
    ]);
}

$conn->close();