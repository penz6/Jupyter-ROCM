FROM rocm/dev-ubuntu-24.04:latest

# 1. Environment Overrides
ENV DEBIAN_FRONTEND=noninteractive \
    PIP_BREAK_SYSTEM_PACKAGES=1 \
    PYTHONUNBUFFERED=1

# 2. Install Essentials
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    git \
    python3-pip \
    python3-dev \
    python3-venv \
    build-essential && \
    rm -rf /var/lib/apt/lists/*

# 3. Global Jupyter Install (to ensure the UI starts)
RUN python3 -m pip install --no-cache-dir \
    jupyterlab \
    jupyterlab-git \
    catppuccin-jupyterlab \
    ipykernel

# 4. Create Mount Points
RUN mkdir -p /workspace /tmp-pip /pip-cache /venv /data/home

EXPOSE 8888
WORKDIR /workspace

# 5. The Ignition Switch (Startup Logic)
CMD ["bash", "-lc", "mkdir -p /data/home/.jupyter /data/home/.local/share/jupyter/runtime /workspace /venv /data/home/bin && [ ! -f /venv/bin/python ] && python3 -m venv /venv && /venv/bin/python -m pip install ipykernel && /venv/bin/python -m ipykernel install --user --name='Persistent-Venv' --display-name='Python (Persistent Venv)' && export HOME=/data/home && export PATH=/venv/bin:/data/home/bin:/data/home/.local/bin:$PATH && export TMPDIR=/tmp-pip && export JUPYTER_CONFIG_DIR=/data/home/.jupyter && export JUPYTER_DATA_DIR=/data/home/.local/share/jupyter && export JUPYTER_RUNTIME_DIR=/data/home/.local/share/jupyter/runtime && jupyter lab --ip=0.0.0.0 --port=8888 --no-browser --allow-root --ServerApp.root_dir=/workspace --ServerApp.preferred_dir=/workspace --IdentityProvider.token='' --PasswordIdentityProvider.hashed_password=''"]
