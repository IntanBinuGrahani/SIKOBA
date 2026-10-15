-- =====================================================
-- SIKOBA - Sistem Informasi Kontrol Obat Puskesmas
-- Database untuk MySQL / MariaDB (phpMyAdmin)
-- =====================================================

CREATE DATABASE IF NOT EXISTS sikoba
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE sikoba;

SET FOREIGN_KEY_CHECKS = 0;
DROP TABLE IF EXISTS laporan, transaksi_detail, stok_keluar, stok_masuk, batch_obat, obat, pengguna;
SET FOREIGN_KEY_CHECKS = 1;

-- -----------------------------------------------------
-- 1. Tabel pengguna
-- -----------------------------------------------------
CREATE TABLE pengguna (
  id_pengguna INT UNSIGNED NOT NULL AUTO_INCREMENT,
  nama        VARCHAR(100) NOT NULL,
  username    VARCHAR(50)  NOT NULL,
  password    VARCHAR(255) NOT NULL,           -- simpan hasil password_hash(), bukan teks biasa
  peran       ENUM('admin','petugas') NOT NULL DEFAULT 'petugas',
  no_hp       VARCHAR(20)  DEFAULT NULL,
  email       VARCHAR(100) DEFAULT NULL,
  created_at  TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id_pengguna),
  UNIQUE KEY uq_pengguna_username (username),
  UNIQUE KEY uq_pengguna_email (email)
) ENGINE=InnoDB;

-- -----------------------------------------------------
-- 2. Tabel obat (data master)
-- -----------------------------------------------------
CREATE TABLE obat (
  id_obat      INT UNSIGNED NOT NULL AUTO_INCREMENT,
  nama_obat    VARCHAR(150) NOT NULL,
  satuan       VARCHAR(30)  NOT NULL,          -- tablet, kapsul, botol, strip, dll
  kategori     VARCHAR(50)  DEFAULT NULL,
  stok_minimum INT UNSIGNED NOT NULL DEFAULT 0,
  deskripsi    TEXT DEFAULT NULL,
  created_at   TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id_obat),
  KEY idx_obat_nama (nama_obat)
) ENGINE=InnoDB;

-- -----------------------------------------------------
-- 3. Tabel batch_obat (stok per batch + kedaluwarsa)
-- -----------------------------------------------------
CREATE TABLE batch_obat (
  id_batch            INT UNSIGNED NOT NULL AUTO_INCREMENT,
  id_obat             INT UNSIGNED NOT NULL,
  jumlah              INT UNSIGNED NOT NULL DEFAULT 0,   -- sisa stok batch
  tanggal_masuk       DATE NOT NULL,
  tanggal_kedaluwarsa DATE NOT NULL,
  supplier            VARCHAR(100) DEFAULT NULL,
  created_at          TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id_batch),
  KEY idx_batch_obat (id_obat),
  KEY idx_batch_exp (tanggal_kedaluwarsa),
  CONSTRAINT fk_batch_obat FOREIGN KEY (id_obat)
    REFERENCES obat (id_obat) ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB;

-- -----------------------------------------------------
-- 4. Tabel stok_masuk
-- -----------------------------------------------------
CREATE TABLE stok_masuk (
  id_masuk      INT UNSIGNED NOT NULL AUTO_INCREMENT,
  id_obat       INT UNSIGNED NOT NULL,
  id_batch      INT UNSIGNED NOT NULL,
  jumlah        INT UNSIGNED NOT NULL,
  tanggal_masuk DATE NOT NULL,
  supplier      VARCHAR(100) DEFAULT NULL,
  petugas       INT UNSIGNED NOT NULL,          -- FK ke pengguna
  keterangan    VARCHAR(255) DEFAULT NULL,
  created_at    TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id_masuk),
  KEY idx_masuk_obat (id_obat),
  KEY idx_masuk_batch (id_batch),
  KEY idx_masuk_petugas (petugas),
  CONSTRAINT fk_masuk_obat FOREIGN KEY (id_obat)
    REFERENCES obat (id_obat) ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT fk_masuk_batch FOREIGN KEY (id_batch)
    REFERENCES batch_obat (id_batch) ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT fk_masuk_petugas FOREIGN KEY (petugas)
    REFERENCES pengguna (id_pengguna) ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB;

-- -----------------------------------------------------
-- 5. Tabel stok_keluar
-- -----------------------------------------------------
CREATE TABLE stok_keluar (
  id_keluar     INT UNSIGNED NOT NULL AUTO_INCREMENT,
  id_obat       INT UNSIGNED NOT NULL,
  id_batch      INT UNSIGNED NOT NULL,
  jumlah        INT UNSIGNED NOT NULL,
  tanggal_keluar DATE NOT NULL,
  tujuan        ENUM('pemakaian','distribusi') NOT NULL DEFAULT 'pemakaian',
  petugas       INT UNSIGNED NOT NULL,          -- FK ke pengguna
  keterangan    VARCHAR(255) DEFAULT NULL,
  created_at    TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id_keluar),
  KEY idx_keluar_obat (id_obat),
  KEY idx_keluar_batch (id_batch),
  KEY idx_keluar_petugas (petugas),
  CONSTRAINT fk_keluar_obat FOREIGN KEY (id_obat)
    REFERENCES obat (id_obat) ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT fk_keluar_batch FOREIGN KEY (id_batch)
    REFERENCES batch_obat (id_batch) ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT fk_keluar_petugas FOREIGN KEY (petugas)
    REFERENCES pengguna (id_pengguna) ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB;

-- -----------------------------------------------------
-- 6. Tabel transaksi_detail
-- id_transaksi merujuk ke stok_masuk.id_masuk ATAU stok_keluar.id_keluar
-- tergantung jenis_transaksi, sehingga tidak dibuat FOREIGN KEY langsung.
-- -----------------------------------------------------
CREATE TABLE transaksi_detail (
  id_detail       INT UNSIGNED NOT NULL AUTO_INCREMENT,
  id_transaksi    INT UNSIGNED NOT NULL,
  id_batch        INT UNSIGNED NOT NULL,
  jumlah          INT UNSIGNED NOT NULL,
  jenis_transaksi ENUM('masuk','keluar') NOT NULL,
  tanggal         DATE NOT NULL,
  keterangan      VARCHAR(255) DEFAULT NULL,
  petugas         INT UNSIGNED NOT NULL,        -- FK ke pengguna
  PRIMARY KEY (id_detail),
  KEY idx_detail_transaksi (jenis_transaksi, id_transaksi),
  KEY idx_detail_batch (id_batch),
  KEY idx_detail_petugas (petugas),
  CONSTRAINT fk_detail_batch FOREIGN KEY (id_batch)
    REFERENCES batch_obat (id_batch) ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT fk_detail_petugas FOREIGN KEY (petugas)
    REFERENCES pengguna (id_pengguna) ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB;

-- -----------------------------------------------------
-- 7. Tabel laporan
-- -----------------------------------------------------
CREATE TABLE laporan (
  id_laporan     INT UNSIGNED NOT NULL AUTO_INCREMENT,
  jenis_laporan  ENUM('harian','mingguan','bulanan') NOT NULL,
  periode_mulai  DATE NOT NULL,
  periode_selesai DATE NOT NULL,
  dibuat_oleh    INT UNSIGNED NOT NULL,         -- FK ke pengguna
  tanggal_dibuat DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  file_laporan   VARCHAR(255) DEFAULT NULL,     -- path file PDF / Excel
  created_at     TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id_laporan),
  KEY idx_laporan_user (dibuat_oleh),
  CONSTRAINT fk_laporan_user FOREIGN KEY (dibuat_oleh)
    REFERENCES pengguna (id_pengguna) ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB;

-- =====================================================
-- VIEW: status stok per obat (Aman / Stok Tipis / Habis)
-- =====================================================
CREATE OR REPLACE VIEW v_stok_obat AS
SELECT
  o.id_obat,
  o.nama_obat,
  o.satuan,
  o.stok_minimum,
  COALESCE(SUM(b.jumlah), 0) AS total_stok,
  CASE
    WHEN COALESCE(SUM(b.jumlah), 0) = 0 THEN 'Habis'
    WHEN COALESCE(SUM(b.jumlah), 0) <= o.stok_minimum THEN 'Stok Tipis'
    ELSE 'Aman'
  END AS status_stok
FROM obat o
LEFT JOIN batch_obat b ON b.id_obat = o.id_obat
GROUP BY o.id_obat, o.nama_obat, o.satuan, o.stok_minimum;

-- =====================================================
-- VIEW: status kedaluwarsa per batch (peringatan 90 hari)
-- =====================================================
CREATE OR REPLACE VIEW v_kedaluwarsa_batch AS
SELECT
  b.id_batch,
  o.nama_obat,
  b.jumlah,
  b.tanggal_kedaluwarsa,
  DATEDIFF(b.tanggal_kedaluwarsa, CURDATE()) AS sisa_hari,
  CASE
    WHEN b.tanggal_kedaluwarsa < CURDATE() THEN 'Kedaluwarsa'
    WHEN DATEDIFF(b.tanggal_kedaluwarsa, CURDATE()) <= 90 THEN 'Mendekati Kedaluwarsa'
    ELSE 'Aman'
  END AS status_exp
FROM batch_obat b
JOIN obat o ON o.id_obat = b.id_obat
WHERE b.jumlah > 0;

-- =====================================================
-- TRIGGER: update stok batch otomatis (sesuai flowchart
-- "Update Stok pada Database")
-- =====================================================
DELIMITER $$

CREATE TRIGGER trg_stok_masuk_ai
AFTER INSERT ON stok_masuk
FOR EACH ROW
BEGIN
  UPDATE batch_obat SET jumlah = jumlah + NEW.jumlah WHERE id_batch = NEW.id_batch;
  INSERT INTO transaksi_detail (id_transaksi, id_batch, jumlah, jenis_transaksi, tanggal, keterangan, petugas)
  VALUES (NEW.id_masuk, NEW.id_batch, NEW.jumlah, 'masuk', NEW.tanggal_masuk, NEW.keterangan, NEW.petugas);
END$$

CREATE TRIGGER trg_stok_keluar_bi
BEFORE INSERT ON stok_keluar
FOR EACH ROW
BEGIN
  DECLARE sisa INT;
  SELECT jumlah INTO sisa FROM batch_obat WHERE id_batch = NEW.id_batch;
  IF sisa IS NULL OR sisa < NEW.jumlah THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Stok tidak mencukupi';
  END IF;
END$$

CREATE TRIGGER trg_stok_keluar_ai
AFTER INSERT ON stok_keluar
FOR EACH ROW
BEGIN
  UPDATE batch_obat SET jumlah = jumlah - NEW.jumlah WHERE id_batch = NEW.id_batch;
  INSERT INTO transaksi_detail (id_transaksi, id_batch, jumlah, jenis_transaksi, tanggal, keterangan, petugas)
  VALUES (NEW.id_keluar, NEW.id_batch, NEW.jumlah, 'keluar', NEW.tanggal_keluar, NEW.keterangan, NEW.petugas);
END$$

DELIMITER ;

-- =====================================================
-- DATA AWAL (contoh)
-- Ganti password dengan hasil password_hash() dari PHP
-- =====================================================
INSERT INTO pengguna (nama, username, password, peran, no_hp, email) VALUES
('Administrator', 'admin', 'GANTI_DENGAN_PASSWORD_HASH', 'admin', '081234567890', 'admin@puskesmas.local'),
('Petugas Farmasi', 'petugas', 'GANTI_DENGAN_PASSWORD_HASH', 'petugas', '081298765432', 'petugas@puskesmas.local');

INSERT INTO obat (nama_obat, satuan, kategori, stok_minimum, deskripsi) VALUES
('Paracetamol 500 mg', 'tablet', 'Analgesik', 100, 'Pereda nyeri dan demam'),
('Amoxicillin 500 mg', 'kapsul', 'Antibiotik', 50, 'Antibiotik spektrum luas'),
('Oralit', 'sachet', 'Rehidrasi', 30, 'Cairan rehidrasi oral');
