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
DB_USER_HOST="x.x.145.%"
ALLOW_REMOTE="true"

echo "[1/7] Install MySQL (if needed)"
apt update -y
apt install -y mysql-server

echo "[2/7] Enable MySQL"
systemctl enable --now mysql

echo "[3/7] Configure bind-address (public)"
CONF="/etc/mysql/mysql.conf.d/mysqld.cnf"
if [[ "$ALLOW_REMOTE" == "true" ]]; then
  if grep -q '^bind-address' "$CONF"; then
    sed -i 's/^bind-address.*/bind-address = 0.0.0.0/' "$CONF"
  else
    echo "bind-address = 0.0.0.0" >>"$CONF"
  fi
fi

echo "[4/7] Restart MySQL"
systemctl restart mysql

echo "[5/7] Create DB & User (public host)"
mysql <<EOF
CREATE DATABASE IF NOT EXISTS ${DB_NAME};

-- 清掉可能干擾的舊帳號（避免 host 比對踩雷）
DROP USER IF EXISTS '${DB_USER}'@'%';
DROP USER IF EXISTS '${DB_USER}'@'localhost';

-- 建立你實際驗證可行的 host 規則
CREATE USER IF NOT EXISTS '${DB_USER}'@'${DB_USER_HOST}'
  IDENTIFIED BY '${DB_PASS}';

GRANT ALL PRIVILEGES ON ${DB_NAME}.* TO '${DB_USER}'@'${DB_USER_HOST}';
FLUSH PRIVILEGES;

SELECT user, host FROM mysql.user WHERE user='${DB_USER}';
EOF

echo "[6/7] Create table & insert test data"
mysql "${DB_NAME}" <<EOF
CREATE TABLE IF NOT EXISTS test (
  id INT AUTO_INCREMENT PRIMARY KEY,
  msg VARCHAR(64),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO test (msg) VALUES
  ('hello-from-mysql-vm'),
  ('public-ip mysql test'),
  (CONCAT('verify @ ', NOW()));
EOF

echo "[7/7] Verify data"
mysql "${DB_NAME}" <<EOF
SELECT id, msg, created_at
FROM test
ORDER BY id DESC
LIMIT 5;
EOF

echo "✅ MySQL public deploy & test data done"
