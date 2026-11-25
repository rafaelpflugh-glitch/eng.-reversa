#!/usr/bin/env bash
set -euo pipefail

WITH_FRIDA=false
for arg in "$@"; do
  case "$arg" in
    --with-frida) WITH_FRIDA=true ;;
    *) ;;
  esac
done

echo "==> Atualizando pacotes do Ubuntu e instalando pre-requisitos..."
sudo apt update && sudo apt upgrade -y
sudo apt install -y curl git build-essential procps unzip xz-utils

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
if [ "$WITH_FRIDA" = true ]; then
  npm install --global --allow-scripts=frida rea-agents
else
  npm install --global rea-agents
fi

echo "==> Criando ~/.rea-env.sh e launcher ~/.local/bin/rea-wsl-mcp..."
mkdir -p "$HOME/.local/bin"
touch "$HOME/.rea-env.sh"

SOURCE_LINE='[ -f "$HOME/.rea-env.sh" ] && . "$HOME/.rea-env.sh"'
touch "$HOME/.bashrc"
if ! grep -Fqx "$SOURCE_LINE" "$HOME/.bashrc"; then
  printf '\n%s\n' "$SOURCE_LINE" >> "$HOME/.bashrc"
fi

cat <<'EOF' > "$HOME/.local/bin/rea-wsl-mcp"
#!/usr/bin/env bash
set -euo pipefail
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
export PATH="$HOME/.local/bin:$HOME/.cargo/bin:$PATH"
[ -f "$HOME/.rea-env.sh" ] && . "$HOME/.rea-env.sh"
exec rea mcp
EOF
chmod +x "$HOME/.local/bin/rea-wsl-mcp"

echo "==> Verificando instalacao do REA..."
rea --version
which ps
which prlimit

echo ""
echo "Setup base do WSL concluido! Rode 'source ~/.bashrc' ou reabra o terminal."
