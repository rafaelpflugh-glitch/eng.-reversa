#!/usr/bin/env bash
set -euo pipefail

echo "==> Atualizando pacotes do Ubuntu e instalando pre-requisitos..."
sudo apt update && sudo apt upgrade -y
sudo apt install -y curl git build-essential procps unzip

echo "==> Instalando nvm e Node.js 24 LTS..."
if [ ! -d "$HOME/.nvm" ]; then
  curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash
fi

export NVM_DIR="$HOME/.nvm"
# shellcheck source=/dev/null
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"

nvm install 24
nvm alias default 24

echo "    Node ativo: $(node -v)"
echo "    npm ativo:  $(npm -v)"

echo "==> Instalando rea-agents globalmente no WSL..."
npm install --global rea-agents

echo "==> Verificando instalacao do REA..."
rea --version
which ps
which prlimit

echo ""
echo "Setup base do WSL concluido! Rode 'source ~/.bashrc' ou reabra o terminal."
