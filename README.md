# JupyterLab ROCm Container

- Small ROCm-based JupyterLab image
- Includes:
  - JupyterLab 4
  - Git CLI
  - `jupyterlab-git`
  - Catppuccin theme
- Does **not** bake Torch into the image
- Torch installs separately into mapped `/venv`

## Volume Mappings

- `/root/.cache` → model caches
- `/pip-cache` → pip download cache
- `/venv` → persistent Python packages like Torch
- `/tmp-pip` → pip temp extraction
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
