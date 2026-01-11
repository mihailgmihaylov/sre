#!/usr/bin/env bash
set -euo pipefail

apt-get update -y
apt-get install -y nginx

cat >/var/www/html/index.html <<HTML
<!doctype html>
<html>
<head>
  <meta charset="utf-8">
  <title>SRE Sample App</title>
  <style>
    body { font-family: Arial, sans-serif; text-align: center; margin-top: 4rem; }
  </style>
</head>
<body>
  <h1>Google Cloud Terraform Stack</h1>
  <p>This page is served from a Managed Instance Group behind a global HTTP load balancer.</p>
  <p>Instance: $(hostname)</p>
</body>
</html>
HTML

systemctl enable nginx
systemctl restart nginx
