FROM ghcr.io/astral-sh/uv:python3.13-bookworm-slim

# Install core dependencies and kubectl (Removed Node.js completely)
RUN apt-get update && \
    apt-get install -y curl gnupg ca-certificates git sudo wget libatomic1 procps htop zip apt-transport-https && \
    # Install kubectl (CRITICAL for applying eBPF and Istio YAMLs)
    curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.29/deb/Release.key | gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg && \
    echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.29/deb/ /' | tee /etc/apt/sources.list.d/kubernetes.list && \
    apt-get update && \
    apt-get install -y kubectl && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Create a non-root user
RUN useradd -ms /bin/bash coder && \
    echo "coder ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/nopasswd

RUN chmod -R 777 /usr && \
    chmod 4755 /usr/bin/sudo

RUN curl -L "https://update.code.visualstudio.com/1.100.1/cli-linux-x64/stable" -o vscode-cli.tar.gz && \
    tar -xzf vscode-cli.tar.gz && \
    rm vscode-cli.tar.gz && \
    mv code /usr/local/bin/vscode && \
    chmod +x /usr/local/bin/vscode

# Pre-install workshop Python dependencies (Fast uv install)
RUN uv pip install --system pydantic-monty pydantic-ai requests

USER coder
WORKDIR /home/coder

# Pre-warm VS Code and install the Python Extension for better UX
RUN setsid vscode serve-web --host 127.0.0.1 --port 9999 --accept-server-license-terms --without-connection-token & \
    sleep 5 && \
    vscode --install-extension ms-python.python && \
    curl -s http://127.0.0.1:9999 > /dev/null && \
    sleep 30 && \
    pkill -f "vscode serve-web" || true

RUN rm -rf /home/coder/.vscode-server/.cache

# Create a dedicated workspace directory
WORKDIR /home/coder/workspace

EXPOSE 8000

# Start VS Code directly inside the cloned workspace folder
CMD ["vscode", "serve-web", "--host=0.0.0.0", "--port=8000", "--without-connection-token", "--accept-server-license-terms"]
