FROM rocm/dev-ubuntu-24.04:latest

# 1. Environment Configuration
ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONUNBUFFERED=1 \
    HOME=/data/home \
    # Mandatory for RX 6750 XT (Navi 22)
    HSA_OVERRIDE_GFX_VERSION=10.3.0 \
    # Critical: Tells TensorFlow where the slim ROCm libraries live
    LD_LIBRARY_PATH=/opt/rocm/lib:/opt/rocm/lib64:${LD_LIBRARY_PATH} \
    PATH="/venv/bin:/data/home/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin" \
    PIP_CACHE_DIR=/pip-cache \
    TMPDIR=/tmp-pip

# 2. System Dependencies (Surgical Install to avoid 11GB bloat)
# We only install the runtimes and the specific 6750 XT (gfx1030) kernels.
RUN apt-get update && \
    # --- FIX: Prioritize AMD Repo over Ubuntu Stock ---
    echo "Package: *\nPin: release o=repo.radeon.com\nPin-Priority: 600" > /etc/apt/preferences.d/rocm-pin-600 && \
    \
    apt-get install -y --no-install-recommends \
    git \
    curl \
    python3-pip \
    python3-dev \
    python3-venv \
    build-essential \
    libgl1 \
    libglib2.0-0 \
    # Essential ROCm runtimes
    hip-runtime-amd \
    rccl \
    rocblas \
    # Target your 6750 XT specifically
    miopen-hip-gfx1030kdb && \
    \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# 3. Bake Jupyter into the System (Ensures UI is always available)
RUN pip install --no-cache-dir --break-system-packages \
    jupyterlab \
    jupyterlab-git \
    catppuccin-jupyterlab \
    ipykernel

# 4. Create Mount Point Placeholders
RUN mkdir -p /workspace /data/home /venv /root/.cache /pip-cache /tmp-pip

WORKDIR /workspace
EXPOSE 8888

# 5. Startup Logic for Persistent Volume
CMD ["bash", "-c", "\
    mkdir -p /data/home/.jupyter /data/home/.local/share/jupyter/kernels /data/home/.local/share/jupyter/runtime /data/home/bin && \
    \
    # If the persistent venv is empty, initialize it once
    if [ ! -f /venv/bin/python ]; then \
        echo '--- Persistent venv empty. Initializing on volume... ---'; \
        python3 -m venv /venv && \
        /venv/bin/pip install --upgrade pip; \
        # Install TF-ROCm with the specific ROCm 7.2 index
        /venv/bin/pip install --no-cache-dir \
            tensorflow-rocm==2.19.1 \
            -f https://repo.radeon.com/rocm/manylinux/rocm-rel-7.2/; \
        echo '--- Venv and TensorFlow ready on persistent volume. ---'; \
    fi; \
    \
    # Refresh kernel registration to the persistent home
    /venv/bin/python -m ipykernel install \
        --name=venv \
        --display-name='Python (venv)' \
        --data-dir=/data/home/.local/share/jupyter && \
    \
    echo '--- Starting Jupyter Lab ---'; \
    jupyter lab \
        --ip=0.0.0.0 \
        --port=8888 \
        --no-browser \
        --allow-root \
        --ServerApp.root_dir=/workspace \
        --ServerApp.preferred_dir=/workspace \
        --IdentityProvider.token='' \
        --PasswordIdentityProvider.hashed_password='' \
    "]
