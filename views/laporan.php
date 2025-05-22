<?php include '../includes/header.php'; ?>

<div class="container mt-4">
  <h4>Laporan Jumlah Penduduk per Desa</h4>

  <table class="table table-bordered table-striped mt-3">
    <thead class="table-dark">
      <tr>
        <th>No</th>
        <th>Nama Desa</th>
        <th>Total Penduduk</th>
      </tr>
    </thead>
    <tbody>
      <?php
      $no = 1;

      // Panggil stored procedure
      $result = $conn->query("CALL sp_laporan_penduduk_per_desa()");
      if ($result) {
        while ($row = $result->fetch_assoc()) {
      ?>
      <tr>
        <td><?= $no++ ?></td>
        <td><?= htmlspecialchars($row['desa']) ?></td>
        <td><?= htmlspecialchars($row['total_penduduk']) ?></td>
      </tr>
      <?php
        }
        // Selesaikan result set dan reset connection
        $result->free();
        $conn->next_result();
      } else {
        echo "<tr><td colspan='3'>Gagal memuat data laporan.</td></tr>";
      }
      ?>
    </tbody>
  </table>
</div>

<?php include '../includes/footer.php'; ?>
