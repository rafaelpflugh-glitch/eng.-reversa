#!/usr/bin/env bash
set -euo pipefail

INSTALL_GHIDRA=false
INSTALL_BINWALK=false
INSTALL_UNBLOB=false

usage() {
  cat <<'EOF'
Uso: ./scripts/setup-wsl-providers.sh [--ghidra] [--binwalk] [--unblob] [--all]

Opcoes:
  --ghidra   Instala OpenJDK 25 + Ghidra 12.2 e configura JAVA_HOME e GHIDRA_INSTALL_DIR
  --binwalk  Instala Rust/Cargo + Binwalk 3.1.0 e configura REA_BINWALK_COMMAND
  --unblob   Instala extratores + uv + Unblob 26.6.4 e configura REA_UNBLOB_COMMAND
  --all      Instala todos os provedores acima
  -h, --help Mostra esta ajuda
EOF
}

if [ "$#" -eq 0 ]; then
  usage
  exit 1
fi

for arg in "$@"; do
  case "$arg" in
    --ghidra)  INSTALL_GHIDRA=true ;;
    --binwalk) INSTALL_BINWALK=true ;;
    --unblob)  INSTALL_UNBLOB=true ;;
    --all)
      INSTALL_GHIDRA=true
      INSTALL_BINWALK=true
      INSTALL_UNBLOB=true
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Opcao desconhecida: $arg" >&2
      usage
      exit 1
      ;;
  esac
done

append_line_once() {
  local line="$1"
  local file="$HOME/.bashrc"
  touch "$file"
  if ! grep -Fqx "$line" "$file"; then
    printf '\n%s\n' "$line" >> "$file"
  fi
}

sudo apt update

if [ "$INSTALL_GHIDRA" = true ]; then
  echo "==> Instalando OpenJDK 25 e Ghidra 12.2..."
  sudo apt install -y openjdk-25-jdk unzip curl

  mkdir -p "$HOME/tools"
  GHIDRA_DIR="$HOME/tools/ghidra_12.2_PUBLIC"
  if [ ! -d "$GHIDRA_DIR" ]; then
    GHIDRA_ZIP="$HOME/tools/ghidra_12.2_PUBLIC_20261016.zip"
    curl -fL -o "$GHIDRA_ZIP" \
      "https://github.com/NationalSecurityAgency/ghidra/releases/download/Ghidra_12.2_build/ghidra_12.2_PUBLIC_20261016.zip"
    unzip -q "$GHIDRA_ZIP" -d "$HOME/tools"
    rm -f "$GHIDRA_ZIP"
  else
    echo "    Ghidra ja encontrado em $GHIDRA_DIR"
  fi

  append_line_once 'export JAVA_HOME=/usr/lib/jvm/java-25-openjdk-amd64'
  append_line_once 'export GHIDRA_INSTALL_DIR="$HOME/tools/ghidra_12.2_PUBLIC"'
  export JAVA_HOME=/usr/lib/jvm/java-25-openjdk-amd64
  export GHIDRA_INSTALL_DIR="$HOME/tools/ghidra_12.2_PUBLIC"
fi

if [ "$INSTALL_BINWALK" = true ]; then
  echo "==> Instalando Binwalk 3.1.0 (via Rust/Cargo)..."
  if [ -x "$HOME/.cargo/bin/binwalk" ] && "$HOME/.cargo/bin/binwalk" --version 2>/dev/null | grep -Fq "binwalk 3.1.0"; then
    echo "    Binwalk 3.1.0 ja esta instalado em $HOME/.cargo/bin/binwalk"
  else
    sudo apt install -y build-essential pkg-config libfontconfig1-dev liblzma-dev curl

    if [ ! -f "$HOME/.cargo/env" ]; then
      curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    fi
    # shellcheck source=/dev/null
    . "$HOME/.cargo/env"

    cargo install binwalk@3.1.0
  fi

  append_line_once 'export REA_BINWALK_COMMAND="$HOME/.cargo/bin/binwalk"'
  export REA_BINWALK_COMMAND="$HOME/.cargo/bin/binwalk"
  "$REA_BINWALK_COMMAND" --version
fi

if [ "$INSTALL_UNBLOB" = true ]; then
  echo "==> Instalando Unblob 26.6.4 (via uv) e extratores de sistema..."
  sudo apt install -y \
    android-sdk-libsparse-utils \
    e2fsprogs \
    p7zip-full \
    unar \
    lzop \
    lziprecover \
    zstd \
    lz4 \
    liblzo2-dev \
    libhyperscan-dev \
    curl

  if ! command -v uv >/dev/null 2>&1 && [ ! -x "$HOME/.local/bin/uv" ]; then
    curl -LsSf https://astral.sh/uv/install.sh | sh
  fi

  append_line_once 'export PATH="$HOME/.local/bin:$PATH"'
  export PATH="$HOME/.local/bin:$PATH"

  if [ -x "$HOME/.local/bin/unblob" ] && [ "$("$HOME/.local/bin/unblob" --version 2>/dev/null || true)" = "26.6.4" ]; then
    echo "    Unblob 26.6.4 ja esta instalado em $HOME/.local/bin/unblob"
  else
    uv tool install unblob==26.6.4
  fi

  append_line_once 'export REA_UNBLOB_COMMAND="$HOME/.local/bin/unblob"'
  export REA_UNBLOB_COMMAND="$HOME/.local/bin/unblob"
  "$REA_UNBLOB_COMMAND" --version
  "$REA_UNBLOB_COMMAND" --show-external-dependencies || true
fi

echo ""
echo "Provedores instalados! Rode 'source ~/.bashrc' e valide com:"
echo "  rea doctor --provider ghidra"
echo "  rea providers"
