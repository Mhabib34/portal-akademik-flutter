<?php
// ============================================================
// koneksi.php — Koneksi database + CORS header
// ============================================================

// --- CORS Header (izinkan semua origin untuk development) ---
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization");
header("Content-Type: application/json; charset=UTF-8");

// Tangani preflight OPTIONS request
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

// --- Konfigurasi Database ---
define('DB_HOST', 'mysql');
define('DB_USER', 'root');        // sesuaikan dengan user MySQL Anda
define('DB_PASS', 'rootpassword');            // sesuaikan dengan password MySQL Anda
define('DB_NAME', 'portal_mahasiswa');

// --- Buat koneksi ---
$conn = new mysqli(DB_HOST, DB_USER, DB_PASS, DB_NAME);

// --- Cek koneksi ---
if ($conn->connect_error) {
    http_response_code(500);
    echo json_encode([
        'status'  => 'error',
        'message' => 'Koneksi database gagal: ' . $conn->connect_error
    ]);
    exit();
}

// Set charset
$conn->set_charset('utf8mb4');