#!/usr/bin/env bash
set -euo pipefail

# ===== 自動 sudo =====
if [[ "$EUID" -ne 0 ]]; then
  exec sudo "$0" "$@"
fi

# ===== Config =====
DB_NAME="demo"
DB_USER="demo"
DB_PASS=""
ALLOW_REMOTE="true"

echo "[1/6] Install MySQL"
apt update -y
apt install -y mysql-server

echo "[2/6] Enable MySQL"
systemctl enable --now mysql

echo "[3/6] Configure bind-address"
CONF="/etc/mysql/mysql.conf.d/mysqld.cnf"
if [[ "$ALLOW_REMOTE" == "true" ]]; then
  sed -i 's/^bind-address.*/bind-address = 0.0.0.0/' "$CONF"
fi

echo "[4/6] Restart MySQL"
systemctl restart mysql

echo "[5/6] Create DB & User"
mysql <<EOF
CREATE DATABASE IF NOT EXISTS ${DB_NAME};
CREATE USER IF NOT EXISTS '${DB_USER}'@'%' IDENTIFIED BY '${DB_PASS}';
GRANT ALL PRIVILEGES ON ${DB_NAME}.* TO '${DB_USER}'@'%';
FLUSH PRIVILEGES;
EOF

echo "[6/6] Insert test data"
mysql ${DB_NAME} <<EOF
CREATE TABLE IF NOT EXISTS test (
  id INT AUTO_INCREMENT PRIMARY KEY,
  msg VARCHAR(64)
);
INSERT INTO test (msg) VALUES ('hello-from-mysql-vm');
EOF

echo "MySQL deploy done"
