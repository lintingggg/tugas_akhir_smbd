<?php include 'config.php'; ?>
<!DOCTYPE html>
<html lang="id">
<head>
    <meta charset="UTF-8">
    <title>SI Desa</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
    <link href="/assets/css/style.css" rel="stylesheet">
    <style>
        html, body {
            height: 100%;
            margin: 0;
        }

        .wrapper {
            display: flex;
            min-height: 100vh;
        }

        .sidebar {
            width: 250px;
            background-color: #0d6efd;
            color: white;
            padding-top: 20px;
        }

        .sidebar a {
            color: white;
            text-decoration: none;
            display: block;
            padding: 10px 20px;
        }

        .sidebar a:hover {
            background-color: #084298;
        }

        .content {
            padding: 20px;
            flex-grow: 1;
        }

        footer {
            background: #f8f9fa;
            text-align: center;
            padding: 15px;
        }
    </style>
</head>
<body>
    <div class="wrapper">
        <div class="sidebar">
            <h4 class="text-center">SI Desa</h4>
            <a href="<?= BASE_URL ?>/index.php">📊 Dashboard</a>
            <a href="<?= BASE_URL ?>/views/penduduk.php">👥 Data Penduduk</a>
            <a href="<?= BASE_URL ?>/views/keluarga.php">👨‍👩‍👧‍👦 Data Keluarga</a>
            <a href="<?= BASE_URL ?>/views/surat.php">Data Surat</a>
            <a href="<?= BASE_URL ?>/views/mutasi.php">Data Mutasi</a>
            <a href="<?= BASE_URL ?>/views/laporan.php">Data laporan</a>
            <a href="<?= BASE_URL ?>/views/log_aktivitas.php">🔄 Log Aktivitas</a>
        </div>
        <div class="content">
