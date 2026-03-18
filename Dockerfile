FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONUNBUFFERED=1 \
    HSA_OVERRIDE_GFX_VERSION=10.3.0 \
    LD_LIBRARY_PATH=/opt/rocm/lib:/opt/rocm/lib64:${LD_LIBRARY_PATH:-} \
    PATH="/venv/bin:/data/home/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin" \
    HOME=/data/home

RUN apt-get update && apt-get install -y --no-install-recommends \
      ca-certificates wget gnupg2 curl git \
      python3 python3-pip python3-venv \
      libgl1 libglib2.0-0 && \
    mkdir -p /etc/apt/keyrings && \
    wget -qO - https://repo.radeon.com/rocm/rocm.gpg.key | gpg --dearmor -o /etc/apt/keyrings/rocm.gpg && \
    printf 'Package: *\nPin: release o=repo.radeon.com\nPin-Priority: 600\n' > /etc/apt/preferences.d/rocm-pin-600 && \
    echo 'deb [arch=amd64 signed-by=/etc/apt/keyrings/rocm.gpg] https://repo.radeon.com/rocm/apt/7.2/ noble main' > /etc/apt/sources.list.d/rocm.list && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
      rocm-core \
      hsa-rocr \
      hip-runtime-amd \
      rocminfo \
      rocblas \
      miopen-hip && \
    python3 -m pip install --no-cache-dir --break-system-packages \
      jupyterlab ipykernel && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /workspace /data/home /venv
WORKDIR /workspace
EXPOSE 8888

CMD ["bash", "-lc", "\
if [ ! -x /venv/bin/python ]; then \
  echo '--- Creating venv on persistent volume ---'; \
  python3 -m venv /venv && \
  /venv/bin/pip install --upgrade pip; \
fi && \
/venv/bin/python -m ipykernel install --user --name venv --display-name 'Python (venv)' && \
exec jupyter lab --ip=0.0.0.0 --port=8888 --no-browser --allow-root --ServerApp.token='' \
"]
