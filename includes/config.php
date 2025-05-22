<?php
$host = 'localhost';
$user = 'root';
$pass = '';
$db   = 'db_sidesa1';

$conn = new mysqli($host, $user, $pass, $db);

if ($conn->connect_error) {
    die("Koneksi gagal: " . $conn->connect_error);
}

define('BASE_URL', '/sidesa_project'); 
?>
