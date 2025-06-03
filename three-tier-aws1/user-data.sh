#!/bin/bash
yum update -y
yum install -y httpd php php-mysqlnd
systemctl start httpd
systemctl enable httpd
echo "<?php
\$db = new mysqli('$(terraform output -raw rds_endpoint)', 'admin', 'your_secure_password', 'mydb');
if (\$db->connect_error) {
    die('Connection failed: ' . \$db->connect_error);
}
echo 'Connected successfully!';
\$db->close();
?>" > /var/www/html/index.php