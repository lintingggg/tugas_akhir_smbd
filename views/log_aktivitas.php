<?php include '../includes/header.php'; ?>

<div class="container mt-4">
  <h4>Log Aktivitas</h4>

  <div class="table-responsive mt-3">
    <table class="table table-bordered table-striped">
      <thead class="table-dark">
        <tr>
          <th>No</th>
          <th>Waktu</th>
          <th>Tabel</th>
          <th>Aksi</th>
          <th>NIK</th>
          <th>Keterangan</th>
        </tr>
      </thead>
      <tbody>
        <?php
        $no = 1;
        $query = $conn->query("SELECT * FROM tb_log_aktivitas ORDER BY waktu DESC");
        while ($row = $query->fetch_assoc()):
        ?>
        <tr>
          <td><?= $no++ ?></td>
          <td><?= $row['waktu'] ?></td>
          <td><?= $row['tabel'] ?></td>
          <td><span class="badge bg-primary"><?= $row['aksi'] ?></span></td>
          <td><?= $row['nik'] ?? '-' ?></td>
          <td><?= $row['keterangan'] ?></td>
        </tr>
        <?php endwhile; ?>
      </tbody>
    </table>
  </div>
</div>

<?php include '../includes/footer.php'; ?>
