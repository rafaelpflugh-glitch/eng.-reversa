# REA — Guia de Bolso (CLI & Agentes MCP)

## 1. Diagnóstico e manutenção

```bash
# Verificar saúde geral do ambiente
rea doctor

# Verificar apenas um cliente MCP (ex.: Antigravity)
rea doctor --client antigravity

# Verificar provedores específicos (no WSL)
rea doctor --provider ghidra
rea doctor --provider jadx

# Listar provedores disponíveis e capacidades
rea providers
rea capabilities

# Listar fluxos guiados embutidos no REA
rea guided-workflows
rea guidance

# Atualizar ou remover o REA
rea update
rea uninstall
```

---

## 2. Comandos mais usados na CLI

### Triagem inicial de qualquer arquivo ou pasta
```bash
rea inspect-artifact /caminho/do/arquivo
rea inspect-desktop-application /caminho/da/pasta
rea audit-release-exposure /caminho/do/alvo
```

### Apps JavaScript / Electron (pasta extraída, `.asar` ou bundles)
```bash
# Recuperar fontes legíveis de um bundle minificado (Wakaru — WSL)
rea recover-javascript-sources /caminho/bundle.js /caminho/saida-recuperada --json

# Salvar o grafo completo de evidências em JSON
rea analyze-javascript-application /caminho/do/app --json > app-evidence.json

# Projetar apenas o resumo (ideal para apps grandes)
echo '{"source":{"kind":"evidence-file","path":"app-evidence.json"},"view":{"kind":"summary"}}' | rea inspect-analysis-view -
```

### Assemblies .NET (C# / VB.NET)
```bash
rea inspect-managed-artifact /caminho/Assembly.dll --json
rea inspect-managed-members /caminho/Assembly.dll --json
```

### Executáveis Windows (PE) sem precisar de Ghidra
```bash
rea inspect-pe-imports /caminho/app.exe
rea inspect-pe-certificates /caminho/app.exe
rea inspect-binary-hardening /caminho/app.exe
rea inspect-pe-resources /caminho/app.exe
```

### Binários nativos (Ghidra, Rizin, objdump, pwntools — WSL)
```bash
# Ghidra (com checkpoints ativos em REA_GHIDRA_CHECKPOINT_DIR, reconsultas são rápidas)
rea inspect /caminho/binario --provider ghidra --format json
rea search "padrao" /caminho/binario --provider ghidra
rea function 0x401000 /caminho/binario --provider ghidra
rea decompile 0x401000 /caminho/binario --provider ghidra

# Disassembly rápido sem abrir o Ghidra
rea inspect-with-objdump /caminho/binario disassemble
rea execute-rizin-command /caminho/binario "afl"

# Layout ELF e análise de core dump (pwntools)
rea inspect-binary-layout /caminho/binario
```

### Imagens de firmware (WSL / Linux)
```bash
# Entropia (funciona também no Windows)
rea inspect-byte-entropy /caminho/firmware.bin

# Regiões com Binwalk 3.1.x (WSL)
rea inspect-firmware-regions /caminho/firmware.bin

# Extração com Unblob 26.6.x (WSL — diretório de saída não deve existir)
rea extract-firmware /caminho/firmware.bin /caminho/saida-nova

# UEFI / NVRAM (embutido, funciona no Windows e Linux)
rea inspect-uefi-firmware /caminho/flash.bin --json
rea inspect-uefi-nvram /caminho/flash.bin --json
```

### Android (JADX, Apktool, ADB — WSL)
```bash
rea inspect-apk-signature /caminho/app.apk
rea inspect-android-package /caminho/app.apk
rea search-android-classes /caminho/app.apk "Main"
rea decode-android-resources /caminho/app.apk /caminho/saida-recursos
rea list-adb-devices
```

### Rede, WebAssembly e sinais lógicos (WSL)
```bash
# Capturas de rede (.pcap / .pcapng com TShark 4.x)
rea inspect-pcap-capture /caminho/captura.pcapng
rea inspect-packet-capture /caminho/captura.pcapng

# WebAssembly (WABT 1.0.42)
rea inspect-wasm-artifact /caminho/modulo.wasm --json

# Analisador lógico (sigrok-cli 0.7.2)
rea inspect-signal-decoders
```

### Instrumentação dinâmica (Frida)
```bash
rea list-frida-devices
rea list-frida-processes
```

---

## 3. Flags úteis em qualquer comando

| Flag | O que faz |
| --- | --- |
| `--format md` | Saída legível em Markdown |
| `--json` | Saída estruturada em JSON |
| `--filter-output a,b.c` | Filtra apenas os campos desejados |
| `--token-count` | Mostra quantos tokens a saída consumiria |
| `--timings` | Exibe o tempo de execução no `stderr` |
| `--help` | Mostra todas as opções do comando específico |

---

## 4. Exemplos de prompts no Antigravity (via `rea` e `rea-wsl`)

- *"Chame `binary_session` em `rea` e em `rea-wsl` para listar todos os provedores disponíveis no Windows e no Linux."*
- *"Use o REA para inspecionar `C:\caminho\do\app`, identificar a arquitetura/runtime e me mostrar as evidências."*
- *"Use `rea-wsl` para recuperar os módulos de `/home/pflug/analises/bundle.js` com Wakaru e mapear os endpoints da API."*
- *"Use `rea-wsl` para medir entropia e inspecionar regiões de `/home/pflug/analises/firmware.bin` com Binwalk."*
- *"Faça uma triagem estática de `C:\caminho\arquivo.exe` (imports, certificados digitais, proteções de compilação e recursos)."*
