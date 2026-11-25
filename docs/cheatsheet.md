# REA — Guia de Bolso (CLI & Agentes MCP)

## 1. Diagnóstico e manutenção

```bash
# Verificar saúde geral do ambiente
rea doctor

# Verificar apenas um cliente MCP (ex.: Antigravity)
rea doctor --client antigravity

# Verificar apenas o Ghidra
rea doctor --provider ghidra

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

### Apps JavaScript / Electron (pasta extraída ou `.asar`)
```bash
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

### Binários nativos com Ghidra (Linux/WSL ou Windows)
```bash
rea inspect /caminho/binario --provider ghidra --format json
rea search "padrao" /caminho/binario --provider ghidra
rea function 0x401000 /caminho/binario --provider ghidra
rea decompile 0x401000 /caminho/binario --provider ghidra
```

### Imagens de firmware (WSL / Linux)
```bash
# Entropia (funciona também no Windows)
rea inspect-byte-entropy /caminho/firmware.bin

# Regiões com Binwalk 3.1.x (Linux/WSL)
rea inspect-firmware-regions /caminho/firmware.bin

# Extração com Unblob 26.6.x (Linux/WSL — diretório de saída não deve existir)
rea extract-firmware /caminho/firmware.bin /caminho/saida-nova

# UEFI / NVRAM (embutido, funciona no Windows e Linux)
rea inspect-uefi-firmware /caminho/flash.bin --json
rea inspect-uefi-nvram /caminho/flash.bin --json
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

## 4. Exemplos de prompts no Antigravity (via MCP)

- *"Chame `binary_session` no REA para confirmar que o servidor MCP está ativo e listar os provedores disponíveis."*
- *"Use o REA para inspecionar o diretório `C:\caminho\do\app`, identificar a arquitetura/runtime e me mostrar as evidências."*
- *"Analise `C:\caminho\app.asar` com o REA e mapeie as rotas/IPC entre renderer e main process."*
- *"Faça uma triagem estática de `C:\caminho\arquivo.exe` (imports, certificados digitais, proteções de compilação e recursos)."*
