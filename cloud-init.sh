#!/bin/bash
set -euxo pipefail

# =========================================================
# Configuration
# =========================================================
REPO_URL="https://github.com/CYH4157/vmware_jupyter.git"
INSTALL_DIR="/opt/vmware_jupyter"

INSTALL_SCRIPT="install_container.sh"
RUN_SCRIPT="run_jupyter.sh"

echo "=== [cloud-init] Start at $(date -Is) ==="

# =========================================================
# 1. Install required system packages
# =========================================================
apt-get update -y
apt-get install -y git ca-certificates curl net-tools

# =========================================================
# 2. Clone (or update) the repository
#    This keeps the image clean and allows easy updates
# =========================================================
if [ ! -d "${INSTALL_DIR}/.git" ]; then
  rm -rf "${INSTALL_DIR}"
  git clone "${REPO_URL}" "${INSTALL_DIR}"
else
  cd "${INSTALL_DIR}"
  git pull || true
fi

cd "${INSTALL_DIR}"

# =========================================================
# 3. Ensure scripts are executable
# =========================================================
chmod +x "${INSTALL_SCRIPT}" "${RUN_SCRIPT}"

# =========================================================
# 4. Run install script
#    - Install containerd
#    - Create systemd unit for Jupyter
#    - Enable the service
# =========================================================
echo "=== [cloud-init] Running install script ==="
./"${INSTALL_SCRIPT}"

# =========================================================
# 5. Wait until containerd is fully ready
#    (Do NOT rely on fixed sleep)
# =========================================================
echo "=== [cloud-init] Waiting for containerd ==="
systemctl enable --now containerd || true

until systemctl is-
