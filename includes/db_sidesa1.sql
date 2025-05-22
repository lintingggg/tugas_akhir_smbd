-- phpMyAdmin SQL Dump
-- version 5.2.0
-- https://www.phpmyadmin.net/
--
-- Host: localhost:3306
-- Generation Time: May 22, 2025 at 07:08 AM
-- Server version: 8.0.30
-- PHP Version: 8.3.12

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `db_sidesa1`
--

DELIMITER $$
--
-- Procedures
--
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_cari_penduduk` (IN `keyword` VARCHAR(100))   BEGIN
    SELECT * FROM view_penduduk
    WHERE nik LIKE CONCAT('%', keyword, '%')
       OR nama LIKE CONCAT('%', keyword, '%');
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_hapus_penduduk` (IN `p_nik` CHAR(16))   BEGIN
    DELETE FROM tb_penduduk WHERE nik = p_nik;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_laporan_penduduk_per_desa` ()   BEGIN
    DECLARE done INT DEFAULT 0;
    DECLARE v_no_kk CHAR(16);
    DECLARE v_desa VARCHAR(100);
    DECLARE v_total INT;

    DECLARE cur CURSOR FOR SELECT no_kk FROM tb_keluarga;
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;

    CREATE TEMPORARY TABLE IF NOT EXISTS temp_laporan (
        desa VARCHAR(100),
        jumlah INT
    );

    OPEN cur;
    REPEAT
        FETCH cur INTO v_no_kk;
        IF NOT done THEN
            SELECT COUNT(p.nik) INTO v_total
            FROM tb_penduduk p
            WHERE p.no_kk = v_no_kk;

            SELECT d.nama_desa INTO v_desa
            FROM tb_desa d
            JOIN tb_keluarga k ON k.no_kk = v_no_kk
            LIMIT 1;

            IF v_desa IS NOT NULL THEN
                INSERT INTO temp_laporan (desa, jumlah)
                VALUES (v_desa, v_total);
            END IF;
        END IF;
    UNTIL done END REPEAT;
    CLOSE cur;

    SELECT desa, SUM(jumlah) as total_penduduk FROM temp_laporan GROUP BY desa;
    DROP TEMPORARY TABLE temp_laporan;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_proses_surat` (IN `p_id_surat` INT, IN `p_status` ENUM('Diproses','Selesai','Ditolak'), IN `p_keterangan` TEXT)   BEGIN
    DECLARE v_nik CHAR(16);
    DECLARE v_nama VARCHAR(100);
    DECLARE v_status_lama ENUM('Diproses', 'Selesai', 'Ditolak');
    
    -- Ambil data surat sebelumnya
    SELECT s.status, s.nik, p.nama 
    INTO v_status_lama, v_nik, v_nama
    FROM tb_surat s
    JOIN tb_penduduk p ON s.nik = p.nik
    WHERE s.id_surat = p_id_surat;
    
    -- Update status surat
    UPDATE tb_surat SET status = p_status WHERE id_surat = p_id_surat;
    
    -- Tambahkan log aktivitas
    INSERT INTO tb_log_aktivitas (tabel, aksi, nik, keterangan)
    VALUES (
        'tb_surat', 
        CONCAT('Update status dari ', v_status_lama, ' ke ', p_status),
        v_nik,
        CONCAT('ID Surat: ', p_id_surat, ', Keterangan: ', p_keterangan)
    );
    
    SELECT CONCAT('Berhasil memproses surat untuk ', v_nama, ' (', v_nik, ')') AS message;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_statistik_penduduk` (IN `p_tahun_mulai` INT, IN `p_tahun_akhir` INT)   BEGIN
    DECLARE v_tahun INT;
    DECLARE v_done INT DEFAULT 0;
    
    -- Buat tabel sementara untuk menyimpan hasil statistik
    DROP TEMPORARY TABLE IF EXISTS temp_statistik;
    CREATE TEMPORARY TABLE temp_statistik (
        tahun INT,
        kelahiran INT,
        kematian INT,
        pindah_masuk INT,
        pindah_keluar INT,
        total_penduduk INT
    );
    
    -- Loop untuk setiap tahun yang diminta
    SET v_tahun = p_tahun_mulai;
    WHILE v_tahun <= p_tahun_akhir DO
        -- Hitung jumlah kelahiran (anggap tanggal_lahir di tahun tersebut)
        SET @kelahiran = 0;
        SELECT COUNT(*) INTO @kelahiran 
        FROM tb_penduduk 
        WHERE YEAR(tanggal_lahir) = v_tahun;
        
        -- Hitung jumlah kematian
        SET @kematian = 0;
        SELECT COUNT(*) INTO @kematian 
        FROM tb_mutasi 
        WHERE jenis_mutasi = 'Meninggal' AND YEAR(tanggal_mutasi) = v_tahun;
        
        -- Hitung jumlah pindah masuk
        SET @pindah_masuk = 0;
        SELECT COUNT(*) INTO @pindah_masuk 
        FROM tb_mutasi 
        WHERE jenis_mutasi = 'Masuk' AND YEAR(tanggal_mutasi) = v_tahun;
        
        -- Hitung jumlah pindah keluar
        SET @pindah_keluar = 0;
        SELECT COUNT(*) INTO @pindah_keluar 
        FROM tb_mutasi 
        WHERE jenis_mutasi = 'Keluar' AND YEAR(tanggal_mutasi) = v_tahun;
        
        -- Hitung total penduduk (simulasi untuk contoh)
        SET @total = @kelahiran + @pindah_masuk - @kematian - @pindah_keluar;
        
        -- Simpan data ke tabel sementara
        INSERT INTO temp_statistik 
        VALUES (v_tahun, @kelahiran, @kematian, @pindah_masuk, @pindah_keluar, @total);
        
        -- Increment tahun
        SET v_tahun = v_tahun + 1;
    END WHILE;
    
    -- Tampilkan hasil statistik
    SELECT * FROM temp_statistik ORDER BY tahun;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_tambah_keluarga` (IN `p_no_kk` CHAR(16), IN `p_nama_kepala` VARCHAR(100), IN `p_alamat` TEXT, IN `p_jumlah_anggota` INT)   BEGIN
    DECLARE v_counter INT DEFAULT 0;
    DECLARE v_nik_prefix CHAR(10);
    
    -- Tambahkan data keluarga
    INSERT INTO tb_keluarga (no_kk, nama_kepala_keluarga, alamat)
    VALUES (p_no_kk, p_nama_kepala, p_alamat);
    
    -- Generate prefix NIK dari KK (10 digit pertama)
    SET v_nik_prefix = LEFT(p_no_kk, 10);
    
    -- Loop untuk menambahkan anggota keluarga dummy jika diminta
    WHILE v_counter < p_jumlah_anggota DO
        -- Generate NIK unik dengan menambahkan counter
        INSERT INTO tb_penduduk (
            nik, 
            nama, 
            tempat_lahir, 
            tanggal_lahir, 
            jenis_kelamin, 
            status_perkawinan, 
            id_agama, 
            id_pekerjaan, 
            no_kk
        ) VALUES (
            CONCAT(v_nik_prefix, LPAD(v_counter, 6, '0')), 
            CONCAT('Anggota ', v_counter + 1), 
            'Tempat Lahir', 
            CURDATE(), 
            IF(v_counter % 2 = 0, 'Laki-laki', 'Perempuan'), 
            'Belum Kawin', 
            1, 
            1, 
            p_no_kk
        );
        
        SET v_counter = v_counter + 1;
    END WHILE;
    
    SELECT CONCAT('Berhasil menambahkan keluarga dengan ', p_jumlah_anggota, ' anggota') AS message;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_tambah_penduduk` (IN `p_nik` CHAR(16), IN `p_nama` VARCHAR(100), IN `p_tempat_lahir` VARCHAR(50), IN `p_tanggal_lahir` DATE, IN `p_jenis_kelamin` ENUM('Laki-laki','Perempuan'), IN `p_status_perkawinan` ENUM('Belum Kawin','Kawin','Cerai'), IN `p_id_agama` INT, IN `p_id_pekerjaan` INT, IN `p_no_kk` CHAR(16))   BEGIN
    INSERT INTO tb_penduduk (
        nik, nama, tempat_lahir, tanggal_lahir, jenis_kelamin,
        status_perkawinan, id_agama, id_pekerjaan, no_kk
    ) VALUES (
        p_nik, p_nama, p_tempat_lahir, p_tanggal_lahir, p_jenis_kelamin,
        p_status_perkawinan, p_id_agama, p_id_pekerjaan, p_no_kk
    );
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_update_penduduk` (IN `p_nik` CHAR(16), IN `p_nama` VARCHAR(100), IN `p_tempat_lahir` VARCHAR(50), IN `p_tanggal_lahir` DATE, IN `p_jenis_kelamin` ENUM('Laki-laki','Perempuan'), IN `p_status_perkawinan` ENUM('Belum Kawin','Kawin','Cerai'), IN `p_id_agama` INT, IN `p_id_pekerjaan` INT, IN `p_no_kk` CHAR(16))   BEGIN
    UPDATE tb_penduduk
    SET nama = p_nama,
        tempat_lahir = p_tempat_lahir,
        tanggal_lahir = p_tanggal_lahir,
        jenis_kelamin = p_jenis_kelamin,
        status_perkawinan = p_status_perkawinan,
        id_agama = p_id_agama,
        id_pekerjaan = p_id_pekerjaan,
        no_kk = p_no_kk
    WHERE nik = p_nik;
END$$

DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `tb_agama`
--

CREATE TABLE `tb_agama` (
  `id_agama` int NOT NULL,
  `nama_agama` varchar(50) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Dumping data for table `tb_agama`
--

INSERT INTO `tb_agama` (`id_agama`, `nama_agama`) VALUES
(1, 'Islam'),
(2, 'Kristen'),
(3, 'Katolik'),
(4, 'Hindu'),
(5, 'Buddha'),
(6, 'Konghucu');

-- --------------------------------------------------------

--
-- Table structure for table `tb_desa`
--

CREATE TABLE `tb_desa` (
  `id_desa` int NOT NULL,
  `nama_desa` varchar(100) NOT NULL,
  `kecamatan` varchar(100) NOT NULL,
  `kabupaten` varchar(100) NOT NULL,
  `provinsi` varchar(100) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Dumping data for table `tb_desa`
--

INSERT INTO `tb_desa` (`id_desa`, `nama_desa`, `kecamatan`, `kabupaten`, `provinsi`) VALUES
(1, 'Sukolilo', 'Labang', 'Bangkalan', 'Jawa Timur'),
(2, 'Burneh', 'Burneh', 'Bangkalan', 'Jawa Timur'),
(3, 'Socah', 'Socah', 'Bangkalan', 'Jawa Timur');

-- --------------------------------------------------------

--
-- Table structure for table `tb_keluarga`
--

CREATE TABLE `tb_keluarga` (
  `no_kk` char(16) NOT NULL,
  `nama_kepala_keluarga` varchar(100) NOT NULL,
  `alamat` text NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Dumping data for table `tb_keluarga`
--

INSERT INTO `tb_keluarga` (`no_kk`, `nama_kepala_keluarga`, `alamat`) VALUES
('3517010101010001', 'Ahmad Fauzi', 'Jl. Merpati No. 1, Sukolilo'),
('3517010101010002', 'Siti Aminah', 'Jl. Anggrek No. 2, Burneh'),
('3517010101010003', 'Budi Santoso', 'Jl. Mawar No. 3, Socah');

-- --------------------------------------------------------

--
-- Table structure for table `tb_log_aktivitas`
--

CREATE TABLE `tb_log_aktivitas` (
  `id_log` int NOT NULL,
  `tabel` varchar(50) NOT NULL,
  `aksi` varchar(20) NOT NULL,
  `nik` char(16) DEFAULT NULL,
  `waktu` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `keterangan` text
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Dumping data for table `tb_log_aktivitas`
--

INSERT INTO `tb_log_aktivitas` (`id_log`, `tabel`, `aksi`, `nik`, `waktu`, `keterangan`) VALUES
(1, 'tb_penduduk', 'INSERT', '3517010101010001', '2025-05-21 15:50:52', 'Penduduk baru dengan nama Ahmad Fauzi telah ditambahkan'),
(2, 'tb_penduduk', 'INSERT', '3517010101010002', '2025-05-21 15:50:52', 'Penduduk baru dengan nama Rina Fauzi telah ditambahkan'),
(3, 'tb_penduduk', 'INSERT', '3517010101010003', '2025-05-21 15:50:52', 'Penduduk baru dengan nama Dedi Amin telah ditambahkan'),
(4, 'tb_penduduk', 'INSERT', '3517010101010004', '2025-05-21 15:50:52', 'Penduduk baru dengan nama Siti Aminah telah ditambahkan'),
(5, 'tb_penduduk', 'INSERT', '3517010101010005', '2025-05-21 15:50:52', 'Penduduk baru dengan nama Budi Santoso telah ditambahkan'),
(6, 'tb_surat', 'INSERT', '3517010101010001', '2025-05-21 15:50:52', 'Pengajuan surat baru: Surat Keterangan Domisili dengan status Diproses'),
(7, 'tb_surat', 'INSERT', '3517010101010002', '2025-05-21 15:50:52', 'Pengajuan surat baru: Surat Keterangan Tidak Mampu dengan status Selesai'),
(8, 'tb_surat', 'INSERT', '3517010101010003', '2025-05-21 15:50:52', 'Pengajuan surat baru: Surat Keterangan Usaha dengan status Diproses'),
(9, 'tb_surat', 'INSERT', '3517010101010004', '2025-05-21 15:50:52', 'Pengajuan surat baru: Surat Keterangan Menikah dengan status Ditolak'),
(10, 'tb_mutasi', 'INSERT', '3517010101010001', '2025-05-21 15:50:52', 'Mutasi Keluar untuk penduduk Ahmad Fauzi pada tanggal 2024-12-10'),
(11, 'tb_mutasi', 'INSERT', '3517010101010003', '2025-05-21 15:50:52', 'Mutasi Masuk untuk penduduk Dedi Amin pada tanggal 2025-01-15'),
(12, 'tb_mutasi', 'INSERT', '3517010101010004', '2025-05-21 15:50:52', 'Mutasi Meninggal untuk penduduk Siti Aminah pada tanggal 2023-09-18'),
(13, 'tb_mutasi', 'INSERT', '3517010101010005', '2025-05-21 15:50:52', 'Mutasi Keluar untuk penduduk Budi Santoso pada tanggal 2025-04-01'),
(14, 'tb_penduduk', 'INSERT', '3517010101010006', '2025-05-21 16:30:26', 'Penduduk baru dengan nama MUHAMMAD IQBAL FAZA telah ditambahkan'),
(17, 'tb_mutasi', 'INSERT', '3517010101010006', '2025-05-21 19:03:08', 'Mutasi Meninggal untuk penduduk MUHAMMAD IQBAL FAZA pada tanggal 2025-05-22'),
(18, 'tb_penduduk', 'DELETE', '3517010101010006', '2025-05-21 19:03:08', 'Penduduk dengan nama MUHAMMAD IQBAL FAZA telah dihapus dari sistem'),
(21, 'tb_mutasi', 'INSERT', '3517010101010001', '2025-05-22 01:45:29', 'Mutasi Meninggal untuk penduduk Ahmad Fauzi pada tanggal 2025-05-22'),
(22, 'tb_penduduk', 'DELETE', '3517010101010001', '2025-05-22 01:45:29', 'Penduduk dengan nama Ahmad Fauzi telah dihapus dari sistem'),
(23, 'tb_penduduk', 'DELETE', '3517010101010004', '2025-05-22 01:45:42', 'Penduduk dengan nama Siti Aminah telah dihapus dari sistem'),
(24, 'tb_mutasi', 'INSERT', '3517010101010003', '2025-05-22 01:46:00', 'Mutasi Meninggal untuk penduduk Dedi Amin pada tanggal 2025-05-22'),
(25, 'tb_penduduk', 'DELETE', '3517010101010003', '2025-05-22 01:46:00', 'Penduduk dengan nama Dedi Amin telah dihapus dari sistem'),
(26, 'tb_penduduk', 'UPDATE', '3517010101010005', '2025-05-22 01:55:44', 'Data penduduk diperbarui: ID Agama: 3 -> 1; '),
(27, 'tb_penduduk', 'UPDATE', '3517010101010005', '2025-05-22 07:04:59', 'Data penduduk diperbarui: Status Perkawinan: Kawin -> Cerai; '),
(28, 'tb_penduduk', 'UPDATE', '3517010101010005', '2025-05-22 07:04:59', 'Mengubah data penduduk menjadi Budi Santoso');

-- --------------------------------------------------------

--
-- Table structure for table `tb_mutasi`
--

CREATE TABLE `tb_mutasi` (
  `id_mutasi` int NOT NULL,
  `nik` char(16) NOT NULL,
  `jenis_mutasi` enum('Masuk','Keluar','Meninggal') NOT NULL,
  `tanggal_mutasi` date NOT NULL,
  `keterangan` text
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Dumping data for table `tb_mutasi`
--

INSERT INTO `tb_mutasi` (`id_mutasi`, `nik`, `jenis_mutasi`, `tanggal_mutasi`, `keterangan`) VALUES
(4, '3517010101010005', 'Keluar', '2025-04-01', 'Pindah kerja ke Jakarta');

--
-- Triggers `tb_mutasi`
--
DELIMITER $$
CREATE TRIGGER `tr_after_insert_mutasi` AFTER INSERT ON `tb_mutasi` FOR EACH ROW BEGIN
    DECLARE v_nama VARCHAR(100);
    
    -- Ambil nama penduduk
    SELECT nama INTO v_nama FROM tb_penduduk WHERE nik = NEW.nik;
    
    -- Catat aktivitas mutasi
    INSERT INTO tb_log_aktivitas (tabel, aksi, nik, keterangan)
    VALUES (
        'tb_mutasi',
        'INSERT',
        NEW.nik,
        CONCAT('Mutasi ', NEW.jenis_mutasi, ' untuk penduduk ', v_nama, ' pada tanggal ', NEW.tanggal_mutasi)
    );
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `tb_pekerjaan`
--

CREATE TABLE `tb_pekerjaan` (
  `id_pekerjaan` int NOT NULL,
  `nama_pekerjaan` varchar(100) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Dumping data for table `tb_pekerjaan`
--

INSERT INTO `tb_pekerjaan` (`id_pekerjaan`, `nama_pekerjaan`) VALUES
(1, 'Petani'),
(2, 'Guru'),
(3, 'PNS'),
(4, 'Wiraswasta'),
(5, 'Karyawan Swasta'),
(6, 'Buruh'),
(7, 'Pelajar/Mahasiswa'),
(8, 'Tidak Bekerja');

-- --------------------------------------------------------

--
-- Table structure for table `tb_penduduk`
--

CREATE TABLE `tb_penduduk` (
  `nik` char(16) NOT NULL,
  `nama` varchar(100) NOT NULL,
  `tempat_lahir` varchar(50) NOT NULL,
  `tanggal_lahir` date NOT NULL,
  `jenis_kelamin` enum('Laki-laki','Perempuan') NOT NULL,
  `status_perkawinan` enum('Belum Kawin','Kawin','Cerai') NOT NULL,
  `id_agama` int NOT NULL,
  `id_pekerjaan` int NOT NULL,
  `no_kk` char(16) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Dumping data for table `tb_penduduk`
--

INSERT INTO `tb_penduduk` (`nik`, `nama`, `tempat_lahir`, `tanggal_lahir`, `jenis_kelamin`, `status_perkawinan`, `id_agama`, `id_pekerjaan`, `no_kk`) VALUES
('3517010101010002', 'Rina Fauzi', 'Bangkalan', '1985-08-15', 'Perempuan', 'Kawin', 1, 2, '3517010101010001'),
('3517010101010005', 'Budi Santoso', 'Bangkalan', '1990-01-12', 'Laki-laki', 'Cerai', 1, 3, '3517010101010003');

--
-- Triggers `tb_penduduk`
--
DELIMITER $$
CREATE TRIGGER `tr_after_insert_penduduk` AFTER INSERT ON `tb_penduduk` FOR EACH ROW BEGIN
    -- Mencatat aktivitas penambahan penduduk baru
    INSERT INTO tb_log_aktivitas (tabel, aksi, nik, keterangan)
    VALUES (
        'tb_penduduk',
        'INSERT',
        NEW.nik,
        CONCAT('Penduduk baru dengan nama ', NEW.nama, ' telah ditambahkan')
    );
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `tr_after_update_penduduk` AFTER UPDATE ON `tb_penduduk` FOR EACH ROW BEGIN
    DECLARE perubahan TEXT DEFAULT '';
    
    -- Cek perubahan data dan simpan dalam satu string
    IF OLD.nama != NEW.nama THEN
        SET perubahan = CONCAT(perubahan, 'Nama: ', OLD.nama, ' -> ', NEW.nama, '; ');
    END IF;
    
    IF OLD.tempat_lahir != NEW.tempat_lahir THEN
        SET perubahan = CONCAT(perubahan, 'Tempat Lahir: ', OLD.tempat_lahir, ' -> ', NEW.tempat_lahir, '; ');
    END IF;
    
    IF OLD.tanggal_lahir != NEW.tanggal_lahir THEN
        SET perubahan = CONCAT(perubahan, 'Tanggal Lahir: ', OLD.tanggal_lahir, ' -> ', NEW.tanggal_lahir, '; ');
    END IF;
    
    IF OLD.jenis_kelamin != NEW.jenis_kelamin THEN
        SET perubahan = CONCAT(perubahan, 'Jenis Kelamin: ', OLD.jenis_kelamin, ' -> ', NEW.jenis_kelamin, '; ');
    END IF;
    
    IF OLD.status_perkawinan != NEW.status_perkawinan THEN
        SET perubahan = CONCAT(perubahan, 'Status Perkawinan: ', OLD.status_perkawinan, ' -> ', NEW.status_perkawinan, '; ');
    END IF;
    
    IF OLD.id_agama != NEW.id_agama THEN
        SET perubahan = CONCAT(perubahan, 'ID Agama: ', OLD.id_agama, ' -> ', NEW.id_agama, '; ');
    END IF;
    
    IF OLD.id_pekerjaan != NEW.id_pekerjaan THEN
        SET perubahan = CONCAT(perubahan, 'ID Pekerjaan: ', OLD.id_pekerjaan, ' -> ', NEW.id_pekerjaan, '; ');
    END IF;
    
    IF OLD.no_kk != NEW.no_kk THEN
        SET perubahan = CONCAT(perubahan, 'No KK: ', OLD.no_kk, ' -> ', NEW.no_kk, '; ');
    END IF;
    
    -- Catat perubahan jika ada
    IF perubahan != '' THEN
        INSERT INTO tb_log_aktivitas (tabel, aksi, nik, keterangan)
        VALUES (
            'tb_penduduk',
            'UPDATE',
            NEW.nik,
            CONCAT('Data penduduk diperbarui: ', perubahan)
        );
    END IF;
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `tr_before_delete_penduduk` BEFORE DELETE ON `tb_penduduk` FOR EACH ROW BEGIN
    -- Tambahkan ke tabel mutasi sebagai meninggal jika belum ada record mutasi
    IF NOT EXISTS (SELECT 1 FROM tb_mutasi WHERE nik = OLD.nik AND jenis_mutasi = 'Meninggal') THEN
        INSERT INTO tb_mutasi (nik, jenis_mutasi, tanggal_mutasi, keterangan)
        VALUES (OLD.nik, 'Meninggal', CURDATE(), 'Data dihapus dari sistem');
    END IF;
    
    -- Catat aktivitas penghapusan penduduk
    INSERT INTO tb_log_aktivitas (tabel, aksi, nik, keterangan)
    VALUES (
        'tb_penduduk',
        'DELETE',
        OLD.nik,
        CONCAT('Penduduk dengan nama ', OLD.nama, ' telah dihapus dari sistem')
    );
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `tr_log_insert_penduduk` AFTER INSERT ON `tb_penduduk` FOR EACH ROW BEGIN
  INSERT INTO tb_log_aktivitas (tabel, aksi, nik, keterangan)
  VALUES (
    'tb_penduduk',
    'INSERT',
    NEW.nik,
    CONCAT('Data penduduk dengan NIK ', NEW.nik, ' ditambahkan.')
  );
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `trg_delete_penduduk` AFTER DELETE ON `tb_penduduk` FOR EACH ROW BEGIN
    INSERT INTO tb_log_aktivitas (tabel, aksi, nik, keterangan)
    VALUES ('tb_penduduk', 'DELETE', OLD.nik, CONCAT('Menghapus penduduk bernama ', OLD.nama));
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `trg_update_penduduk` AFTER UPDATE ON `tb_penduduk` FOR EACH ROW BEGIN
    INSERT INTO tb_log_aktivitas (tabel, aksi, nik, keterangan)
    VALUES ('tb_penduduk', 'UPDATE', NEW.nik, CONCAT('Mengubah data penduduk menjadi ', NEW.nama));
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `tb_surat`
--

CREATE TABLE `tb_surat` (
  `id_surat` int NOT NULL,
  `nik` char(16) NOT NULL,
  `jenis_surat` varchar(100) NOT NULL,
  `tanggal_pengajuan` date NOT NULL,
  `status` enum('Diproses','Selesai','Ditolak') NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Dumping data for table `tb_surat`
--

INSERT INTO `tb_surat` (`id_surat`, `nik`, `jenis_surat`, `tanggal_pengajuan`, `status`) VALUES
(2, '3517010101010002', 'Surat Keterangan Tidak Mampu', '2025-04-25', 'Selesai');

--
-- Triggers `tb_surat`
--
DELIMITER $$
CREATE TRIGGER `tr_after_insert_surat` AFTER INSERT ON `tb_surat` FOR EACH ROW BEGIN
    -- Catat aktivitas penambahan surat
    INSERT INTO tb_log_aktivitas (tabel, aksi, nik, keterangan)
    VALUES (
        'tb_surat',
        'INSERT',
        NEW.nik,
        CONCAT('Pengajuan surat baru: ', NEW.jenis_surat, ' dengan status ', NEW.status)
    );
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Stand-in structure for view `view_data_keluarga`
-- (See below for the actual view)
--
CREATE TABLE `view_data_keluarga` (
`alamat` text
,`jumlah_anggota` bigint
,`nama_kepala_keluarga` varchar(100)
,`no_kk` char(16)
);

-- --------------------------------------------------------

--
-- Stand-in structure for view `view_data_mutasi`
-- (See below for the actual view)
--
CREATE TABLE `view_data_mutasi` (
`id_mutasi` int
,`jenis_mutasi` enum('Masuk','Keluar','Meninggal')
,`keterangan` text
,`nama` varchar(100)
,`nik` char(16)
,`tanggal_mutasi` date
);

-- --------------------------------------------------------

--
-- Stand-in structure for view `view_data_penduduk`
-- (See below for the actual view)
--
CREATE TABLE `view_data_penduduk` (
`alamat` text
,`jenis_kelamin` enum('Laki-laki','Perempuan')
,`nama` varchar(100)
,`nama_agama` varchar(50)
,`nama_kepala_keluarga` varchar(100)
,`nama_pekerjaan` varchar(100)
,`nik` char(16)
,`no_kk` char(16)
,`status_perkawinan` enum('Belum Kawin','Kawin','Cerai')
,`tanggal_lahir` date
,`tempat_lahir` varchar(50)
);

-- --------------------------------------------------------

--
-- Stand-in structure for view `view_data_surat`
-- (See below for the actual view)
--
CREATE TABLE `view_data_surat` (
`id_surat` int
,`jenis_surat` varchar(100)
,`nama` varchar(100)
,`nik` char(16)
,`status` enum('Diproses','Selesai','Ditolak')
,`tanggal_pengajuan` date
);

-- --------------------------------------------------------

--
-- Stand-in structure for view `view_penduduk`
-- (See below for the actual view)
--
CREATE TABLE `view_penduduk` (
`id_agama` int
,`id_pekerjaan` int
,`jenis_kelamin` enum('Laki-laki','Perempuan')
,`nama` varchar(100)
,`nama_agama` varchar(50)
,`nama_kepala_keluarga` varchar(100)
,`nama_pekerjaan` varchar(100)
,`nik` char(16)
,`no_kk` char(16)
,`status_perkawinan` enum('Belum Kawin','Kawin','Cerai')
,`tanggal_lahir` date
,`tempat_lahir` varchar(50)
);

-- --------------------------------------------------------

--
-- Stand-in structure for view `view_statistik_penduduk`
-- (See below for the actual view)
--
CREATE TABLE `view_statistik_penduduk` (
`jenis_kelamin` enum('Laki-laki','Perempuan')
,`jumlah` bigint
,`status_perkawinan` enum('Belum Kawin','Kawin','Cerai')
);

-- --------------------------------------------------------

--
-- Structure for view `view_data_keluarga`
--
DROP TABLE IF EXISTS `view_data_keluarga`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `view_data_keluarga`  AS SELECT `k`.`no_kk` AS `no_kk`, `k`.`nama_kepala_keluarga` AS `nama_kepala_keluarga`, `k`.`alamat` AS `alamat`, count(`p`.`nik`) AS `jumlah_anggota` FROM (`tb_keluarga` `k` left join `tb_penduduk` `p` on((`k`.`no_kk` = `p`.`no_kk`))) GROUP BY `k`.`no_kk`, `k`.`nama_kepala_keluarga`, `k`.`alamat``alamat`  ;

-- --------------------------------------------------------

--
-- Structure for view `view_data_mutasi`
--
DROP TABLE IF EXISTS `view_data_mutasi`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `view_data_mutasi`  AS SELECT `m`.`id_mutasi` AS `id_mutasi`, `p`.`nik` AS `nik`, `p`.`nama` AS `nama`, `m`.`jenis_mutasi` AS `jenis_mutasi`, `m`.`tanggal_mutasi` AS `tanggal_mutasi`, `m`.`keterangan` AS `keterangan` FROM (`tb_mutasi` `m` join `tb_penduduk` `p` on((`m`.`nik` = `p`.`nik`)))  ;

-- --------------------------------------------------------

--
-- Structure for view `view_data_penduduk`
--
DROP TABLE IF EXISTS `view_data_penduduk`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `view_data_penduduk`  AS SELECT `p`.`nik` AS `nik`, `p`.`nama` AS `nama`, `p`.`tempat_lahir` AS `tempat_lahir`, `p`.`tanggal_lahir` AS `tanggal_lahir`, `p`.`jenis_kelamin` AS `jenis_kelamin`, `p`.`status_perkawinan` AS `status_perkawinan`, `a`.`nama_agama` AS `nama_agama`, `pek`.`nama_pekerjaan` AS `nama_pekerjaan`, `k`.`no_kk` AS `no_kk`, `k`.`nama_kepala_keluarga` AS `nama_kepala_keluarga`, `k`.`alamat` AS `alamat` FROM (((`tb_penduduk` `p` join `tb_agama` `a` on((`p`.`id_agama` = `a`.`id_agama`))) join `tb_pekerjaan` `pek` on((`p`.`id_pekerjaan` = `pek`.`id_pekerjaan`))) join `tb_keluarga` `k` on((`p`.`no_kk` = `k`.`no_kk`)))  ;

-- --------------------------------------------------------

--
-- Structure for view `view_data_surat`
--
DROP TABLE IF EXISTS `view_data_surat`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `view_data_surat`  AS SELECT `s`.`id_surat` AS `id_surat`, `p`.`nik` AS `nik`, `p`.`nama` AS `nama`, `s`.`jenis_surat` AS `jenis_surat`, `s`.`tanggal_pengajuan` AS `tanggal_pengajuan`, `s`.`status` AS `status` FROM (`tb_surat` `s` join `tb_penduduk` `p` on((`s`.`nik` = `p`.`nik`)))  ;

-- --------------------------------------------------------

--
-- Structure for view `view_penduduk`
--
DROP TABLE IF EXISTS `view_penduduk`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `view_penduduk`  AS SELECT `p`.`nik` AS `nik`, `p`.`nama` AS `nama`, `p`.`tempat_lahir` AS `tempat_lahir`, `p`.`tanggal_lahir` AS `tanggal_lahir`, `p`.`jenis_kelamin` AS `jenis_kelamin`, `p`.`status_perkawinan` AS `status_perkawinan`, `p`.`id_agama` AS `id_agama`, `a`.`nama_agama` AS `nama_agama`, `p`.`id_pekerjaan` AS `id_pekerjaan`, `pk`.`nama_pekerjaan` AS `nama_pekerjaan`, `p`.`no_kk` AS `no_kk`, `k`.`nama_kepala_keluarga` AS `nama_kepala_keluarga` FROM (((`tb_penduduk` `p` join `tb_agama` `a` on((`p`.`id_agama` = `a`.`id_agama`))) join `tb_pekerjaan` `pk` on((`p`.`id_pekerjaan` = `pk`.`id_pekerjaan`))) join `tb_keluarga` `k` on((`p`.`no_kk` = `k`.`no_kk`)))  ;

-- --------------------------------------------------------

--
-- Structure for view `view_statistik_penduduk`
--
DROP TABLE IF EXISTS `view_statistik_penduduk`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `view_statistik_penduduk`  AS SELECT `tb_penduduk`.`jenis_kelamin` AS `jenis_kelamin`, `tb_penduduk`.`status_perkawinan` AS `status_perkawinan`, count(0) AS `jumlah` FROM `tb_penduduk` GROUP BY `tb_penduduk`.`jenis_kelamin`, `tb_penduduk`.`status_perkawinan``status_perkawinan`  ;

--
-- Indexes for dumped tables
--

--
-- Indexes for table `tb_agama`
--
ALTER TABLE `tb_agama`
  ADD PRIMARY KEY (`id_agama`);

--
-- Indexes for table `tb_desa`
--
ALTER TABLE `tb_desa`
  ADD PRIMARY KEY (`id_desa`);

--
-- Indexes for table `tb_keluarga`
--
ALTER TABLE `tb_keluarga`
  ADD PRIMARY KEY (`no_kk`);

--
-- Indexes for table `tb_log_aktivitas`
--
ALTER TABLE `tb_log_aktivitas`
  ADD PRIMARY KEY (`id_log`);

--
-- Indexes for table `tb_mutasi`
--
ALTER TABLE `tb_mutasi`
  ADD PRIMARY KEY (`id_mutasi`),
  ADD KEY `tb_mutasi_ibfk_1` (`nik`);

--
-- Indexes for table `tb_pekerjaan`
--
ALTER TABLE `tb_pekerjaan`
  ADD PRIMARY KEY (`id_pekerjaan`);

--
-- Indexes for table `tb_penduduk`
--
ALTER TABLE `tb_penduduk`
  ADD PRIMARY KEY (`nik`),
  ADD KEY `id_agama` (`id_agama`),
  ADD KEY `id_pekerjaan` (`id_pekerjaan`),
  ADD KEY `no_kk` (`no_kk`);

--
-- Indexes for table `tb_surat`
--
ALTER TABLE `tb_surat`
  ADD PRIMARY KEY (`id_surat`),
  ADD KEY `tb_surat_ibfk_1` (`nik`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `tb_agama`
--
ALTER TABLE `tb_agama`
  MODIFY `id_agama` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=7;

--
-- AUTO_INCREMENT for table `tb_desa`
--
ALTER TABLE `tb_desa`
  MODIFY `id_desa` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT for table `tb_log_aktivitas`
--
ALTER TABLE `tb_log_aktivitas`
  MODIFY `id_log` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=29;

--
-- AUTO_INCREMENT for table `tb_mutasi`
--
ALTER TABLE `tb_mutasi`
  MODIFY `id_mutasi` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=10;

--
-- AUTO_INCREMENT for table `tb_pekerjaan`
--
ALTER TABLE `tb_pekerjaan`
  MODIFY `id_pekerjaan` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=9;

--
-- AUTO_INCREMENT for table `tb_surat`
--
ALTER TABLE `tb_surat`
  MODIFY `id_surat` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

--
-- Constraints for dumped tables
--

--
-- Constraints for table `tb_mutasi`
--
ALTER TABLE `tb_mutasi`
  ADD CONSTRAINT `tb_mutasi_ibfk_1` FOREIGN KEY (`nik`) REFERENCES `tb_penduduk` (`nik`) ON DELETE CASCADE;

--
-- Constraints for table `tb_penduduk`
--
ALTER TABLE `tb_penduduk`
  ADD CONSTRAINT `tb_penduduk_ibfk_1` FOREIGN KEY (`id_agama`) REFERENCES `tb_agama` (`id_agama`),
  ADD CONSTRAINT `tb_penduduk_ibfk_2` FOREIGN KEY (`id_pekerjaan`) REFERENCES `tb_pekerjaan` (`id_pekerjaan`),
  ADD CONSTRAINT `tb_penduduk_ibfk_3` FOREIGN KEY (`no_kk`) REFERENCES `tb_keluarga` (`no_kk`);

--
-- Constraints for table `tb_surat`
--
ALTER TABLE `tb_surat`
  ADD CONSTRAINT `tb_surat_ibfk_1` FOREIGN KEY (`nik`) REFERENCES `tb_penduduk` (`nik`) ON DELETE CASCADE;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
