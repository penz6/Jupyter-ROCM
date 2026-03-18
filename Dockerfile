FROM ubuntu:24.04

# 1. Environment Configuration
# HSA_OVERRIDE_GFX_VERSION=10.3.0 is required for RX 6750 XT
# Using ${LD_LIBRARY_PATH:-} fixes the "UndefinedVar" warning in your logs
ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONUNBUFFERED=1 \
    HSA_OVERRIDE_GFX_VERSION=10.3.0 \
    LD_LIBRARY_PATH=/opt/rocm/lib:/opt/rocm/lib64:${LD_LIBRARY_PATH:-} \
    PATH="/venv/bin:/data/home/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin" \
    HOME=/data/home

# 2. Surgical Installation (Bypasses the 9GB bloat)
RUN apt-get update && apt-get install -y --no-install-recommends \
    wget gnupg2 ca-certificates && \
    mkdir -p /etc/apt/keyrings && \
    wget -qO - https://repo.radeon.com/rocm/rocm.gpg.key | gpg --dearmor -o /etc/apt/keyrings/rocm.gpg && \
    echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/rocm.gpg] https://repo.radeon.com/rocm/apt/7.2 noble main" > /etc/apt/sources.list.d/rocm.list && \
    apt-get update && \
    \
    # Install Python and basic utilities
    apt-get install -y --no-install-recommends \
    python3-pip python3-venv git curl libgl1 libglib2.0-0 && \
    \
    # --- THE SURGERY ---
    # We install 'lib' versions. These are tiny compared to the meta-packages.
    apt-get install -y --no-install-recommends \
    libamdhip64-6 \
    librocblas0 \
    libmiopen-hip0 \
    librccl1 \
    # We install ONLY the kernels for your Navi 22 card (gfx1030)
    rocblas-gfx1030 \
    miopen-hip-gfx1030 && \
    \
    # Install Jupyter UI at system level
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
        echo '--- Initializing Venv on Persistent Volume ---'; \
        python3 -m venv /venv && \
        /venv/bin/pip install --upgrade pip; \
    fi; \
    /venv/bin/python -m ipykernel install --user --name venv --display-name 'Python (venv)' && \
    echo '--- Starting Jupyter Lab ---'; \
    jupyter lab --ip=0.0.0.0 --port=8888 --no-browser --allow-root --ServerApp.token='' \
    "]
