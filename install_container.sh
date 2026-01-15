sudo apt update
sudo apt install -y ca-certificates curl gnupg lsb-release

# 建立 keyring
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | \
  sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

# 加 repo（focal）
echo \
"deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
https://download.docker.com/linux/ubuntu focal stable" | \
sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt update
sudo apt install -y containerd.io


echo "[Step 2] check containerd service status"
sudo systemctl enable --now containerd
systemctl status containerd --no-pager


sudo mkdir -p /etc/containerd
containerd config default | sudo tee /etc/containerd/config.toml > /dev/null
sudo systemctl restart containerd

sudo containerd --version
sudo ctr version

sudo ctr image pull docker.io/library/alpine:latest
sudo ctr run --rm docker.io/library/alpine:latest test echo "containerd OK"

