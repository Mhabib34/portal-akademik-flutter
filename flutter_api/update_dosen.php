<?php
// ============================================================
// update_dosen.php — Update data dosen (admin only)
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

$id    = trim($_POST['id']    ?? '');
$nidn  = trim($_POST['nidn']  ?? '');
$nama  = trim($_POST['nama']  ?? '');
$noHp  = trim($_POST['no_hp'] ?? '');

if (empty($id) || empty($nidn) || empty($nama)) {
    echo json_encode(['status' => 'error', 'message' => 'ID, NIDN, dan nama wajib diisi']);
    exit();
}

$cek = $conn->prepare("SELECT user_id, nidn FROM dosen WHERE id = ? LIMIT 1");
$cek->bind_param('i', $id);
$cek->execute();
$result = $cek->get_result();
if ($result->num_rows === 0) {
    echo json_encode(['status' => 'error', 'message' => 'Data dosen tidak ditemukan']);
    $cek->close();
    $conn->close();
    exit();
}
$existing = $result->fetch_assoc();
$userId   = $existing['user_id'];
$nidnLama = $existing['nidn'];
$cek->close();

$cekNidn = $conn->prepare("SELECT id FROM dosen WHERE nidn = ? AND id != ? LIMIT 1");
$cekNidn->bind_param('si', $nidn, $id);
$cekNidn->execute();
$cekNidn->store_result();
if ($cekNidn->num_rows > 0) {
    echo json_encode(['status' => 'error', 'message' => 'NIDN sudah digunakan dosen lain']);
    $cekNidn->close();
    $conn->close();
    exit();
}
$cekNidn->close();

$conn->begin_transaction();

try {
    $stmtDosen = $conn->prepare(
        "UPDATE dosen SET nidn = ?, nama = ?, no_hp = ? WHERE id = ?"
    );
    $stmtDosen->bind_param('sssi', $nidn, $nama, $noHp, $id);
    $stmtDosen->execute();
    $stmtDosen->close();

    $stmtUser = $conn->prepare("UPDATE users SET nama = ? WHERE id = ?");
    $stmtUser->bind_param('si', $nama, $userId);
    $stmtUser->execute();
    $stmtUser->close();

    if ($nidn !== $nidnLama) {
        $cekUsr = $conn->prepare("SELECT id FROM users WHERE username = ? AND id != ? LIMIT 1");
        $cekUsr->bind_param('si', $nidn, $userId);
        $cekUsr->execute();
        $cekUsr->store_result();
        if ($cekUsr->num_rows > 0) {
            $conn->rollback();
            echo json_encode(['status' => 'error', 'message' => 'Username baru (NIDN baru) sudah digunakan']);
            $cekUsr->close();
            $conn->close();
            exit();
        }
        $cekUsr->close();

        $stmtUname = $conn->prepare("UPDATE users SET username = ? WHERE id = ?");
        $stmtUname->bind_param('si', $nidn, $userId);
        $stmtUname->execute();
        $stmtUname->close();
    }

    $conn->commit();

    echo json_encode(['status' => 'ok', 'message' => 'Data dosen berhasil diperbarui']);

} catch (Exception $e) {
    $conn->rollback();
    echo json_encode(['status' => 'error', 'message' => 'Gagal memperbarui data: ' . $e->getMessage()]);
}

$conn->close();
