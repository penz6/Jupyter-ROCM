FROM ubuntu:24.04

# 1. Essential Environment
ENV DEBIAN_FRONTEND=noninteractive \
    HSA_OVERRIDE_GFX_VERSION=10.3.0 \
    LD_LIBRARY_PATH=/opt/rocm/lib:/opt/rocm/lib64:${LD_LIBRARY_PATH:-} \
    PATH="/venv/bin:/data/home/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin" \
    HOME=/data/home

# 2. Minimum System Setup
# We only install Python, Jupyter's needs, and the ROCm "Driver" libraries
RUN apt-get update && apt-get install -y wget gnupg2 && \
    # Add AMD ROCm Repository
    mkdir -p /etc/apt/keyrings && \
    wget -qO - https://repo.radeon.com/rocm/rocm.gpg.key | gpg --dearmor -o /etc/apt/keyrings/rocm.gpg && \
    echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/rocm.gpg] https://repo.radeon.com/rocm/apt/7.2 noble main" > /etc/apt/sources.list.d/rocm.list && \
    apt-get update && \
    \
    # Install ONLY what is strictly necessary
    apt-get install -y --no-install-recommends \
    python3-pip python3-venv git curl \
    libgl1 libglib2.0-0 \
    # These 4 packages are the ONLY ones needed for TF-ROCm to see the GPU
    hip-runtime-amd rccl rocblas miopen-hip && \
    \
    # Install Jupyter at system level (so it's always there)
    pip install --no-cache-dir --break-system-packages jupyterlab ipykernel && \
    \
    # Cleanup
    apt-get clean && rm -rf /var/lib/apt/lists/*

# 3. Setup Directories
RUN mkdir -p /workspace /data/home /venv
WORKDIR /workspace
EXPOSE 8888

# 4. Startup Script
CMD ["bash", "-c", "\
    # Setup venv only if it doesn't exist on your persistent mount
    if [ ! -f /venv/bin/python ]; then \
        python3 -m venv /venv && \
        /venv/bin/pip install --upgrade pip; \
    fi; \
    \
    # Register the kernel so Jupyter sees your persistent venv
    /venv/bin/python -m ipykernel install --user --name venv --display-name 'Python (venv)' && \
    \
    # Start Jupyter
    jupyter lab --ip=0.0.0.0 --port=8888 --no-browser --allow-root --ServerApp.token='' \
    "]
