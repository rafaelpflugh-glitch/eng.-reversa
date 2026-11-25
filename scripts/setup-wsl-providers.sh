#!/usr/bin/env bash
set -euo pipefail

INSTALL_GHIDRA=false
INSTALL_BINWALK=false
INSTALL_UNBLOB=false
INSTALL_NATIVE_TOOLS=false
INSTALL_JS=false
INSTALL_ANDROID=false
INSTALL_NETWORK=false
INSTALL_WASM=false
INSTALL_SIGNALS=false
INSTALL_FRIDA=false

usage() {
  cat <<'EOF'
Uso: ./scripts/setup-wsl-providers.sh [OPCOES...]

Opcoes:
  --ghidra        OpenJDK 25 + Ghidra 12.2 + diretorio de checkpoints
  --binwalk       Rust/Cargo + Binwalk 3.1.0 (inspecao de regioes de firmware)
  --unblob        Extratores + uv + Unblob 26.6.4 (extracao de firmwares)
  --native-tools  GDB + GNU objdump + Rizin 0.9.1 + pwntools 4.15.0
  --js            Wakaru 1.14.0 (desempacotar/desminificar bundles JS)
  --android       JADX Headless MCP 0.7.1 + Apktool + ADB
  --network       TShark 4.x + capinfos + mitmproxy
  --wasm          WABT 1.0.42 (wasm-validate, wasm-objdump, wasm2wat)
  --signals       sigrok-cli 0.7.2 (decodificacao de sinais logicos)
  --frida         Habilita scripts nativos do Frida no rea-agents
  --all           Instala TODOS os provedores acima
  -h, --help      Mostra esta ajuda
EOF
}

if [ "$#" -eq 0 ]; then
  usage
  exit 1
fi

for arg in "$@"; do
  case "$arg" in
    --ghidra)       INSTALL_GHIDRA=true ;;
    --binwalk)      INSTALL_BINWALK=true ;;
    --unblob)       INSTALL_UNBLOB=true ;;
    --native-tools) INSTALL_NATIVE_TOOLS=true ;;
    --js)           INSTALL_JS=true ;;
    --android)      INSTALL_ANDROID=true ;;
    --network)      INSTALL_NETWORK=true ;;
    --wasm)         INSTALL_WASM=true ;;
    --signals)      INSTALL_SIGNALS=true ;;
    --frida)        INSTALL_FRIDA=true ;;
    --all)
      INSTALL_GHIDRA=true
      INSTALL_BINWALK=true
      INSTALL_UNBLOB=true
      INSTALL_NATIVE_TOOLS=true
      INSTALL_JS=true
      INSTALL_ANDROID=true
      INSTALL_NETWORK=true
      INSTALL_WASM=true
      INSTALL_SIGNALS=true
      INSTALL_FRIDA=true
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

ENV_FILE="$HOME/.rea-env.sh"
mkdir -p "$HOME/tools" "$HOME/.local/bin"
touch "$ENV_FILE" "$HOME/.bashrc"

SOURCE_LINE='[ -f "$HOME/.rea-env.sh" ] && . "$HOME/.rea-env.sh"'
if ! grep -Fqx "$SOURCE_LINE" "$HOME/.bashrc"; then
  printf '\n%s\n' "$SOURCE_LINE" >> "$HOME/.bashrc"
fi

set_env_line() {
  local line="$1"
  if ! grep -Fqx "$line" "$ENV_FILE"; then
    printf '%s\n' "$line" >> "$ENV_FILE"
  fi
}

ensure_uv() {
  if ! command -v uv >/dev/null 2>&1 && [ ! -x "$HOME/.local/bin/uv" ]; then
    curl -LsSf https://astral.sh/uv/install.sh | sh
  fi
  set_env_line 'export PATH="$HOME/.local/bin:$PATH"'
  export PATH="$HOME/.local/bin:$PATH"
}

verify_sha256() {
  local file="$1"
  local expected="$2"
  echo "${expected}  ${file}" | sha256sum -c -
}

sudo apt update

# --- 1. GHIDRA 12.2 + JDK 25 + CHECKPOINTS ---
if [ "$INSTALL_GHIDRA" = true ]; then
  echo "==> [ghidra] Instalando OpenJDK 25 e Ghidra 12.2..."
  sudo apt install -y openjdk-25-jdk unzip curl

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

  mkdir -p "$HOME/.cache/rea/ghidra-checkpoints"
  set_env_line 'export JAVA_HOME=/usr/lib/jvm/java-25-openjdk-amd64'
  set_env_line 'export GHIDRA_INSTALL_DIR="$HOME/tools/ghidra_12.2_PUBLIC"'
  set_env_line 'export REA_GHIDRA_CHECKPOINT_DIR="$HOME/.cache/rea/ghidra-checkpoints"'
  export JAVA_HOME=/usr/lib/jvm/java-25-openjdk-amd64
  export GHIDRA_INSTALL_DIR="$HOME/tools/ghidra_12.2_PUBLIC"
  export REA_GHIDRA_CHECKPOINT_DIR="$HOME/.cache/rea/ghidra-checkpoints"
fi

# --- 2. BINWALK 3.1.0 ---
if [ "$INSTALL_BINWALK" = true ]; then
  echo "==> [binwalk] Instalando Binwalk 3.1.0 (via Rust/Cargo)..."
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

  set_env_line 'export PATH="$HOME/.cargo/bin:$PATH"'
  set_env_line 'export REA_BINWALK_COMMAND="$HOME/.cargo/bin/binwalk"'
  export REA_BINWALK_COMMAND="$HOME/.cargo/bin/binwalk"
  "$REA_BINWALK_COMMAND" --version
fi

# --- 3. UNBLOB 26.6.4 ---
if [ "$INSTALL_UNBLOB" = true ]; then
  echo "==> [unblob] Instalando Unblob 26.6.4 e extratores de sistema..."
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

  ensure_uv
  if [ -x "$HOME/.local/bin/unblob" ] && [ "$("$HOME/.local/bin/unblob" --version 2>/dev/null || true)" = "26.6.4" ]; then
    echo "    Unblob 26.6.4 ja esta instalado em $HOME/.local/bin/unblob"
  else
    uv tool install unblob==26.6.4
  fi

  set_env_line 'export REA_UNBLOB_COMMAND="$HOME/.local/bin/unblob"'
  export REA_UNBLOB_COMMAND="$HOME/.local/bin/unblob"
  "$REA_UNBLOB_COMMAND" --version
  "$REA_UNBLOB_COMMAND" --show-external-dependencies || true
fi

# --- 4. NATIVE TOOLS: GDB + OBJDUMP + RIZIN + PWNTOOLS ---
if [ "$INSTALL_NATIVE_TOOLS" = true ]; then
  echo "==> [native-tools] Instalando GDB, binutils (objdump), Rizin 0.9.1 e pwntools 4.15.0..."
  sudo apt install -y gdb binutils xz-utils curl

  set_env_line 'export REA_GDB_COMMAND=/usr/bin/gdb'
  set_env_line 'export REA_OBJDUMP_COMMAND=/usr/bin/objdump'

  RIZIN_DIR="$HOME/tools/rizin-0.9.1"
  if [ ! -x "$RIZIN_DIR/bin/rizin" ]; then
    mkdir -p "$RIZIN_DIR"
    RIZIN_TAR="$HOME/tools/rizin-v0.9.1-static-x86_64.tar.xz"
    curl -fL -o "$RIZIN_TAR" \
      "https://github.com/rizinorg/rizin/releases/download/v0.9.1/rizin-v0.9.1-static-x86_64.tar.xz"
    tar -xJf "$RIZIN_TAR" -C "$RIZIN_DIR"
    rm -f "$RIZIN_TAR"
  else
    echo "    Rizin ja encontrado em $RIZIN_DIR/bin/rizin"
  fi
  set_env_line 'export REA_RIZIN_COMMAND="$HOME/tools/rizin-0.9.1/bin/rizin"'
  "$RIZIN_DIR/bin/rizin" -v | head -n 1

  ensure_uv
  PWN_VENV="$HOME/tools/pwntools-venv"
  if [ ! -x "$PWN_VENV/bin/python" ] || ! "$PWN_VENV/bin/python" -c "import pwn; assert pwn.__version__ == '4.15.0'" 2>/dev/null; then
    uv venv "$PWN_VENV"
    uv pip install --python "$PWN_VENV/bin/python" pwntools==4.15.0
  else
    echo "    pwntools 4.15.0 ja instalado em $PWN_VENV"
  fi
  set_env_line 'export REA_PWNTOOLS_PYTHON="$HOME/tools/pwntools-venv/bin/python"'
fi

# --- 5. WAKARU 1.14.0 (JS RECOVERY) ---
if [ "$INSTALL_JS" = true ]; then
  echo "==> [js] Instalando Wakaru 1.14.0..."
  WAKARU_DIR="$HOME/tools/wakaru-1.14.0"
  WAKARU_BIN="$WAKARU_DIR/wakaru"
  WAKARU_SHA256="664fa06782a61eda7ed15885134b52525fd565dd77607e642062ceb6cd927c38"
  if [ ! -x "$WAKARU_BIN" ]; then
    mkdir -p "$WAKARU_DIR"
    curl -fL "https://github.com/pionxzh/wakaru/releases/download/v1.14.0/wakaru-linux-x64.tar.gz" \
      | tar -xz -C "$WAKARU_DIR" wakaru
    verify_sha256 "$WAKARU_BIN" "$WAKARU_SHA256"
  else
    echo "    Wakaru 1.14.0 ja encontrado em $WAKARU_BIN"
  fi
  set_env_line 'export REA_WAKARU_COMMAND="$HOME/tools/wakaru-1.14.0/wakaru"'
  "$WAKARU_BIN" --version
fi

# --- 6. ANDROID: JADX HEADLESS MCP 0.7.1 + APKTOOL + ADB ---
if [ "$INSTALL_ANDROID" = true ]; then
  echo "==> [android] Instalando JADX Headless MCP 0.7.1, Apktool e ADB..."
  sudo apt install -y openjdk-25-jdk apktool adb curl

  JADX_DIR="$HOME/tools/jadx-headless-mcp"
  JADX_JAR="$JADX_DIR/jadx-headless-mcp-0.7.1-all.jar"
  JADX_SHA256="6e5eacf500b64292bfb73c49797c1958f6ee44646e43e868039ae7feb573ff75"
  if [ ! -f "$JADX_JAR" ]; then
    mkdir -p "$JADX_DIR"
    curl -fL -o "$JADX_JAR" \
      "https://github.com/1013503897/jadx-headless-mcp/releases/download/v0.7.1/jadx-headless-mcp-0.7.1-all.jar"
    verify_sha256 "$JADX_JAR" "$JADX_SHA256"
  else
    echo "    JADX Headless MCP 0.7.1 ja encontrado em $JADX_JAR"
  fi

  set_env_line 'export JAVA_HOME=/usr/lib/jvm/java-25-openjdk-amd64'
  set_env_line 'export REA_JADX_MCP_JAR="$HOME/tools/jadx-headless-mcp/jadx-headless-mcp-0.7.1-all.jar"'
  set_env_line 'export REA_APKTOOL_COMMAND=/usr/bin/apktool'
  set_env_line 'export REA_ADB_PATH=/usr/bin/adb'
fi

# --- 7. NETWORK: TSHARK 4.x + CAPINFOS + MITMPROXY ---
if [ "$INSTALL_NETWORK" = true ]; then
  echo "==> [network] Instalando TShark 4.x, capinfos e mitmproxy..."
  sudo DEBIAN_FRONTEND=noninteractive apt install -y tshark wireshark-common mitmproxy
  set_env_line 'export REA_TSHARK_COMMAND=/usr/bin/tshark'
  tshark --version | head -n 1
fi

# --- 8. WASM: WABT 1.0.42 ---
if [ "$INSTALL_WASM" = true ]; then
  echo "==> [wasm] Instalando WABT 1.0.42..."
  WABT_BIN_DIR="$HOME/tools/wabt-1.0.42/bin"
  if [ ! -x "$WABT_BIN_DIR/wasm2wat" ]; then
    WABT_TAR="$HOME/tools/wabt-1.0.42-linux-x64.tar.gz"
    curl -fL -o "$WABT_TAR" \
      "https://github.com/WebAssembly/wabt/releases/download/1.0.42/wabt-1.0.42-linux-x64.tar.gz"
    tar -xzf "$WABT_TAR" -C "$HOME/tools"
    rm -f "$WABT_TAR"
  else
    echo "    WABT 1.0.42 ja encontrado em $WABT_BIN_DIR"
  fi
  set_env_line 'export REA_WABT_BIN_DIRECTORY="$HOME/tools/wabt-1.0.42/bin"'
  "$WABT_BIN_DIR/wasm2wat" --version
fi

# --- 9. SIGNALS: SIGROK-CLI 0.7.2 ---
if [ "$INSTALL_SIGNALS" = true ]; then
  echo "==> [signals] Instalando sigrok-cli 0.7.2..."
  sudo apt install -y sigrok-cli
  set_env_line 'export REA_SIGROK_COMMAND=/usr/bin/sigrok-cli'
  sigrok-cli --version | head -n 1
fi

# --- 10. FRIDA ---
if [ "$INSTALL_FRIDA" = true ]; then
  echo "==> [frida] Habilitando scripts nativos do Frida no rea-agents..."
  export NVM_DIR="$HOME/.nvm"
  # shellcheck source=/dev/null
  [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
  npm install --global --allow-scripts=frida rea-agents
fi

echo ""
echo "Provedores instalados e configurados em $ENV_FILE!"
echo "Rode 'source ~/.bashrc' e valide com:"
echo "  rea doctor --provider ghidra"
echo "  rea doctor --provider jadx"
echo "  rea providers"
