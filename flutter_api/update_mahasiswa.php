<?php
// ============================================================
// update_mahasiswa.php — Update data mahasiswa (admin only)
// ============================================================

require_once 'koneksi.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode(['status' => 'error', 'message' => 'Method tidak diizinkan']);
    exit();
}

$id      = trim($_POST['id']      ?? '');
$nim     = trim($_POST['nim']     ?? '');
$nama    = trim($_POST['nama']    ?? '');
$jurusan = trim($_POST['jurusan'] ?? '');
$alamat  = trim($_POST['alamat']  ?? '');

// Validasi input
if (empty($id) || empty($nim) || empty($nama) || empty($jurusan)) {
    echo json_encode(['status' => 'error', 'message' => 'ID, NIM, nama, dan jurusan wajib diisi']);
    exit();
}

// Ambil data mahasiswa lama untuk mendapatkan user_id & nim lama
$cek = $conn->prepare("SELECT user_id, nim FROM mahasiswa WHERE id = ? LIMIT 1");
$cek->bind_param('i', $id);
$cek->execute();
$result = $cek->get_result();
if ($result->num_rows === 0) {
    echo json_encode(['status' => 'error', 'message' => 'Data mahasiswa tidak ditemukan']);
    $cek->close();
    $conn->close();
    exit();
}
$existing = $result->fetch_assoc();
$userId   = $existing['user_id'];
$nimLama  = $existing['nim'];
$cek->close();

// Cek duplikat NIM (kecuali milik sendiri)
$cekNim = $conn->prepare("SELECT id FROM mahasiswa WHERE nim = ? AND id != ? LIMIT 1");
$cekNim->bind_param('si', $nim, $id);
$cekNim->execute();
$cekNim->store_result();
if ($cekNim->num_rows > 0) {
    echo json_encode(['status' => 'error', 'message' => 'NIM sudah digunakan mahasiswa lain']);
    $cekNim->close();
    $conn->close();
    exit();
}
$cekNim->close();

// Mulai transaksi
$conn->begin_transaction();

try {
    // Update tabel mahasiswa
    $stmtMhs = $conn->prepare(
        "UPDATE mahasiswa SET nim = ?, nama = ?, jurusan = ?, alamat = ? WHERE id = ?"
    );
    $stmtMhs->bind_param('ssssi', $nim, $nama, $jurusan, $alamat, $id);
    $stmtMhs->execute();
    $stmtMhs->close();

    // Update nama di tabel users (username tetap menggunakan NIM lama,
    // admin bisa reset password terpisah — sesuai spesifikasi)
    $stmtUser = $conn->prepare("UPDATE users SET nama = ? WHERE id = ?");
    $stmtUser->bind_param('si', $nama, $userId);
    $stmtUser->execute();
    $stmtUser->close();

    // Jika NIM berubah, update juga username di users
    if ($nim !== $nimLama) {
        // Cek username baru tidak bentrok
        $cekUsr = $conn->prepare("SELECT id FROM users WHERE username = ? AND id != ? LIMIT 1");
        $cekUsr->bind_param('si', $nim, $userId);
        $cekUsr->execute();
        $cekUsr->store_result();
        if ($cekUsr->num_rows > 0) {
            $conn->rollback();
            echo json_encode(['status' => 'error', 'message' => 'Username baru (NIM baru) sudah digunakan']);
            $cekUsr->close();
            $conn->close();
            exit();
        }
        $cekUsr->close();

        $stmtUname = $conn->prepare("UPDATE users SET username = ? WHERE id = ?");
        $stmtUname->bind_param('si', $nim, $userId);
        $stmtUname->execute();
        $stmtUname->close();
    }

    $conn->commit();

    echo json_encode([
        'status'  => 'ok',
        'message' => 'Data mahasiswa berhasil diperbarui'
    ]);

} catch (Exception $e) {
    $conn->rollback();
    echo json_encode(['status' => 'error', 'message' => 'Gagal memperbarui data: ' . $e->getMessage()]);
}

$conn->close();