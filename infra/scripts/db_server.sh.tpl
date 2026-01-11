#!/usr/bin/env bash
set -euo pipefail

export DEBIAN_FRONTEND=noninteractive

apt-get update -y
apt-get install -y mariadb-server

systemctl enable mariadb
systemctl restart mariadb

mysql <<SQL
ALTER USER 'root'@'localhost' IDENTIFIED BY '${root_pass}';
FLUSH PRIVILEGES;
CREATE DATABASE IF NOT EXISTS \`${db_name}\`;
CREATE USER IF NOT EXISTS '${db_user}'@'%' IDENTIFIED BY '${db_password}';
GRANT ALL PRIVILEGES ON \`${db_name}\`.* TO '${db_user}'@'%';
FLUSH PRIVILEGES;
SQL

cat >/etc/mysql/mariadb.conf.d/60-bind.cnf <<'CFG'
[mysqld]
bind-address = 0.0.0.0
CFG

systemctl restart mariadb
