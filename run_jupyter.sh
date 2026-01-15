#!/usr/bin/env bash
set -euo pipefail

SERVICE_NAME="jupyter-containerd"
IMAGE="docker.io/jupyter/base-notebook:latest"
BASE_DIR="/srv/jupyter"
WORK_DIR="${BASE_DIR}/work"
ENV_FILE="/etc/default/${SERVICE_NAME}"
UNIT_FILE="/etc/systemd/system/${SERVICE_NAME}.service"

CTR_BIN="$(command -v ctr || true)"
if [[ -z "${CTR_BIN}" ]]; then
  echo "[ERROR] ctr not found. Please install containerd first."
  exit 1
fi

echo "=== [STEP 1] Create persistent directories ==="
sudo mkdir -p "${WORK_DIR}"
sudo chmod 777 "${WORK_DIR}"

echo "=== [STEP 2] Prompt Jupyter password (will be stored in ${ENV_FILE}) ==="
# 互動式輸入密碼（不回顯），存到 env 檔（由容器內自動轉 hash）
JUPYTER_PW="$(bash -lc 'read -s -p "Set Jupyter password: " p1; echo; read -s -p "Confirm password: " p2; echo; [[ "$p1" == "$p2" ]] || exit 3; echo "$p1"')"
if [[ -z "${JUPYTER_PW}" ]]; then
  echo "[ERROR] Empty password is not allowed."
  exit 1
fi

echo "=== [STEP 3] Write env file: ${ENV_FILE} ==="
sudo tee "${ENV_FILE}" >/dev/null <<EOF
# Jupyter (containerd) settings
IMAGE=${IMAGE}
NAME=${SERVICE_NAME}
WORK_DIR=${WORK_DIR}
PORT=8888
JUPYTER_PASSWORD="${JUPYTER_PW}"
EOF

# 鎖權限（避免其他人讀到明文密碼）
sudo chmod 600 "${ENV_FILE}"

echo "=== [STEP 4] Write systemd unit: ${UNIT_FILE} ==="
sudo tee "${UNIT_FILE}" >/dev/null <<'EOF'
[Unit]
Description=Jupyter (containerd/ctr)
After=network-online.target containerd.service
Wants=network-online.target
Requires=containerd.service

[Service]
Type=simple
EnvironmentFile=/etc/default/jupyter-containerd

# 清理舊的 container/task（避免重啟卡住）
ExecStartPre=/usr/bin/bash -lc '/usr/bin/ctr task kill ${NAME} >/dev/null 2>&1 || true'
ExecStartPre=/usr/bin/bash -lc '/usr/bin/ctr task rm ${NAME} >/dev/null 2>&1 || true'
ExecStartPre=/usr/bin/bash -lc '/usr/bin/ctr container rm ${NAME} >/dev/null 2>&1 || true'

# 確保 image 存在
ExecStartPre=/usr/bin/bash -lc '/usr/bin/ctr image pull ${IMAGE}'

# 啟動 Jupyter：host network（直接 http://host:8888）
# 用 JUPYTER_PASSWORD 讓容器內自動產生正確的 hash，避免 InvalidHashError
ExecStart=/usr/bin/bash -lc '\
  export JUPYTER_PASSWORD="${JUPYTER_PASSWORD}"; \
  /usr/bin/ctr run --rm --net-host \
    --mount type=bind,src=${WORK_DIR},dst=/home/jovyan/work,options=rbind:rw \
    ${IMAGE} ${NAME} \
    start-notebook.sh \
      --ServerApp.ip=0.0.0.0 \
      --ServerApp.port=${PORT} \
      --ServerApp.token="" \
      --ServerApp.allow_remote_access=True \
'

Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF

echo "=== [STEP 5] Reload systemd and enable service ==="
sudo systemctl daemon-reload
sudo systemctl enable --now "${SERVICE_NAME}"

echo "=== [DONE] Service is up ==="
echo "Open: http://<your-ip>:8888"
echo "Check logs: sudo journalctl -u ${SERVICE_NAME} -f"
