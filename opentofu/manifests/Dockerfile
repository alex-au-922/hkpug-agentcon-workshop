FROM python:3.13-slim-bookworm

ARG TARGETARCH
ARG DEBIAN_FRONTEND=noninteractive
ARG VSCODE_VERSION=1.115.0
ARG CLAUDE_CODE_VERSION=2.1.100
ARG CODEX_VERSION=rust-v0.118.0

ENV TZ="Asia/Hong_Kong"

# Install core dependencies and kubectl.
RUN apt-get update && \
    apt-get install -y curl gnupg ca-certificates git sudo wget zsh tzdata libatomic1 procps htop zip apt-transport-https && \
    ln -snf "/usr/share/zoneinfo/$TZ" /etc/localtime && \
    echo "$TZ" > /etc/timezone && \
    curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.29/deb/Release.key | gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg && \
    echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.29/deb/ /' | tee /etc/apt/sources.list.d/kubernetes.list && \
    apt-get update && \
    apt-get install -y kubectl && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

RUN useradd -ms /usr/bin/zsh coder && \
    echo "coder ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/nopasswd

RUN chmod 0440 /etc/sudoers.d/nopasswd && \
    chmod 4755 /usr/bin/sudo

RUN chmod -R go-w /usr/share/zsh /usr/local/share/zsh

RUN case "$TARGETARCH" in \
      amd64) VSCODE_ARCH=x64 ;; \
      arm64) VSCODE_ARCH=arm64 ;; \
      *) echo "Unsupported TARGETARCH: $TARGETARCH" >&2; exit 1 ;; \
    esac && \
    curl -L "https://update.code.visualstudio.com/${VSCODE_VERSION}/cli-linux-${VSCODE_ARCH}/stable" -o vscode-cli.tar.gz && \
    tar -xzf vscode-cli.tar.gz && \
    rm vscode-cli.tar.gz && \
    mv code /usr/local/bin/vscode && \
    chmod +x /usr/local/bin/vscode

RUN mkdir -p /home/coder && chown -R coder:coder /home/coder

USER coder
WORKDIR /tmp

ENV HOME="/home/coder"
ENV PATH="/home/coder/.local/bin:/home/coder/.opencode/bin:${PATH}"
ENV SHELL="/usr/bin/zsh"
ENV TZ="Asia/Hong_Kong"

RUN mkdir -p /home/coder/.local/share /home/coder/.vscode/extensions /home/coder/.vscode-data/User /home/coder/.vscode-data/extensions /home/coder/.vscode-server/extensions /home/coder/.zsh/plugins /home/coder/workspace && \
    git clone --depth=1 https://github.com/zsh-users/zsh-autosuggestions.git /home/coder/.zsh/plugins/zsh-autosuggestions && \
    git clone --depth=1 https://github.com/zsh-users/zsh-syntax-highlighting.git /home/coder/.zsh/plugins/zsh-syntax-highlighting

COPY --chown=coder:coder opentofu/manifests/extensions/cache /opt/workshop-vsix-cache

RUN python - <<'PY'
import pathlib
import shutil
import tempfile
import zipfile

cache = pathlib.Path('/opt/workshop-vsix-cache')
roots = [
    pathlib.Path('/home/coder/.vscode/extensions'),
    pathlib.Path('/home/coder/.vscode-data/extensions'),
    pathlib.Path('/home/coder/.vscode-server/extensions'),
]

for archive_path in sorted(cache.glob('*.vsix')):
    with tempfile.TemporaryDirectory() as tmpdir:
        extract_path = pathlib.Path(tmpdir) / 'extract'
        with zipfile.ZipFile(archive_path) as archive:
            archive.extractall(extract_path)
            for info in archive.infolist():
                mode = (info.external_attr >> 16) & 0o7777
                if not mode:
                    continue

                extracted = extract_path / info.filename
                if extracted.exists():
                    extracted.chmod(mode)
        unpacked = extract_path / 'extension'
        for root in roots:
            folder = root / archive_path.stem
            if folder.exists():
                shutil.rmtree(folder)
            shutil.copytree(unpacked, folder)
PY

COPY --chown=coder:coder src/requirements.txt /tmp/requirements.txt

RUN case "$TARGETARCH" in \
      amd64) CLAUDE_ARCH=linux-x64; CODEX_ARCH=x86_64-unknown-linux-musl ;; \
      arm64) CLAUDE_ARCH=linux-arm64; CODEX_ARCH=aarch64-unknown-linux-musl ;; \
      *) echo "Unsupported TARGETARCH: $TARGETARCH" >&2; exit 1 ;; \
    esac && \
    curl -fL "https://storage.googleapis.com/claude-code-dist-86c565f3-f756-42ad-8dfa-d59b1c096819/claude-code-releases/${CLAUDE_CODE_VERSION}/${CLAUDE_ARCH}/claude" -o /tmp/claude && \
    sudo install -m 0755 /tmp/claude /usr/local/bin/claude && \
    curl -fL "https://github.com/openai/codex/releases/download/${CODEX_VERSION}/codex-${CODEX_ARCH}.tar.gz" -o /tmp/codex.tgz && \
    tar -xzf /tmp/codex.tgz -C /tmp && \
    sudo install -m 0755 "/tmp/codex-${CODEX_ARCH}" /usr/local/bin/codex && \
    rm -f /tmp/claude /tmp/codex.tgz "/tmp/codex-${CODEX_ARCH}" && \
    curl -fsSL https://opencode.ai/install | bash && \
    sudo install -m 0755 "$HOME/.opencode/bin/opencode" /usr/local/bin/opencode

RUN sudo python -m pip install --no-cache-dir --upgrade pip && \
    sudo python -m pip install --no-cache-dir -r /tmp/requirements.txt && \
    python -m ipykernel install --user --name agentcon-workshop --display-name "Python (agentcon-workshop)" && \
    python - <<'PY'
import pathlib
import shutil
import json
from pathlib import Path

kernel_json = Path('/home/coder/.local/share/jupyter/kernels/agentcon-workshop/kernel.json')
data = json.loads(kernel_json.read_text())
data['argv'][0] = '/usr/local/bin/python'
data['env'] = {'PYTHONPATH': '/home/coder/workspace'}
kernel_json.write_text(json.dumps(data, indent=1) + '\n')
PY

COPY --chown=coder:coder src /home/coder/workspace

COPY --chown=coder:coder opentofu/manifests/home/.zshrc /home/coder/.zshrc
COPY --chown=coder:coder opentofu/manifests/home/vscode-user-settings.json /home/coder/.vscode-data/User/settings.json

WORKDIR /home/coder/workspace

EXPOSE 8000

CMD ["vscode", "serve-web", "--host=0.0.0.0", "--port=8000", "--without-connection-token", "--accept-server-license-terms", "--server-data-dir", "/home/coder/.vscode-data", "--default-folder", "/home/coder/workspace"]
