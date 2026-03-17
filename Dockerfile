FROM rocm/dev-ubuntu-24.04:latest

ENV DEBIAN_FRONTEND=noninteractive \
    PIP_BREAK_SYSTEM_PACKAGES=1 \
    PYTHONUNBUFFERED=1 \
    HOME=/data/home

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    git \
    curl \
    python3-pip \
    python3-dev \
    python3-venv \
    build-essential && \
    rm -rf /var/lib/apt/lists/*

RUN pip install --no-cache-dir \
    jupyterlab \
    jupyterlab-git \
    catppuccin-jupyterlab \
    ipykernel

RUN mkdir -p /workspace /tmp-pip /pip-cache /venv /data/home

EXPOSE 8888
WORKDIR /workspace

CMD ["bash", "-lc", "\
  mkdir -p /data/home/.jupyter /data/home/.local/share/jupyter/runtime /data/home/bin && \
  export HOME=/data/home && \
  export PATH=/venv/bin:/data/home/bin:/data/home/.local/bin:$PATH && \
  export TMPDIR=/tmp-pip && \
  export PIP_CACHE_DIR=/pip-cache && \
  export JUPYTER_CONFIG_DIR=/data/home/.jupyter && \
  export JUPYTER_DATA_DIR=/data/home/.local/share/jupyter && \
  export JUPYTER_RUNTIME_DIR=/data/home/.local/share/jupyter/runtime && \
  if [ ! -f /venv/bin/pip ]; then \
    curl https://bootstrap.pypa.io/get-pip.py -o /tmp/get-pip.py && \
    /venv/bin/python /tmp/get-pip.py --no-cache-dir; \
  fi && \
  if [ -f /venv/bin/pip ]; then \
    if ! /venv/bin/python -m ipykernel --version &>/dev/null; then \
      /venv/bin/pip install --no-cache-dir ipykernel; \
    fi && \
    /venv/bin/python -m ipykernel install --user --name=venv --display-name='Python (venv)'; \
  fi && \
  jupyter lab \
    --ip=0.0.0.0 \
    --port=8888 \
    --no-browser \
    --allow-root \
    --ServerApp.root_dir=/workspace \
    --ServerApp.preferred_dir=/workspace \
    --IdentityProvider.token='' \
    --PasswordIdentityProvider.hashed_password=''"]
