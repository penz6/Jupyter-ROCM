# JupyterLab ROCm Container

Minimal JupyterLab environment with ROCm GPU support designed for persistent storage and easy extension installation.

## Features
- ROCm GPU support
- JupyterLab 4
- PyTorch ROCm
- Git CLI installed
- `jupyterlab-git` extension
- Web UI extension installs enabled
- Modern dark theme available (Catppuccin)
- Persistent config and workspace

## Volume Mappings

- `/root/.cache` → model caches (huggingface, etc.)
- `/pip-cache` → pip download cache
- `/venv` → optional persistent python packages
- `/tmp-pip` → pip temporary extraction
- `/data/home` → Jupyter config, extensions, user packages
- `/workspace` → notebooks and projects

## Example Run

```bash
docker run -d \
  --name jupyterlab-rocm \
  --device=/dev/kfd \
  --device=/dev/dri \
  --ipc=host \
  -p 8888:8888 \
  -v /mnt/user/appdata/jupyterlab/cache:/root/.cache \
  -v /mnt/user/appdata/jupyterlab/pip-cache:/pip-cache \
  -v /mnt/user/appdata/jupyterlab/venv:/venv \
  -v /mnt/user/appdata/jupyterlab/tmp:/tmp-pip \
  -v /mnt/user/appdata/jupyterlab/home:/data/home \
  -v /mnt/user/appdata/jupyterlab/workspace:/workspace \
  <image-name>
