<?php include '../includes/header.php'; 


?>

<h2>Data Penduduk</h2>
<form method="POST" class="mb-3 d-flex" style="max-width: 400px;">
    <input type="text" name="keyword" class="form-control me-2" placeholder="Cari NIK / Nama" required>
    <button type="submit" name="cari" class="btn btn-primary">Cari</button>
</form>

<a href="#" class="btn btn-primary mb-3" data-bs-toggle="modal" data-bs-target="#modalTambahPenduduk">+ Tambah Penduduk</a>
<table class="table table-bordered table-striped">
    <thead class="table-primary">
        <tr>
            <th>NIK</th>
            <th>Nama</th>
            <th>Tempat, Tanggal Lahir</th>
            <th>Jenis Kelamin</th>
            <th>Status Perkawinan</th>
            <th>Agama</th>
            <th>Pekerjaan</th>
            <th>Kepala Keluarga</th>
            <th>Aksi</th>
        </tr>
    </thead>
    <tbody>
        <?php
        if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_POST['cari'])) {
            $keyword = $_POST['keyword'];
            $stmt = $conn->prepare("CALL sp_cari_penduduk(?)");
            $stmt->bind_param("s", $keyword);
            $stmt->execute();
            $result = $stmt->get_result();
            $conn->next_result(); // Tambahkan ini untuk hindari error di query berikutnya
        } else {
            $result = $conn->query("SELECT * FROM view_penduduk ORDER BY nama ASC");
        }
        
        // Ambil data referensi 1x di luar loop
        $data_agama = $conn->query("SELECT * FROM tb_agama");
        $agama_list = [];
        while ($a = $data_agama->fetch_assoc()) $agama_list[] = $a;

        $data_pekerjaan = $conn->query("SELECT * FROM tb_pekerjaan");
        $pekerjaan_list = [];
        while ($p = $data_pekerjaan->fetch_assoc()) $pekerjaan_list[] = $p;

        $data_keluarga = $conn->query("SELECT * FROM tb_keluarga");
        $keluarga_list = [];
        while ($k = $data_keluarga->fetch_assoc()) $keluarga_list[] = $k;


        if ($result->num_rows > 0) {
            
            while ($row = $result->fetch_assoc()) {
                echo "<tr>
                    <td>{$row['nik']}</td>
                    <td>{$row['nama']}</td>
                    <td>{$row['tempat_lahir']}, " . date('d-m-Y', strtotime($row['tanggal_lahir'])) . "</td>
                    <td>{$row['jenis_kelamin']}</td>
                    <td>{$row['status_perkawinan']}</td>
                    <td>{$row['nama_agama']}</td>
                    <td>{$row['nama_pekerjaan']}</td>
                    <td>{$row['nama_kepala_keluarga']}</td>
                    <td>
                        <button type='button' class='btn btn-sm btn-warning' data-bs-toggle='modal' data-bs-target='#modalEdit{$row['nik']}'>Edit</button>
                        <form method='POST' class='d-inline'>
                            <input type='hidden' name='hapus_nik' value='{$row['nik']}'>
                            <button type='submit' class='btn btn-sm btn-danger' onclick=\"return confirm('Yakin ingin menghapus data ini?')\">Hapus</button>
                    </td>
                </tr>";
                
                // Modal Edit for each row
                echo "<div class='modal fade' id='modalEdit{$row['nik']}' tabindex='-1'>
                <div class='modal-dialog'>
                    <form method='POST'>
                        <div class='modal-content'>
                            <div class='modal-header'>
                                <h5 class='modal-title'>Edit Penduduk</h5>
                                <button type='button' class='btn-close' data-bs-dismiss='modal'></button>
                            </div>
                            <div class='modal-body'>
                                <input type='hidden' name='edit_nik' value='{$row['nik']}'>
                                
                                <div class='mb-2'>
                                    <label>Nama</label>
                                    <input type='text' name='edit_nama' class='form-control' value='{$row['nama']}' required>
                                </div>

                                <div class='mb-2'>
                                    <label>Tempat Lahir</label>
                                    <input type='text' name='edit_tempat' class='form-control' value='{$row['tempat_lahir']}' required>
                                </div>

                                <div class='mb-2'>
                                    <label>Tanggal Lahir</label>
                                    <input type='date' name='edit_tgl' class='form-control' value='{$row['tanggal_lahir']}' required>
                                </div>

                                <div class='mb-2'>
                                    <label>Jenis Kelamin</label>
                                    <select name='edit_jk' class='form-control' required>
                                        <option ".($row['jenis_kelamin'] == 'Laki-laki' ? 'selected' : '').">Laki-laki</option>
                                        <option ".($row['jenis_kelamin'] == 'Perempuan' ? 'selected' : '').">Perempuan</option>
                                    </select>
                                </div>

                                <div class='mb-2'>
                                    <label>Status Perkawinan</label>
                                    <select name='edit_status' class='form-control' required>
                                        <option ".($row['status_perkawinan'] == 'Belum Kawin' ? 'selected' : '').">Belum Kawin</option>
                                        <option ".($row['status_perkawinan'] == 'Kawin' ? 'selected' : '').">Kawin</option>
                                        <option ".($row['status_perkawinan'] == 'Cerai' ? 'selected' : '').">Cerai</option>
                                    </select>
                                </div>";

                                // Dropdown Agama
                                echo "<div class='mb-2'>
                                        <label>Agama</label>
                                        <select name='edit_agama' class='form-control' required>
                                            <option value=''>-- Pilih --</option>";
                                foreach ($agama_list as $a) {
                                    $selected = ($a['id_agama'] == $row['id_agama']) ? 'selected' : '';
                                    echo "<option value='{$a['id_agama']}' $selected>{$a['nama_agama']}</option>";
                                }
                                echo "</select>
                                    </div>";

                                // Dropdown Pekerjaan
                                echo "<div class='mb-2'>
                                        <label>Pekerjaan</label>
                                        <select name='edit_pekerjaan' class='form-control' required>
                                            <option value=''>-- Pilih --</option>";
                                foreach ($pekerjaan_list as $p) {
                                    $selected = ($p['id_pekerjaan'] == $row['id_pekerjaan']) ? 'selected' : '';
                                    echo "<option value='{$p['id_pekerjaan']}' $selected>{$p['nama_pekerjaan']}</option>";
                                }
                                echo "</select>
                                    </div>";

                                // Dropdown No KK
                                echo "<div class='mb-2'>
                                        <label>No KK</label>
                                        <select name='edit_kk' class='form-control' required>
                                            <option value=''>-- Pilih --</option>";
                                foreach ($keluarga_list as $k) {
                                    $selected = ($k['no_kk'] == $row['no_kk']) ? 'selected' : '';
                                    echo "<option value='{$k['no_kk']}' $selected>{$k['no_kk']} - {$k['nama_kepala_keluarga']}</option>";
                                }
                                echo "</select>
                                    </div>";

            echo        "</div>
                            <div class='modal-footer'>
                                <button type='submit' name='simpan_edit' class='btn btn-success'>Simpan</button>
                                <button type='button' class='btn btn-secondary' data-bs-dismiss='modal'>Batal</button>
                            </div>
                        </div>
                    </form>
                </div>
            </div>";

            }
        } else {
            echo "<tr><td colspan='9' class='text-center'>Tidak ada data</td></tr>";
        }
        ?>
    </tbody>
</table>

<!-- Modal Tambah Penduduk -->
<div class="modal fade" id="modalTambahPenduduk" tabindex="-1" aria-labelledby="modalLabel" aria-hidden="true">
  <div class="modal-dialog modal-lg">
    <div class="modal-content">
      <form action="" method="POST">
        <div class="modal-header">
          <h5 class="modal-title" id="modalLabel">Tambah Penduduk</h5>
          <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
        </div>
        <div class="modal-body">
          <?php
          $agama = $conn->query("SELECT * FROM tb_agama");
          $pekerjaan = $conn->query("SELECT * FROM tb_pekerjaan");
          $keluarga = $conn->query("SELECT * FROM tb_keluarga");
          ?>
          <div class="row">
            <div class="col-md-6">
              <label>NIK</label>
              <input type="text" name="nik" class="form-control" required maxlength="16">
            </div>
            <div class="col-md-6">
              <label>Nama</label>
              <input type="text" name="nama" class="form-control" required>
            </div>
            <div class="col-md-6 mt-2">
              <label>Tempat Lahir</label>
              <input type="text" name="tempat_lahir" class="form-control" required>
            </div>
            <div class="col-md-6 mt-2">
              <label>Tanggal Lahir</label>
              <input type="date" name="tanggal_lahir" class="form-control" required>
            </div>
            <div class="col-md-6 mt-2">
              <label>Jenis Kelamin</label>
              <select name="jenis_kelamin" class="form-control" required>
                <option value="">-- Pilih --</option>
                <option value="Laki-laki">Laki-laki</option>
                <option value="Perempuan">Perempuan</option>
              </select>
            </div>
            <div class="col-md-6 mt-2">
              <label>Status Perkawinan</label>
              <select name="status_perkawinan" class="form-control" required>
                <option value="">-- Pilih --</option>
                <option value="Belum Kawin">Belum Kawin</option>
                <option value="Kawin">Kawin</option>
                <option value="Cerai">Cerai</option>
              </select>
            </div>
            <div class="col-md-4 mt-2">
              <label>Agama</label>
              <select name="id_agama" class="form-control" required>
                <option value="">-- Pilih --</option>
                <?php while ($a = $agama->fetch_assoc()): ?>
                  <option value="<?= $a['id_agama'] ?>"><?= $a['nama_agama'] ?></option>
                <?php endwhile; ?>
              </select>
            </div>
            <div class="col-md-4 mt-2">
              <label>Pekerjaan</label>
              <select name="id_pekerjaan" class="form-control" required>
                <option value="">-- Pilih --</option>
                <?php while ($p = $pekerjaan->fetch_assoc()): ?>
                  <option value="<?= $p['id_pekerjaan'] ?>"><?= $p['nama_pekerjaan'] ?></option>
                <?php endwhile; ?>
              </select>
            </div>
            <div class="col-md-4 mt-2">
              <label>No KK</label>
              <select name="no_kk" class="form-control" required>
                <option value="">-- Pilih --</option>
                <?php while ($k = $keluarga->fetch_assoc()): ?>
                  <option value="<?= $k['no_kk'] ?>"><?= $k['no_kk'] ?> - <?= $k['nama_kepala_keluarga'] ?></option>
                <?php endwhile; ?>
              </select>
            </div>
          </div>
        </div>
        <div class="modal-footer">
          <button type="submit" name="simpan" class="btn btn-success">Simpan</button>
          <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Batal</button>
        </div>
      </form>
    </div>
  </div>
</div>

<?php
// Handle form submissions
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    try {
        // Tambah Penduduk
        if (isset($_POST['simpan'])) {
            $sql = "CALL sp_tambah_penduduk(
                '".$conn->real_escape_string($_POST['nik'])."',
                '".$conn->real_escape_string($_POST['nama'])."',
                '".$conn->real_escape_string($_POST['tempat_lahir'])."',
                '".$conn->real_escape_string($_POST['tanggal_lahir'])."',
                '".$conn->real_escape_string($_POST['jenis_kelamin'])."',
                '".$conn->real_escape_string($_POST['status_perkawinan'])."',
                ".(int)$_POST['id_agama'].",
                ".(int)$_POST['id_pekerjaan'].",
                '".$conn->real_escape_string($_POST['no_kk'])."'
            )";
            
            if ($conn->query($sql)) {
                $_SESSION['success'] = "Data penduduk berhasil ditambahkan";
                echo "<script>location.href='penduduk.php';</script>";
                exit();
            } else {
                throw new Exception("Gagal menambahkan data: " . $conn->error);
            }
        }

        // Edit Penduduk
        if (isset($_POST['simpan_edit'])) {
            $sql = "CALL sp_update_penduduk(
                '".$conn->real_escape_string($_POST['edit_nik'])."',
                '".$conn->real_escape_string($_POST['edit_nama'])."',
                '".$conn->real_escape_string($_POST['edit_tempat'])."',
                '".$conn->real_escape_string($_POST['edit_tgl'])."',
                '".$conn->real_escape_string($_POST['edit_jk'])."',
                '".$conn->real_escape_string($_POST['edit_status'])."',
                ".(int)$_POST['edit_agama'].",
                ".(int)$_POST['edit_pekerjaan'].",
                '".$conn->real_escape_string($_POST['edit_kk'])."'
            )";
            
            if ($conn->query($sql)) {
                $_SESSION['success'] = "Data penduduk berhasil diupdate";
                echo "<script>location.href='penduduk.php';</script>";
                exit();
            } else {
                throw new Exception("Gagal mengupdate data: " . $conn->error);
            }
        }

        // Hapus Penduduk
        if (isset($_POST['hapus'])) {
            $sql = "CALL sp_hapus_penduduk(".$_POST['hapus'].")";
            
            if ($conn->query($sql)) {
                $_SESSION['success'] = "Data penduduk berhasil dihapus";
                echo "<script>location.href='penduduk.php';</script>";
                exit();
            } else {
                throw new Exception("Gagal menghapus data: " . $conn->error);
            }
        }


    } catch (Exception $e) {
        $_SESSION['error'] = $e->getMessage();
        echo "<script>location.href='penduduk.php';</script>";
        exit();
    }
}
?>

<?php include '../includes/footer.php'; ?>