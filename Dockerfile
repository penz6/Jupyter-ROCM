FROM rocm/dev-ubuntu-24.04:latest

# 1. Environment Configuration
# HSA_OVERRIDE_GFX_VERSION is mandatory for RX 6750 XT (Navi 22)
# LD_LIBRARY_PATH is set with a fallback to avoid Docker build warnings
ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONUNBUFFERED=1 \
    HOME=/data/home \
    HSA_OVERRIDE_GFX_VERSION=10.3.0 \
    LD_LIBRARY_PATH=/opt/rocm/lib:/opt/rocm/lib64:${LD_LIBRARY_PATH:-} \
    PATH="/venv/bin:/data/home/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin" \
    PIP_CACHE_DIR=/pip-cache \
    TMPDIR=/tmp-pip

# 2. System Dependencies (Slimmed for RX 6750 XT)
# Using --no-install-recommends is what keeps this from being 11GB.
RUN apt-get update && \
    echo "Package: *\nPin: release o=repo.radeon.com\nPin-Priority: 600" > /etc/apt/preferences.d/rocm-pin-600 && \
    apt-get install -y --no-install-recommends \
    git \
    curl \
    python3-pip \
    python3-dev \
    python3-venv \
    build-essential \
    libgl1 \
    libglib2.0-0 \
    # Core ROCm runtimes for TensorFlow
    hip-runtime-amd \
    rccl \
    rocblas \
    miopen-hip && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# 3. Bake Jupyter into the Image (System Level)
RUN pip install --no-cache-dir --break-system-packages \
    jupyterlab \
    jupyterlab-git \
    catppuccin-jupyterlab \
    ipykernel

# 4. Create Mount Point Placeholders
RUN mkdir -p /workspace /data/home /venv /root/.cache /pip-cache /tmp-pip

# 5. Workspace Setup
WORKDIR /workspace
EXPOSE 8888

# 6. Startup Script Logic for Persistent Volume
CMD ["bash", "-c", "\
    # Ensure directory structure in persistent home \
    mkdir -p /data/home/.jupyter /data/home/.local/share/jupyter/kernels /data/home/.local/share/jupyter/runtime /data/home/bin && \
    \
    # Initialize venv if the volume is empty \
    if [ ! -f /venv/bin/python ]; then \
        echo '--- Persistent venv empty. Initializing... ---'; \
        python3 -m venv /venv && \
        /venv/bin/pip install --upgrade pip; \
        echo '--- Installing TensorFlow-ROCm ---'; \
        /venv/bin/pip install --no-cache-dir \
            tensorflow-rocm==2.19.1 \
            -f https://repo.radeon.com/rocm/manylinux/rocm-rel-7.2/; \
        echo '--- Venv and TensorFlow ready. ---'; \
    fi; \
    \
    # Register the persistent venv kernel \
    /venv/bin/python -m ipykernel install \
        --name=venv \
        --display-name='Python (venv)' \
        --data-dir=/data/home/.local/share/jupyter && \
    \
    # Start Jupyter Lab \
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
