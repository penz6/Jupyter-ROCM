FROM rocm/dev-ubuntu-24.04:latest

# 1. Environment Configuration
# We set HSA_OVERRIDE_GFX_VERSION for RDNA2 (RX 6000) compatibility
ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONUNBUFFERED=1 \
    HOME=/data/home \
    HSA_OVERRIDE_GFX_VERSION=10.3.0 \
    PATH="/venv/bin:/data/home/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin" \
    PIP_CACHE_DIR=/pip-cache \
    TMPDIR=/tmp-pip

# 2. System Dependencies
# Added libgl1 and libglib2.0 for OpenCV/Vision support often used with ROCm
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    git \
    curl \
    python3-pip \
    python3-dev \
    python3-venv \
    build-essential \
    libgl1 \
    libglib2.0-0 && \
    rm -rf /var/lib/apt/lists/*

# 3. Bake Jupyter into the Image
# We use --break-system-packages because Ubuntu 24.04 restricts system pip by default.
# This ensures Jupyter is ALWAYS available even if /venv is wiped.
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

# 6. Startup Script Logic
# This bootstraps the venv on the first run and starts Jupyter Lab.
CMD ["bash", "-c", "\
    # Ensure internal directory structure for Jupyter in the persistent mount \
    mkdir -p /data/home/.jupyter /data/home/.local/share/jupyter/kernels /data/home/.local/share/jupyter/runtime /data/home/bin && \
    \
    # Check if the persistent venv is initialized \
    if [ ! -f /venv/bin/python ]; then \
        echo '--- Persistent venv not found. Initializing... ---'; \
        python3 -m venv /venv && \
        /venv/bin/pip install --upgrade pip; \
        echo '--- Venv initialized successfully. ---'; \
    fi; \
    \
    # Register/Refresh the venv kernel so it points to the persistent mount \
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
