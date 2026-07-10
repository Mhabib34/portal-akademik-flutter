-- ============================================================
-- PORTAL AKADEMIK MAHASISWA — init.sql (v3)
-- Mencakup: users, auth_tokens, mahasiswa, dosen, tahun_ajaran,
--           mata_kuliah, ruang, kelas, jadwal, krs, krs_detail, nilai
-- ============================================================

CREATE DATABASE IF NOT EXISTS portal_mahasiswa
  CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

USE portal_mahasiswa;

-- ------------------------------------------------------------
-- Tabel users
--   role: admin | dosen | user (user = mahasiswa, sesuai kode lama)
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS users (
  id                    INT AUTO_INCREMENT PRIMARY KEY,
  nama                  VARCHAR(100) NOT NULL,
  username              VARCHAR(50)  NOT NULL UNIQUE,
  password              VARCHAR(255) NOT NULL,
  role                  ENUM('admin','dosen','user') NOT NULL DEFAULT 'user',
  must_change_password  TINYINT(1)  NOT NULL DEFAULT 1,
  is_active             TINYINT(1)  NOT NULL DEFAULT 1,
  created_at            TIMESTAMP   NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- ------------------------------------------------------------
-- Tabel auth_tokens
--   Menyimpan token login (menggantikan pengiriman user_id/role
--   polos dari client). 1 user bisa punya lebih dari 1 token aktif
--   (login dari beberapa device) — kalau mau 1 device saja, tinggal
--   hapus token lama saat login baru di logic PHP-nya.
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS auth_tokens (
  id          INT AUTO_INCREMENT PRIMARY KEY,
  user_id     INT          NOT NULL,
  token       VARCHAR(64)  NOT NULL UNIQUE,
  expires_at  TIMESTAMP    NOT NULL,
  created_at  TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_token_user
    FOREIGN KEY (user_id) REFERENCES users(id)
    ON DELETE CASCADE
    ON UPDATE CASCADE,
  INDEX idx_token (token)
) ENGINE=InnoDB;

-- ------------------------------------------------------------
-- Tabel mahasiswa
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS mahasiswa (
  id       INT AUTO_INCREMENT PRIMARY KEY,
  nim      VARCHAR(20)  NOT NULL UNIQUE,
  nama     VARCHAR(100) NOT NULL,
  jurusan  VARCHAR(100) NOT NULL,
  alamat   TEXT,
  user_id  INT          NOT NULL UNIQUE,
  CONSTRAINT fk_mahasiswa_user
    FOREIGN KEY (user_id) REFERENCES users(id)
    ON DELETE CASCADE
    ON UPDATE CASCADE
) ENGINE=InnoDB;

-- ------------------------------------------------------------
-- Tabel dosen
--   username & password akun dosen = NIDN (mengikuti pola mahasiswa)
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS dosen (
  id       INT AUTO_INCREMENT PRIMARY KEY,
  nidn     VARCHAR(20)  NOT NULL UNIQUE,
  nama     VARCHAR(100) NOT NULL,
  no_hp    VARCHAR(20),
  user_id  INT          NOT NULL UNIQUE,
  CONSTRAINT fk_dosen_user
    FOREIGN KEY (user_id) REFERENCES users(id)
    ON DELETE CASCADE
    ON UPDATE CASCADE
) ENGINE=InnoDB;

-- ------------------------------------------------------------
-- Tabel tahun_ajaran
--   is_aktif menandai periode yang sedang berjalan (dipakai
--   sebagai default filter di app: hanya 1 baris boleh aktif)
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS tahun_ajaran (
  id        INT AUTO_INCREMENT PRIMARY KEY,
  nama      VARCHAR(20)  NOT NULL,          -- contoh: '2025/2026'
  semester  ENUM('Ganjil','Genap') NOT NULL,
  is_aktif  TINYINT(1)   NOT NULL DEFAULT 0,
  UNIQUE KEY uq_tahun_semester (nama, semester)
) ENGINE=InnoDB;

-- ------------------------------------------------------------
-- Tabel mata_kuliah (data master mata kuliah, belum terikat dosen/jadwal)
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS mata_kuliah (
  id           INT AUTO_INCREMENT PRIMARY KEY,
  kode_mk      VARCHAR(15)  NOT NULL UNIQUE,
  nama_mk      VARCHAR(150) NOT NULL,
  sks          TINYINT      NOT NULL,
  jurusan      VARCHAR(100) NOT NULL,
  semester_ke  TINYINT      NOT NULL,       -- semester ke berapa di kurikulum (1-8)
  deskripsi    TEXT
) ENGINE=InnoDB;

-- ------------------------------------------------------------
-- Tabel ruang
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS ruang (
  id          INT AUTO_INCREMENT PRIMARY KEY,
  nama_ruang  VARCHAR(50) NOT NULL UNIQUE,   -- contoh: 'R.301'
  gedung      VARCHAR(50),
  kapasitas   INT NOT NULL DEFAULT 40
) ENGINE=InnoDB;

-- ------------------------------------------------------------
-- Tabel kelas (rombel)
--   Satu mata_kuliah bisa punya beberapa kelas paralel (A, B, ...)
--   per tahun_ajaran, masing-masing diampu 1 dosen.
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS kelas (
  id              INT AUTO_INCREMENT PRIMARY KEY,
  mata_kuliah_id  INT NOT NULL,
  tahun_ajaran_id INT NOT NULL,
  dosen_id        INT NOT NULL,
  nama_kelas      VARCHAR(5) NOT NULL DEFAULT 'A',   -- 'A', 'B', dst
  kapasitas       INT NOT NULL DEFAULT 40,
  CONSTRAINT fk_kelas_mk
    FOREIGN KEY (mata_kuliah_id) REFERENCES mata_kuliah(id)
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT fk_kelas_tahun
    FOREIGN KEY (tahun_ajaran_id) REFERENCES tahun_ajaran(id)
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT fk_kelas_dosen
    FOREIGN KEY (dosen_id) REFERENCES dosen(id)
    ON DELETE RESTRICT ON UPDATE CASCADE,
  UNIQUE KEY uq_kelas (mata_kuliah_id, tahun_ajaran_id, nama_kelas)
) ENGINE=InnoDB;

-- ------------------------------------------------------------
-- Tabel jadwal
--   1 kelas bisa punya lebih dari 1 sesi/minggu (mis. teori + praktikum),
--   makanya jadwal dipisah dari kelas (1-to-many).
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS jadwal (
  id          INT AUTO_INCREMENT PRIMARY KEY,
  kelas_id    INT NOT NULL,
  ruang_id    INT NOT NULL,
  hari        ENUM('Senin','Selasa','Rabu','Kamis','Jumat','Sabtu') NOT NULL,
  jam_mulai   TIME NOT NULL,
  jam_selesai TIME NOT NULL,
  CONSTRAINT fk_jadwal_kelas
    FOREIGN KEY (kelas_id) REFERENCES kelas(id)
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT fk_jadwal_ruang
    FOREIGN KEY (ruang_id) REFERENCES ruang(id)
    ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB;

-- ------------------------------------------------------------
-- Tabel krs (header pengajuan per mahasiswa per tahun_ajaran)
--   Approve/reject dilakukan untuk keseluruhan pengajuan sekaligus.
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS krs (
  id               INT AUTO_INCREMENT PRIMARY KEY,
  mahasiswa_id     INT NOT NULL,
  tahun_ajaran_id  INT NOT NULL,
  status           ENUM('menunggu','disetujui','ditolak') NOT NULL DEFAULT 'menunggu',
  catatan_admin    VARCHAR(255),
  tanggal_ajuan    TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  tanggal_keputusan TIMESTAMP NULL,
  CONSTRAINT fk_krs_mahasiswa
    FOREIGN KEY (mahasiswa_id) REFERENCES mahasiswa(id)
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT fk_krs_tahun
    FOREIGN KEY (tahun_ajaran_id) REFERENCES tahun_ajaran(id)
    ON DELETE CASCADE ON UPDATE CASCADE,
  UNIQUE KEY uq_krs_mhs_tahun (mahasiswa_id, tahun_ajaran_id)
) ENGINE=InnoDB;

-- ------------------------------------------------------------
-- Tabel krs_detail (daftar kelas yang diambil dalam 1 pengajuan KRS)
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS krs_detail (
  id       INT AUTO_INCREMENT PRIMARY KEY,
  krs_id   INT NOT NULL,
  kelas_id INT NOT NULL,
  CONSTRAINT fk_krsdetail_krs
    FOREIGN KEY (krs_id) REFERENCES krs(id)
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT fk_krsdetail_kelas
    FOREIGN KEY (kelas_id) REFERENCES kelas(id)
    ON DELETE RESTRICT ON UPDATE CASCADE,
  UNIQUE KEY uq_krsdetail (krs_id, kelas_id)
) ENGINE=InnoDB;

-- ------------------------------------------------------------
-- Tabel nilai
--   1 baris = nilai 1 mahasiswa di 1 kelas (mata kuliah tertentu,
--   tahun ajaran tertentu — sudah tersirat lewat kelas_id).
--   Bobot tetap: Tugas 30% + UTS 30% + UAS 40% (dihitung di
--   aplikasi/PHP saat simpan, bukan generated column, supaya
--   mudah dijelaskan & tidak terikat versi MySQL tertentu).
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS nilai (
  id           INT AUTO_INCREMENT PRIMARY KEY,
  mahasiswa_id INT NOT NULL,
  kelas_id     INT NOT NULL,
  tugas        DECIMAL(5,2) NOT NULL DEFAULT 0,
  uts          DECIMAL(5,2) NOT NULL DEFAULT 0,
  uas          DECIMAL(5,2) NOT NULL DEFAULT 0,
  nilai_angka  DECIMAL(5,2) NOT NULL DEFAULT 0,   -- = tugas*0.3 + uts*0.3 + uas*0.4
  nilai_huruf  VARCHAR(2)   NOT NULL DEFAULT '-', -- A/B/C/D/E
  bobot        DECIMAL(3,2) NOT NULL DEFAULT 0,   -- untuk hitung IPK: A=4,B=3,C=2,D=1,E=0
  updated_at   TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT fk_nilai_mahasiswa
    FOREIGN KEY (mahasiswa_id) REFERENCES mahasiswa(id)
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT fk_nilai_kelas
    FOREIGN KEY (kelas_id) REFERENCES kelas(id)
    ON DELETE CASCADE ON UPDATE CASCADE,
  UNIQUE KEY uq_nilai (mahasiswa_id, kelas_id)
) ENGINE=InnoDB;

-- ------------------------------------------------------------
-- Seed: akun admin default
-- ------------------------------------------------------------
INSERT INTO users (nama, username, password, role, must_change_password, is_active)
VALUES ('Administrator', 'admin', 'admin123', 'admin', 0, 1);

-- ------------------------------------------------------------
-- Seed: tahun ajaran aktif contoh
-- ------------------------------------------------------------
INSERT INTO tahun_ajaran (nama, semester, is_aktif)
VALUES ('2025/2026', 'Ganjil', 1);