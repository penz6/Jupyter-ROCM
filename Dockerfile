FROM rocm/dev-ubuntu-24.04:latest

# Set environment to skip interactive prompts and bypass PEP 668 restrictions
ENV DEBIAN_FRONTEND=noninteractive \
    PIP_BREAK_SYSTEM_PACKAGES=1 \
    PYTHONUNBUFFERED=1

# Install system dependencies needed for ROCm and Python builds
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    git \
    python3-pip \
    python3-dev \
    build-essential && \
    rm -rf /var/lib/apt/lists/*

# Install JupyterLab and extensions globally
RUN python3 -m pip install --no-cache-dir \
    jupyterlab \
    jupyterlab-git \
    catppuccin-jupyterlab \
    ipykernel

# Create the internal mount points
RUN mkdir -p /workspace /tmp-pip /pip-cache /venv /data/home

EXPOSE 8888
WORKDIR /workspace
