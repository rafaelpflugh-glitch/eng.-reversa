# REA Setup Kit (Windows + WSL Ubuntu 24.04)

Guia prático e scripts automatizados para instalar, configurar e usar o **[REA (Reverse Engineer Anything)](https://github.com/morluto/rea)** no **Windows** (conectado ao **Antigravity** e outros agentes via MCP) e no **WSL 2 (Ubuntu 24.04)** com a suíte completa de provedores Linux — incluindo ponte MCP direta **`rea-wsl`** para o Antigravity no Windows.

> **Sobre o REA:** o REA não tem uma janela gráfica própria. Ele é uma caixa de ferramentas de engenharia reversa (CLI + servidor **MCP**) usada pelo terminal ou diretamente dentro de agentes de IA (como Antigravity, Claude Code, Codex, Cursor e VS Code).

---

## Instalação rápida em um PC novo (1 comando)

Abra o **PowerShell** e rode:

```powershell
git clone https://github.com/rafaelpflugh-glitch/eng.-reversa.git
cd eng.-reversa
Set-ExecutionPolicy -Scope CurrentUser RemoteSigned
.\setup-all.ps1
```

O `setup-all.ps1` faz tudo em sequência (e é **idempotente** — se o Windows pedir reinicialização após instalar o Node.js ou o WSL, basta rodar `.\setup-all.ps1` novamente):

1. Verifica/instala **Node.js**, instala `rea-agents` (+ suporte a **Frida**) no Windows e configura o MCP `rea` no **Antigravity**.
2. Verifica/instala o **WSL 2 + Ubuntu 24.04** e define como padrão.
3. Dentro do Ubuntu 24.04, instala **Node 24**, **REA** e **todos os provedores** (`~/.rea-env.sh` + launcher `~/.local/bin/rea-wsl-mcp`).
4. Registra o segundo servidor MCP **`rea-wsl`** no Antigravity (`~/.gemini/config/mcp_config.json`), permitindo acionar Ghidra Linux, Binwalk, Unblob, Rizin, GDB, Wakaru, JADX, TShark, WABT e sigrok-cli direto do chat no Windows.

Opções úteis do `setup-all.ps1`:
```powershell
.\setup-all.ps1                                       # instala tudo (padrão)
.\setup-all.ps1 -Providers ghidra,binwalk,unblob      # escolhe só alguns provedores no WSL
.\setup-all.ps1 -NoFrida                              # pula os scripts nativos do Frida
.\setup-all.ps1 -SkipWsl                              # apenas Windows + Antigravity
.\setup-all.ps1 -SkipWslMcp                           # não registra o servidor rea-wsl no Antigravity
```

Depois de finalizar, **reinicie o Antigravity** para ativar os servidores MCP `rea` e `rea-wsl`.

---

## Suíte de provedores incluída (`scripts/setup-wsl-providers.sh`)

Todas as variáveis de ambiente ficam centralizadas em `~/.rea-env.sh` (carregado automaticamente pelo `~/.bashrc` e pelo servidor MCP `rea-wsl`).

| Flag | Ferramentas & versões | O que desbloqueia no REA |
| --- | --- | --- |
| `--ghidra` | **Ghidra 12.2** + **OpenJDK 25** + **Checkpoints** (`REA_GHIDRA_CHECKPOINT_DIR`) | Decompilação de binários nativos (ELF, PE, ARM, MIPS, x86/x64) com cache persistente de análise |
| `--binwalk` | **Binwalk 3.1.0** (`REA_BINWALK_COMMAND`) | Inspeção de regiões em imagens de firmware (`inspect_firmware_regions`) |
| `--unblob` | **Unblob 26.6.4** (`REA_UNBLOB_COMMAND`) + extratores | Extração de contêineres e firmwares (`extract_firmware`) |
| `--native-tools` | **GDB**, GNU **`objdump`**, **Rizin 0.9.1**, **`pwntools` 4.15.0** | Disassembly rápido, sessões de debug persistentes, layout ELF e análise de crash/core dumps |
| `--js` | **Wakaru 1.14.0** *(SHA-256 verificado)* | Recuperação/desminificação de bundles JavaScript (`recover_javascript_sources`) |
| `--android` | **JADX Headless MCP 0.7.1** *(SHA-256 verificado)* + **Apktool** + **ADB** | Decompilação de classes/métodos de APKs, recursos/manifesto e inspeção de dispositivos |
| `--network` | **TShark 4.x** + **`capinfos`** + **`mitmproxy`** | Análise de `.pcap`/`.pcapng`, DNS, TLS SNI e comparação com endpoints estáticos |
| `--wasm` | **WABT 1.0.42** (`REA_WABT_BIN_DIRECTORY`) | Validação e decodificação de módulos `.wasm` para WAT (`inspect_wasm_artifact`) |
| `--signals` | **`sigrok-cli` 0.7.2** (`REA_SIGROK_COMMAND`) | Decodificação de capturas de analisador lógico (SPI, I2C, UART etc.) |
| `--frida` | **Frida** (`--allow-scripts=frida`) | Instrumentação dinâmica em processos em execução (`instrument_with_frida`) |
| `--all` | Todos os itens acima | Suíte completa |

---

## Estrutura do repositório

- [`setup-all.ps1`](setup-all.ps1) — Instalador único (Windows + WSL + todos os provedores + `rea-wsl` MCP).
- [`scripts/setup-windows.ps1`](scripts/setup-windows.ps1) — Instala `rea-agents` no Windows, registra o MCP no cliente escolhido e roda `rea doctor`.
- [`scripts/register-wsl-mcp.ps1`](scripts/register-wsl-mcp.ps1) — Adiciona/atualiza o servidor MCP `rea-wsl` em `~/.gemini/config/mcp_config.json`.
- [`scripts/setup-wsl-base.sh`](scripts/setup-wsl-base.sh) — Prepara o Ubuntu 24.04 (`procps`, `nvm` + Node 24, `rea-agents`, `~/.rea-env.sh` e `~/.local/bin/rea-wsl-mcp`).
- [`scripts/setup-wsl-providers.sh`](scripts/setup-wsl-providers.sh) — Instala e configura de forma modular os provedores avançados no Ubuntu 24.04.
- [`docs/cheatsheet.md`](docs/cheatsheet.md) — Guia rápido de comandos CLI e exemplos de prompts para usar no Antigravity.

---

## Como usar no dia a dia

Veja o guia de bolso completo em [`docs/cheatsheet.md`](docs/cheatsheet.md).

- **No Antigravity (via `rea` ou `rea-wsl`):**
  > *"Use o REA (`rea-wsl`) para inspecionar `/home/pflug/analises/alvo` e me mostrar as evidências."*
- **Validação rápida no Ubuntu (WSL):**
  ```bash
  source ~/.bashrc
  rea doctor --provider ghidra
  rea doctor --provider jadx
  rea providers
  ```

---

## Uso responsável e créditos

Este repositório reúne apenas scripts de ambiente e documentação pessoal. O REA é um projeto open-source mantido em [morluto/rea](https://github.com/morluto/rea) sob licença MIT. Use estas ferramentas apenas para pesquisa legítima, educação, interoperabilidade, auditoria defensiva e análise de software próprio ou autorizado.
