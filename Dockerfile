FROM ubuntu:24.04

# 1. Environment Configuration
ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONUNBUFFERED=1 \
    HSA_OVERRIDE_GFX_VERSION=10.3.0 \
    LD_LIBRARY_PATH=/opt/rocm/lib:/opt/rocm/lib64:${LD_LIBRARY_PATH:-} \
    PATH="/venv/bin:/data/home/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin" \
    HOME=/data/home

# 2. Robust Repo Setup & Surgical Install
RUN apt-get update && apt-get install -y --no-install-recommends wget gnupg2 ca-certificates && \
    mkdir -p /etc/apt/keyrings && \
    wget -qO - https://repo.radeon.com/rocm/rocm.gpg.key | gpg --dearmor -o /etc/apt/keyrings/rocm.gpg && \
    # Adding the specific 7.2 Noble repository
    echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/rocm.gpg] https://repo.radeon.com/rocm/apt/7.2 noble main" > /etc/apt/sources.list.d/rocm.list && \
    apt-get update && \
    \
    # Install Python and UI essentials
    apt-get install -y --no-install-recommends \
    python3-pip python3-venv git curl libgl1 libglib2.0-0 && \
    \
    # Install ONLY the 7.2 Runtime and 6750 XT Kernels
    # hip-runtime-amd is the 'bridge' for Python/Tensorflow
    apt-get install -y --no-install-recommends \
    rocm-core \
    hsa-rocr \
    hip-runtime-amd \
    rocblas-gfx1030kdb \
    miopen-hip-gfx1030kdb && \
    \
    # Install Jupyter at system level
    pip install --no-cache-dir --break-system-packages jupyterlab ipykernel && \
    \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# 3. Setup Persistent Paths
RUN mkdir -p /workspace /data/home /venv
WORKDIR /workspace
EXPOSE 8888

# 4. Startup Script (Preserves your persistent venv)
CMD ["bash", "-c", "\
    if [ ! -f /venv/bin/python ]; then \
        echo '--- Creating venv on persistent volume ---'; \
        python3 -m venv /venv && \
        /venv/bin/pip install --upgrade pip; \
    fi; \
    \
    # Register the kernel so it appears in Jupyter
    /venv/bin/python -m ipykernel install --user --name venv --display-name 'Python (venv)' && \
    \
    echo '--- Launching Jupyter Lab ---'; \
    jupyter lab --ip=0.0.0.0 --port=8888 --no-browser --allow-root --ServerApp.token='' \
    "]
