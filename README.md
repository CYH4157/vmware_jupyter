# vmware_jupyter


```text
jupyter-containerd-systemd/
├── install_container.sh 
├── 
├── README.md
├── .gitignore
└── LICENSE        # 可選（MIT / Apache-2.0）
```


```markdown
# Jupyter with containerd + systemd

Run Jupyter Notebook/Lab using **containerd (ctr)** instead of Docker,
managed by **systemd**, and automatically started on boot.

Tested on:
- Ubuntu 20.04 LTS
- containerd >= 1.6

---

## Features

- ✅ containerd / ctr (no Docker required)
- ✅ systemd managed (auto start on boot)
- ✅ Password protected Jupyter
- ✅ Persistent workspace on host
- ✅ Simple, single-node setup

---

## Prerequisites

```bash
sudo apt install -y containerd.io
sudo systemctl enable --now containerd
```

* * *

## Install


