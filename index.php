<?php include 'includes/header.php'; ?>

<div class="container mt-4">
  <h4>Statistik Penduduk</h4>

  <!-- Chart Canvas -->
  <canvas id="statistikChart" height="100"></canvas>

  <hr class="my-4">

  <!-- Tabel Data -->
  <table class="table table-bordered table-striped mt-3">
    <thead class="table-dark">
      <tr>
        <th>No</th>
        <th>Jenis Kelamin</th>
        <th>Status Perkawinan</th>
        <th>Jumlah</th>
      </tr>
    </thead>
    <tbody>
      <?php
      $no = 1;
      $labels = [];
      $data = [];

      $query = $conn->query("SELECT * FROM view_statistik_penduduk");
      while ($row = $query->fetch_assoc()):
        $label = $row['jenis_kelamin'] . ' - ' . $row['status_perkawinan'];
        $labels[] = $label;
        $data[] = $row['jumlah'];
      ?>
      <tr>
        <td><?= $no++ ?></td>
        <td><?= $row['jenis_kelamin'] ?></td>
        <td><?= $row['status_perkawinan'] ?></td>
        <td><?= $row['jumlah'] ?></td>
      </tr>
      <?php endwhile; ?>
    </tbody>
  </table>
</div>

<!-- Chart.js CDN -->
<script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
<script>
  const ctx = document.getElementById('statistikChart').getContext('2d');

  const statistikChart = new Chart(ctx, {
    type: 'bar',
    data: {
      labels: <?= json_encode($labels) ?>,
      datasets: [{
        label: 'Jumlah Penduduk',
        data: <?= json_encode($data) ?>,
        backgroundColor: 'rgba(54, 162, 235, 0.6)',
        borderColor: 'rgba(54, 162, 235, 1)',
        borderWidth: 1
      }]
    },
    options: {
      responsive: true,
      scales: {
        y: {
          beginAtZero: true,
          title: { display: true, text: 'Jumlah' }
        },
        x: {
          title: { display: true, text: 'Kelamin - Status Perkawinan' }
        }
      }
    }
  });
</script>

<?php include 'includes/footer.php'; ?>
