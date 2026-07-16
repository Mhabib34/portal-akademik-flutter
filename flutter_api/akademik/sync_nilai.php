<?php
require_once '../config/koneksi.php';

echo "<h1>Sinkronisasi Data KRS ke Tabel Nilai</h1>";

$insertNilai = $conn->prepare(
    "INSERT IGNORE INTO nilai (mahasiswa_id, kelas_id)
     SELECT krs.mahasiswa_id, kd.kelas_id 
     FROM krs_detail kd 
     JOIN krs ON krs.id = kd.krs_id
     WHERE krs.status = 'disetujui'"
);

if ($insertNilai->execute()) {
    $affected = $insertNilai->affected_rows;
    echo "<p>Berhasil! $affected data nilai mahasiswa baru telah ditambahkan dari KRS yang sudah disetujui sebelumnya.</p>";
} else {
    echo "<p>Gagal: " . $conn->error . "</p>";
}

$insertNilai->close();
$conn->close();
echo "<p>Silakan tutup halaman ini dan refresh aplikasi Flutter Anda.</p>";
