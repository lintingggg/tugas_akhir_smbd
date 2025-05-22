<?php include '../includes/header.php'; ?>

<div class="container mt-4">
  <h4>Data Keluarga</h4>
  <table class="table table-bordered table-striped mt-3">
    <thead class="table-dark">
      <tr>
        <th>No</th>
        <th>No KK</th>
        <th>Nama Kepala Keluarga</th>
        <th>Alamat</th>
        <th>Jumlah Anggota</th>
      </tr>
    </thead>
    <tbody>
      <?php
      $no = 1;
      $query = $conn->query("SELECT * FROM view_data_keluarga");
      while ($row = $query->fetch_assoc()):
      ?>
      <tr>
        <td><?= $no++ ?></td>
        <td><?= $row['no_kk'] ?></td>
        <td><?= $row['nama_kepala_keluarga'] ?></td>
        <td><?= $row['alamat'] ?></td>
        <td><?= $row['jumlah_anggota'] ?></td>
      </tr>
      <?php endwhile; ?>
    </tbody>
  </table>
</div>

<?php include '../includes/footer.php'; ?>
