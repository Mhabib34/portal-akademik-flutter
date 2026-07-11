<?php
// ============================================================
// update_mahasiswa.php — Update data mahasiswa (admin only)
// ============================================================

require_once 'koneksi.php';
require_once 'auth_helper.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode(['status' => 'error', 'message' => 'Method tidak diizinkan']);
    exit();
}

$currentUser = requireAuth($conn);
requireRole($currentUser, ['admin']);

$id      = trim($_POST['id']      ?? '');
$nim     = trim($_POST['nim']     ?? '');
$nama    = trim($_POST['nama']    ?? '');
$prodiId = trim($_POST['prodi_id'] ?? '');
$alamat  = trim($_POST['alamat']  ?? '');

if (empty($id) || empty($nim) || empty($nama) || empty($prodiId)) {
    echo json_encode(['status' => 'error', 'message' => 'ID, NIM, nama, dan prodi_id wajib diisi']);
    exit();
}

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

$conn->begin_transaction();

try {
    $stmtMhs = $conn->prepare(
        "UPDATE mahasiswa SET nim = ?, nama = ?, prodi_id = ?, alamat = ? WHERE id = ?"
    );
    $stmtMhs->bind_param('ssisi', $nim, $nama, $prodiId, $alamat, $id);
    $stmtMhs->execute();
    $stmtMhs->close();

    $stmtUser = $conn->prepare("UPDATE users SET nama = ? WHERE id = ?");
    $stmtUser->bind_param('si', $nama, $userId);
    $stmtUser->execute();
    $stmtUser->close();

    if ($nim !== $nimLama) {
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

    echo json_encode(['status' => 'ok', 'message' => 'Data mahasiswa berhasil diperbarui']);

} catch (Exception $e) {
    $conn->rollback();
    echo json_encode(['status' => 'error', 'message' => 'Gagal memperbarui data: ' . $e->getMessage()]);
}

$conn->close();
