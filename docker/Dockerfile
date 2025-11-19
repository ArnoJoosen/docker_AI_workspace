# Build argument to choose between 'cuda', 'cpu' and 'rocm'
ARG BUILD_TARGET=cuda
# Build argument to select python version for the python environment
ARG PYTHON_VERSION=3.10
# Build arguemnt to set username of the non-root user
ARG USERNAME=user
# User ID and Group ID arguments to match host user
ARG USER_UID=1000
ARG USER_GID=1000
# Passwords and Keys
ARG ROOT_PASSWORD=rootpassword
ARG USER_PASSWORD=userpassword
ARG SSH_PUBLIC_KEY
# JupyterLab configuration arguments
ARG JUPYTER_TOKEN=my_secure_jupyter_token_123


# Use build stage based on the selected BUILD_TARGET
FROM nvidia/cuda:12.6.3-cudnn-devel-ubuntu24.04 AS cuda
FROM ubuntu:24.04 AS cpu
FROM rocm/dev-ubuntu-22.04 AS rocm
FROM ${BUILD_TARGET}

# Re-declare ARGs to be available in this build stage
ARG PYTHON_VERSION
ARG USERNAME
ARG USER_UID
ARG USER_GID
ARG ROOT_PASSWORD
ARG USER_PASSWORD
ARG SSH_PUBLIC_KEY
ARG JUPYTER_TOKEN

# Update package lists and install SSH server and other utilities
# The 'tzdata' package is pre-installed to avoid interactive prompts during installation.
RUN apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    apt-get update --fix-missing && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    tzdata \
    openssh-server \
    supervisor \
    sudo \
    curl \
    wget \
    vim \
    git \
    software-properties-common \
    build-essential \
    libgl1 \
    libglib2.0-0 \
    && rm -rf /var/lib/apt/lists/*

# Update and install software-properties-common to manage PPAs
RUN apt-get update && apt-get install -y software-properties-common \
    && add-apt-repository ppa:deadsnakes/ppa -y \
    && apt-get update \
    && apt-get install -y python${PYTHON_VERSION} python${PYTHON_VERSION}-distutils python${PYTHON_VERSION}-venv python${PYTHON_VERSION}-dev python3-pip \
    && update-alternatives --install /usr/bin/python3 python3 /usr/bin/python${PYTHON_VERSION} 1 \
    && update-alternatives --set python3 /usr/bin/python${PYTHON_VERSION} \
    && rm -rf /var/lib/apt/lists/*

# Verify installed version
RUN python3 --version

# System pip is sufficient, skip upgrade to avoid conflicts

# Create symlinks for compatibility
RUN ln -sf /usr/bin/python${PYTHON_VERSION} /usr/bin/python \
    && ln -sf /usr/bin/pip3 /usr/bin/pip


# Install additional Python packages through apt (safer for system packages)
RUN apt-get update && apt-get install -y \
    python3-full \
    pipx \
    && rm -rf /var/lib/apt/lists/*

# Remove externally-managed-environment file and create pip configuration
RUN rm -f /usr/lib/python*/EXTERNALLY-MANAGED
RUN mkdir -p /etc/pip && printf "[global]\nbreak-system-packages = true\n" > /etc/pip/pip.conf

# Configure SSH
RUN mkdir /var/run/sshd
RUN echo "root:${ROOT_PASSWORD}" | chpasswd
RUN sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config
RUN sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config

# SSH login fix. Otherwise user is kicked off after login
RUN sed 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' -i /etc/pam.d/sshd

# Create a second user with matching UID/GID
# First, check if UID/GID already exist and handle accordingly
RUN if id ${USER_UID} >/dev/null 2>&1; then \
    existing_user=$(id -nu ${USER_UID}); \
    userdel -f $existing_user || true; \
    groupdel $existing_user 2>/dev/null || true; \
    fi && \
    if getent group ${USER_GID} >/dev/null 2>&1; then \
    existing_group=$(getent group ${USER_GID} | cut -d: -f1); \
    if [ "$existing_group" != "${USERNAME}" ]; then \
    groupdel $existing_group 2>/dev/null || true; \
    fi; \
    fi && \
    groupadd -g ${USER_GID} ${USERNAME} && \
    useradd -m -u ${USER_UID} -g ${USER_GID} -s /bin/bash -G sudo ${USERNAME}
RUN echo "${USERNAME}:${USER_PASSWORD}" | chpasswd

# Allow sudo without password for the user (optional)
RUN echo "${USERNAME} ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Create SSH directory for user
RUN mkdir -p /home/${USERNAME}/.ssh
RUN chown ${USERNAME}:${USERNAME} /home/${USERNAME}/.ssh
RUN chmod 700 /home/${USERNAME}/.ssh

# Add SSH public key from environment variable
RUN if [ -n "$SSH_PUBLIC_KEY" ]; then \
    echo "$SSH_PUBLIC_KEY" > /home/${USERNAME}/.ssh/authorized_keys && \
    chown ${USERNAME}:${USERNAME} /home/${USERNAME}/.ssh/authorized_keys && \
    chmod 600 /home/${USERNAME}/.ssh/authorized_keys; \
    fi

# Create supervisor log directory
RUN mkdir -p /var/log/supervisor

# Expose SSH port
EXPOSE 22

# Set environment variables
ENV NOTVISIBLE "in users profile"
RUN echo "export VISIBLE=now" >> /etc/profile

# Enable SSH service to start automatically
#RUN systemctl enable ssh

USER ${USERNAME}
# Re-declare ARG for this build stage
ARG PYTHON_VERSION
RUN mkdir -p /home/${USERNAME}/workspace
RUN python${PYTHON_VERSION} -m venv /home/${USERNAME}/.venv
RUN echo "source /home/${USERNAME}/.venv/bin/activate" >> /home/${USERNAME}/.bashrc

# Install JupyterLab in the virtual environment
RUN /home/${USERNAME}/.venv/bin/pip install --upgrade pip
RUN /home/${USERNAME}/.venv/bin/pip install \
    jupyterlab \
    jupyterlab-lsp \
    jedi-language-server

# Switch back to root for final system setup
USER root

# Copy supervisord configuration
COPY docker/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Re-declare args for workspace ownership fix
ARG USER_UID
ARG USER_GID
ARG USERNAME

# Fix ownership of entire user home directory to ensure proper permissions
RUN chown -R ${USER_UID}:${USER_GID} /home/${USERNAME}

# Copy and setup entrypoint script
COPY docker/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Set working directory
WORKDIR /home/${USERNAME}/workspace

# Set environment variables for runtime
ENV JUPYTER_TOKEN=${JUPYTER_TOKEN}
ENV ENV_USERNAME=${USERNAME}

# Expose ports for SSH and JupyterLab
EXPOSE 8888
EXPOSE 22

# Use entrypoint script to ensure proper ownership at runtime
ENTRYPOINT ["/entrypoint.sh"]
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
