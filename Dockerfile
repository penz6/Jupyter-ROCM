# START FROM BLANK UBUNTU (100MB) INSTEAD OF ROCM-DEV (9GB)
FROM ubuntu:24.04

# 1. Essential Environment
ENV DEBIAN_FRONTEND=noninteractive \
    HSA_OVERRIDE_GFX_VERSION=10.3.0 \
    LD_LIBRARY_PATH=/opt/rocm/lib:/opt/rocm/lib64:${LD_LIBRARY_PATH:-} \
    PATH="/venv/bin:/data/home/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin" \
    HOME=/data/home

# 2. Add AMD Repo and Install ONLY the 4 Runtime Libs
RUN apt-get update && apt-get install -y wget gnupg2 && \
    mkdir -p /etc/apt/keyrings && \
    wget -qO - https://repo.radeon.com/rocm/rocm.gpg.key | gpg --dearmor -o /etc/apt/keyrings/rocm.gpg && \
    echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/rocm.gpg] https://repo.radeon.com/rocm/apt/7.2 noble main" > /etc/apt/sources.list.d/rocm.list && \
    apt-get update && \
    \
    # Install Python + The 4 specific GPU files TensorFlow needs
    apt-get install -y --no-install-recommends \
    python3-pip python3-venv git curl \
    libgl1 libglib2.0-0 \
    # THESE ARE THE ONLY ROCM FILES YOU NEED TO RUN AI
    hip-runtime-amd rccl rocblas miopen-hip && \
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
        python3 -m venv /venv && \
        /venv/bin/pip install --upgrade pip; \
    fi; \
    /venv/bin/python -m ipykernel install --user --name venv --display-name 'Python (venv)' && \
    jupyter lab --ip=0.0.0.0 --port=8888 --no-browser --allow-root --ServerApp.token='' \
    "]
