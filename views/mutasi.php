<?php include '../includes/header.php'; ?>

<div class="container mt-4">
  <h4>Data Mutasi Penduduk</h4>
  <table class="table table-bordered table-striped mt-3">
    <thead class="table-dark">
      <tr>
        <th>No</th>
        <th>NIK</th>
        <th>Nama</th>
        <th>Jenis Mutasi</th>
        <th>Tanggal Mutasi</th>
        <th>Keterangan</th>
      </tr>
    </thead>
    <tbody>
      <?php
      $no = 1;
      $query = $conn->query("SELECT * FROM view_data_mutasi");
      while ($row = $query->fetch_assoc()):
      ?>
      <tr>
        <td><?= $no++ ?></td>
        <td><?= $row['nik'] ?></td>
        <td><?= $row['nama'] ?></td>
        <td><?= $row['jenis_mutasi'] ?></td>
        <td><?= $row['tanggal_mutasi'] ?></td>
        <td><?= $row['keterangan'] ?></td>
      </tr>
      <?php endwhile; ?>
    </tbody>
  </table>
</div>

<?php include '../includes/footer.php'; ?>
