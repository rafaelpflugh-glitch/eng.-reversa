# REA Setup Kit (Windows + WSL Ubuntu 24.04)

Guia prático e scripts automatizados para instalar, configurar e usar o **[REA (Reverse Engineer Anything)](https://github.com/morluto/rea)** no **Windows** (conectado ao **Antigravity** e outros agentes via MCP) e no **WSL 2 (Ubuntu 24.04)** com provedores avançados (**Ghidra 12.2 + JDK 25**, **Binwalk 3.1.0** e **Unblob 26.6.4**).

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

O `setup-all.ps1` cuida de tudo em sequência (e pode ser rodado novamente sem problema caso o Windows peça para reiniciar após instalar o Node.js ou o WSL):
1. Verifica/instala **Node.js** suportado, instala `rea-agents` globalmente e configura o MCP no **Antigravity**.
2. Verifica/instala o **WSL 2 + Ubuntu 24.04** e define como padrão.
3. Dentro do Ubuntu 24.04, instala **Node 24**, **REA**, **Ghidra 12.2 + JDK 25**, **Binwalk 3.1.0** e **Unblob 26.6.4**.

Opções úteis do `setup-all.ps1`:
```powershell
.\setup-all.ps1 -Client antigravity -Providers all   # padrão (tudo)
.\setup-all.ps1 -Providers ghidra                    # apenas Ghidra no WSL
.\setup-all.ps1 -SkipWsl                             # apenas Windows + Antigravity
```

Depois de finalizar, **reinicie o Antigravity** para ativar o servidor MCP `rea`.

---

## Estrutura do repositório

- [`setup-all.ps1`](setup-all.ps1) — Instalador único (Windows + WSL + todos os provedores).
- [`scripts/setup-windows.ps1`](scripts/setup-windows.ps1) — Instala `rea-agents` no Windows, registra o MCP no cliente escolhido (padrão: `antigravity`) e roda `rea doctor`.
- [`scripts/setup-wsl-base.sh`](scripts/setup-wsl-base.sh) — Prepara o Ubuntu 24.04 no WSL 2 (`procps`, Node.js 24 via `nvm` e `rea-agents`).
- [`scripts/setup-wsl-providers.sh`](scripts/setup-wsl-providers.sh) — Instala e configura de forma modular **Ghidra 12.2 + JDK 25**, **Binwalk 3.1.0** e **Unblob 26.6.4** no Ubuntu 24.04.
- [`docs/cheatsheet.md`](docs/cheatsheet.md) — Guia rápido de comandos CLI e exemplos de prompts para usar no Antigravity.

---

## 1. Setup no Windows (CLI + MCP no Antigravity)

### Pré-requisitos
- **Node.js** `22.23.4+`, `24.22.1+` ou `26.12.1+`
- PowerShell com permissão para scripts locais:
  ```powershell
  Set-ExecutionPolicy -Scope CurrentUser RemoteSigned
  ```

### Execução
```powershell
.\scripts\setup-windows.ps1 -Client antigravity
```

Depois de aprovar o plano do `rea setup`, **reinicie o Antigravity** para carregar o servidor MCP `rea` e a skill `reverse-engineer-anything`.

*(Se o `rea doctor` acusar uma entrada manual antiga como `foreign` em `~/.gemini/config/mcp_config.json`, remova a entrada `"rea"` antiga e rode `rea setup --client antigravity` novamente.)*

---

## 2. Setup do WSL 2 (Ubuntu 24.04)

No PowerShell (como Administrador), instale o Ubuntu 24.04 e defina como padrão:

```powershell
wsl --update
wsl --set-default-version 2
wsl --install -d Ubuntu-24.04
wsl --set-default Ubuntu-24.04
```

Depois, dentro do terminal do **Ubuntu 24.04**, instale a base (Node 24 + `procps` + REA):

```bash
chmod +x scripts/setup-wsl-base.sh scripts/setup-wsl-providers.sh
./scripts/setup-wsl-base.sh
```

---

## 3. Provedores avançados no Ubuntu 24.04 (WSL)

Você pode instalar tudo de uma vez ou escolher apenas os provedores desejados:

```bash
# Instalar todos (Ghidra 12.2 + JDK 25, Binwalk 3.1.0 e Unblob 26.6.4)
./scripts/setup-wsl-providers.sh --all

# Ou individualmente:
./scripts/setup-wsl-providers.sh --ghidra
./scripts/setup-wsl-providers.sh --binwalk
./scripts/setup-wsl-providers.sh --unblob
```

Após concluir, recarregue o shell e valide:

```bash
source ~/.bashrc
rea doctor --provider ghidra
rea providers
```

| Provedor | Versão verificada pelo REA | Uso principal |
| --- | --- | --- |
| **Ghidra + JDK** | Ghidra `12.2` + OpenJDK `25` | Decompilação e análise de binários nativos (ELF, PE, ARM, MIPS, x86/x64) |
| **Binwalk** | `3.1.0` (`REA_BINWALK_COMMAND`) | Inspeção de regiões em imagens de firmware (`rea inspect-firmware-regions`) |
| **Unblob** | `26.6.4` (`REA_UNBLOB_COMMAND`) | Extração de contêineres e firmwares (`rea extract-firmware`) |

---

## 4. Como usar no dia a dia

Veja o guia de bolso completo em [`docs/cheatsheet.md`](docs/cheatsheet.md).

- **No Antigravity:** basta pedir em português apontando o caminho local do alvo, ex.:
  > *"Use o REA para inspecionar `C:\caminho\do\app`, identificar a stack e listar os arquivos principais com evidências."*
- **Na CLI:**
  ```powershell
  rea doctor --client antigravity
  rea inspect-artifact "C:\caminho\arquivo"
  rea analyze-javascript-application "C:\caminho\app" --json > app-evidence.json
  ```

---

## Uso responsável e créditos

Este repositório reúne apenas scripts de ambiente e documentação pessoal. O REA é um projeto open-source mantido em [morluto/rea](https://github.com/morluto/rea) sob licença MIT. Use estas ferramentas apenas para pesquisa legítima, educação, interoperabilidade, auditoria defensiva e análise de software próprio ou autorizado.
