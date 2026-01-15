#!/usr/bin/env bash
set -e

IMAGE="docker.io/jupyter/base-notebook:latest"
NAME="jupyter"
DATA="$HOME/jupyter-data"

mkdir -p "$DATA"

echo "[1/3] Pull image"
sudo ctr image pull $IMAGE

echo "[2/3] Run Jupyter (host network)"
sudo ctr run \
  --rm \
  --net-host \
  --mount type=bind,src=$DATA,dst=/home/jovyan/work,options=rbind:rw \
  $IMAGE \
  $NAME \
  start-notebook.sh \
    --NotebookApp.ip=0.0.0.0 \
    --NotebookApp.token='' \
    --NotebookApp.password=''

echo "[DONE] Open http://<IP>:8888"

