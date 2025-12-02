#!/bin/bash
dnf update -y
dnf install -y httpd php php-mysqli php-json php-dom php-gd php-intl php-mbstring php-xml php-zip wget unzip -y

systemctl enable httpd
systemctl start httpd

#############################################
# Install WordPress
#############################################

cd /var/www/html
rm -rf *

wget https://wordpress.org/latest.tar.gz
tar -xzf latest.tar.gz
mv wordpress/* .
rm -rf wordpress latest.tar.gz

#############################################
# Create FULL portfolio.php page
#############################################

cat << 'EOF' > /var/www/html/portfolio.php
<?php
// Database connection variables (edit DB_HOST after Terraform apply)
$servername = "REPLACE_RDS_ENDPOINT_HERE";
$username = "admin";
$password = "DemoPassword123!";
$dbname = "wordpressdb";

// Create connection
$conn = new mysqli($servername, $username, $password, $dbname);

// Check connection
if ($conn->connect_error) {
  die("Connection failed: " . $conn->connect_error);
}

// If form is submitted, insert into DB
if ($_SERVER["REQUEST_METHOD"] == "POST") {
  $name = $_POST["name"];
  $email = $_POST["email"];
  $message = $_POST["message"];
  
  $stmt = $conn->prepare("INSERT INTO contacts (name, email, message) VALUES (?, ?, ?)");
  $stmt->bind_param("sss", $name, $email, $message);
  $stmt->execute();
  $stmt->close();

  echo "<script>alert('Thank you for contacting me!');</script>";
}
?>
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Emma’s Portfolio</title>
  <style>
    body {
      font-family: 'Segoe UI', Tahoma, sans-serif;
      background: #f7f9fc;
      margin: 0;
      padding: 0;
      color: #333;
    }
    header {
      background-color: #004aad;
      color: white;
      text-align: center;
      padding: 40px 20px;
    }
    section {
      width: 90%;
      max-width: 800px;
      margin: 40px auto;
      background: white;
      padding: 30px;
      border-radius: 10px;
      box-shadow: 0 2px 10px rgba(0,0,0,0.1);
    }
    h2 {
      color: #004aad;
    }
    input, textarea {
      width: 100%;
      padding: 10px;
      margin-top: 10px;
      border: 1px solid #ccc;
      border-radius: 6px;
    }
    button {
      background: #004aad;
      color: white;
      padding: 10px 15px;
      border: none;
      margin-top: 10px;
      border-radius: 6px;
      cursor: pointer;
    }
    button:hover {
      background: #00337f;
    }
  </style>
</head>
<body>
  <header>
    <h1>Welcome to Emma’s Portfolio</h1>
    <p>Cloud Practitioner | Backend Developer | AWS Enthusiast</p>
  </header>

  <section>
    <h2>About Me</h2>
    <p>Hello! I’m Emma, an AWS Cloud Practitioner passionate about cloud solutions, web apps, and backend development. 
    This portfolio is hosted on AWS using a two-tier architecture (EC2 + RDS) to showcase real-world cloud deployment.</p>
  </section>

  <section>
    <h2>Contact Me</h2>
    <form method="POST" action="">
      <label>Name</label>
      <input type="text" name="name" required>
      <label>Email</label>
      <input type="email" name="email" required>
      <label>Message</label>
      <textarea name="message" rows="4" required></textarea>
      <button type="submit">Send Message</button>
    </form>
  </section>
</body>
</html>
<?php
$conn->close();
?>
EOF

#############################################
# Permissions
#############################################
chown -R apache:apache /var/www/html
chmod -R 755 /var/www/html
