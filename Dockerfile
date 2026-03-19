FROM rocm/dev-ubuntu-24.04:7.2

ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONUNBUFFERED=1 \
    HOME=/data/home \
    XDG_CACHE_HOME=/data/home/.cache \
    JUPYTER_CONFIG_DIR=/data/home/.jupyter \
    JUPYTER_DATA_DIR=/data/home/.local/share/jupyter \
    HF_HOME=/data/home/.cache/huggingface \
    HSA_OVERRIDE_GFX_VERSION=10.3.0 \
    LD_LIBRARY_PATH=/opt/rocm/lib:/opt/rocm/lib64:${LD_LIBRARY_PATH:-} \
    PATH="/venv/bin:/data/home/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

RUN apt-get update && apt-get install -y --no-install-recommends \
      python3 \
      python3-pip \
      python3-venv \
      git \
      curl \
      ca-certificates \
      libgl1 \
      libglib2.0-0 \
      rocminfo \
      rocm-smi-lib \
      rocm-ml-libraries && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

RUN mkdir -p \
      /workspace \
      /venv \
      /data/home \
      /data/home/.cache \
      /data/home/.jupyter \
      /data/home/.local/share/jupyter

WORKDIR /workspace
EXPOSE 8888

CMD ["bash", "-lc", "\
set -e; \
unset PIP_USER; \
export PIP_CONFIG_FILE=/dev/null; \
mkdir -p \
  \"$HOME/.cache\" \
  \"$HOME/.cache/huggingface\" \
  \"$HOME/.jupyter/lab/user-settings/@jupyterlab/apputils-extension\" \
  \"$JUPYTER_DATA_DIR\" \
  /workspace; \
if [ ! -x /venv/bin/python ]; then \
  echo '--- Creating venv on persistent volume ---'; \
  python3 -m venv /venv; \
fi; \
echo '--- Ensuring Jupyter is installed in /venv ---'; \
/venv/bin/python -m pip install --no-cache-dir --upgrade pip setuptools wheel; \
if ! /venv/bin/python -c 'import jupyterlab, ipykernel' >/dev/null 2>&1; then \
  /venv/bin/python -m pip install --no-cache-dir jupyterlab ipykernel; \
fi; \
cat > \"$HOME/.jupyter/lab/user-settings/@jupyterlab/apputils-extension/themes.jupyterlab-settings\" <<'JSON'\n\
{\n\
  \"theme\": \"JupyterLab Dark\",\n\
  \"theme-scrollbars\": true\n\
}\n\
JSON\n\
/venv/bin/python -m ipykernel install --sys-prefix --name venv --display-name 'Python (venv)' >/dev/null 2>&1 || true; \
echo '--- Launching JupyterLab from /venv ---'; \
exec /venv/bin/python -m jupyterlab \
  --ip=0.0.0.0 \
  --port=8888 \
  --no-browser \
  --allow-root \
  --ServerApp.root_dir=/workspace \
  --ServerApp.token='' \
"]
