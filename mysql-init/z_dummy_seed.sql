-- ============================================================
-- PORTAL AKADEMIK MAHASISWA — z_dummy_seed.sql
-- Menambahkan data dummy lengkap untuk semua tabel untuk keperluan development.
-- Menjamin setiap fitur bisa di-test dengan data yang "real".
-- ============================================================

USE portal_mahasiswa;

-- 1. FAKULTAS (id 1 sudah ada: Fakultas Ilmu Komputer)
INSERT INTO fakultas (nama_fakultas) VALUES 
('Fakultas Ekonomi dan Bisnis'),
('Fakultas Teknik'),
('Fakultas Bahasa dan Sastra');

-- 2. PRODI (id 1 & 2 sudah ada: Teknik Informatika, Sistem Informasi)
INSERT INTO prodi (fakultas_id, nama_prodi) VALUES 
(2, 'Manajemen'),
(2, 'Akuntansi'),
(3, 'Teknik Sipil'),
(3, 'Teknik Mesin'),
(4, 'Sastra Inggris');

-- 3. USERS (Dosen & Mahasiswa)
-- Asumsi ID admin = 1, sehingga ID dosen mulai 2, mahasiswa mulai 5.
INSERT INTO users (id, nama, username, password, role, must_change_password) VALUES 
(2, 'Dr. Budi Santoso, M.Kom.', 'budi.dosen', 'password123', 'dosen', 0),
(3, 'Prof. Siti Aminah, M.T.', 'siti.dosen', 'password123', 'dosen', 0),
(4, 'Hendra Gunawan, Ph.D', 'hendra.dosen', 'password123', 'dosen', 0),

(5, 'Andi Wijaya', '2010114001', 'password123', 'user', 0),
(6, 'Rina Melati', '2010114002', 'password123', 'user', 0),
(7, 'Bambang Pamungkas', '2010114003', 'password123', 'user', 0),
(8, 'Citra Kirana', '2010114004', 'password123', 'user', 0),
(9, 'Dewi Lestari', '2010114005', 'password123', 'user', 0);

-- 4. DOSEN
INSERT INTO dosen (nidn, nama, no_hp, user_id) VALUES 
('1001001001', 'Dr. Budi Santoso, M.Kom.', '081234567890', 2),
('1001001002', 'Prof. Siti Aminah, M.T.', '081298765432', 3),
('1001001003', 'Hendra Gunawan, Ph.D', '081223344556', 4);

-- 5. MAHASISWA
INSERT INTO mahasiswa (nim, nama, prodi_id, alamat, user_id) VALUES 
('2010114001', 'Andi Wijaya', 1, 'Jl. Mawar No 1, Jakarta', 5),
('2010114002', 'Rina Melati', 1, 'Jl. Melati No 2, Bandung', 6),
('2010114003', 'Bambang Pamungkas', 2, 'Jl. Kenangan No 3, Surabaya', 7),
('2010114004', 'Citra Kirana', 3, 'Jl. Sudirman No 4, Malang', 8),
('2010114005', 'Dewi Lestari', 4, 'Jl. Thamrin No 5, Semarang', 9);

-- 6. TAHUN AJARAN (id 1 sudah ada: 2025/2026 Ganjil, Aktif)
INSERT INTO tahun_ajaran (nama, semester, is_aktif) VALUES 
('2024/2025', 'Genap', 0),
('2024/2025', 'Ganjil', 0);

-- 7. MATA KULIAH
INSERT INTO mata_kuliah (kode_mk, nama_mk, sks, prodi_id, semester_ke, deskripsi) VALUES 
('IF101', 'Algoritma dan Pemrograman', 3, 1, 1, 'Dasar-dasar logika pemrograman menggunakan C/C++'),
('IF102', 'Basis Data', 3, 1, 2, 'Pengenalan ERD, Normalisasi, dan Query SQL'),
('IF103', 'Pemrograman Web', 3, 1, 3, 'Pengenalan HTML, CSS, JavaScript, dan framework web'),
('SI101', 'Pengantar Sistem Informasi', 2, 2, 1, 'Konsep dasar sistem informasi dalam organisasi'),
('SI102', 'Manajemen Proyek TI', 3, 2, 4, 'Siklus hidup manajemen proyek dan metodologi Agile'),
('MJ101', 'Pengantar Manajemen', 2, 3, 1, 'Dasar ilmu manajemen bisnis'),
('AK101', 'Akuntansi Keuangan Dasar', 3, 4, 1, 'Jurnal, buku besar, neraca keuangan');

-- 8. RUANG
INSERT INTO ruang (nama_ruang, gedung, kapasitas) VALUES 
('A.101', 'Gedung A', 40),
('A.102', 'Gedung A', 40),
('B.201', 'Gedung B', 50),
('Lab Komputer 1', 'Gedung C', 30),
('Lab Jaringan', 'Gedung C', 25);

-- 9. KELAS (ROMBEL)
INSERT INTO kelas (mata_kuliah_id, tahun_ajaran_id, dosen_id, nama_kelas, kapasitas) VALUES 
(1, 1, 1, 'TI-A', 40), -- Algoritma & Pemrograman (Budi Santoso)
(2, 1, 2, 'TI-A', 40), -- Basis Data (Siti Aminah)
(3, 1, 1, 'TI-B', 40), -- Pemrograman Web (Budi Santoso)
(4, 1, 2, 'SI-A', 40), -- Pengantar SI (Siti Aminah)
(5, 1, 3, 'SI-B', 40), -- Manajemen Proyek TI (Hendra Gunawan)
(6, 1, 3, 'MJ-A', 50); -- Pengantar Manajemen (Hendra Gunawan)

-- 10. JADWAL
INSERT INTO jadwal (kelas_id, ruang_id, hari, jam_mulai, jam_selesai) VALUES 
(1, 4, 'Senin', '08:00:00', '10:30:00'),  -- Algoritma di Lab Komp 1
(2, 1, 'Selasa', '10:00:00', '12:30:00'), -- Basis Data di A.101
(3, 4, 'Rabu', '13:00:00', '15:30:00'),   -- Pemrograman Web di Lab Komp 1
(4, 2, 'Kamis', '08:00:00', '09:40:00'),  -- Pengantar SI di A.102
(5, 3, 'Jumat', '09:00:00', '11:30:00'),  -- Manajemen Proyek di B.201
(6, 1, 'Senin', '13:00:00', '14:40:00');  -- Pengantar Manajemen di A.101

-- 11. KRS
-- Tahun Ajaran 1 = 2025/2026 Ganjil (Aktif)
INSERT INTO krs (mahasiswa_id, tahun_ajaran_id, status, catatan_admin) VALUES 
(1, 1, 'disetujui', 'Telah dicek oleh Dosen Wali'), -- Andi Wijaya (Disetujui)
(2, 1, 'disetujui', 'Telah dicek oleh Dosen Wali'), -- Rina Melati (Disetujui)
(3, 1, 'menunggu', NULL),                           -- Bambang Pamungkas (Menunggu)
(4, 1, 'ditolak', 'SKS melebihi batas maksimal');   -- Citra Kirana (Ditolak)

-- 12. KRS_DETAIL (Daftar mata kuliah yang diambil)
INSERT INTO krs_detail (krs_id, kelas_id) VALUES 
(1, 1), -- Andi ambil Algoritma
(1, 2), -- Andi ambil Basis Data
(1, 3), -- Andi ambil Pemrograman Web
(2, 2), -- Rina ambil Basis Data
(2, 4), -- Rina ambil Pengantar SI
(3, 4), -- Bambang ambil Pengantar SI
(3, 5), -- Bambang ambil Manajemen Proyek
(4, 1), -- Citra ambil Algoritma
(4, 6); -- Citra ambil Pengantar Manajemen

-- 13. NILAI (Hanya yang KRS-nya disetujui, contoh untuk beberapa kelas)
INSERT INTO nilai (mahasiswa_id, kelas_id, tugas, quiz_1, quiz_2, uts, kehadiran, uas, nilai_angka, nilai_huruf, bobot) VALUES 
-- Nilai Andi Wijaya
(1, 1, 85.0, 80.0, 85.0, 90.0, 100.0, 88.0, 87.5, 'A', 4.0),
(1, 2, 75.0, 70.0, 75.0, 80.0, 100.0, 78.0, 77.0, 'B', 3.0),
-- Nilai Rina Melati
(2, 2, 90.0, 95.0, 85.0, 92.0, 100.0, 95.0, 93.0, 'A', 4.0),
(2, 4, 65.0, 70.0, 60.0, 75.0, 85.0,  70.0, 70.5, 'B', 3.0);
