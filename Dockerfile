FROM rocm/dev-ubuntu-24.04:latest

ENV DEBIAN_FRONTEND=noninteractive
ENV HOME=/data/home
ENV PATH=/data/home/.local/bin:$PATH
ENV TMPDIR=/tmp-pip
ENV PIP_CACHE_DIR=/pip-cache
ENV PIP_BREAK_SYSTEM_PACKAGES=1
ENV PIP_USER=1
ENV JUPYTER_CONFIG_DIR=/data/home/.jupyter
ENV JUPYTER_DATA_DIR=/data/home/.local/share/jupyter
ENV JUPYTER_RUNTIME_DIR=/data/home/.local/share/jupyter/runtime

RUN apt-get update && \
    apt-get install -y --no-install-recommends git python3-pip && \
    rm -rf /var/lib/apt/lists/*

RUN mkdir -p /data/home/.jupyter /data/home/.local/share/jupyter/runtime /workspace /tmp-pip /pip-cache

RUN python3 -m pip install --break-system-packages --user --upgrade pip setuptools wheel && \
    python3 -m pip install --break-system-packages --user --upgrade \
      jupyterlab \
      jupyterlab-git \
      catppuccin-jupyterlab && \
    python3 -m pip install --break-system-packages --user --pre \
      --index-url https://download.pytorch.org/whl/nightly/rocm7.2 \
      torch

EXPOSE 8888

CMD ["bash", "-lc", "jupyter lab --ip=0.0.0.0 --port=8888 --no-browser --allow-root --ServerApp.root_dir=/workspace --ServerApp.preferred_dir=/workspace --IdentityProvider.token='' --PasswordIdentityProvider.hashed_password=''"]
