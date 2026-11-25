<#
.SYNOPSIS
    Instala todo o ambiente REA em um PC Windows novo:
    1) Node.js (verifica/instala) + rea-agents + MCP no Antigravity
    2) WSL 2 + Ubuntu 24.04
    3) Dentro do Ubuntu: Node 24 + REA + Ghidra 12.2 + JDK 25 + Binwalk 3.1.0 + Unblob 26.6.4
.DESCRIPTION
    Script idempotente: se precisar reiniciar o Windows apos instalar o WSL ou o Node,
    basta rodar .\setup-all.ps1 novamente que ele continua de onde parou.
.EXAMPLE
    .\setup-all.ps1
.EXAMPLE
    .\setup-all.ps1 -Client antigravity -Providers all
.EXAMPLE
    .\setup-all.ps1 -SkipWsl
#>
[CmdletBinding()]
param(
    [string]$Client = "antigravity",
    [ValidateSet("all", "ghidra", "binwalk", "unblob", "none")]
    [string]$Providers = "all",
    [string]$WslDistro = "Ubuntu-24.04",
    [switch]$SkipWindows,
    [switch]$SkipWsl
)

$ErrorActionPreference = "Stop"
$RepoRoot = $PSScriptRoot

function Test-SupportedNode {
    $nodeCmd = Get-Command node -ErrorAction SilentlyContinue
    if (-not $nodeCmd) { return $false }
    $raw = (& node -v 2>$null).Trim()
    if ($raw -notmatch '^v(\d+)\.(\d+)\.(\d+)') { return $false }
    $maj = [int]$Matches[1]; $min = [int]$Matches[2]; $pat = [int]$Matches[3]
    if ($maj -eq 22 -and ($min -gt 23 -or ($min -eq 23 -and $pat -ge 4))) { return $true }
    if ($maj -eq 24 -and ($min -gt 22 -or ($min -eq 22 -and $pat -ge 1))) { return $true }
    if ($maj -ge 26 -and ($maj -gt 26 -or $min -gt 12 -or ($min -eq 12 -and $pat -ge 1))) { return $true }
    return $false
}

function Convert-ToWslPath([string]$WindowsPath) {
    $full = (Resolve-Path $WindowsPath).Path
    if ($full -match '^([A-Za-z]):\\(.*)$') {
        $drive = $Matches[1].ToLowerInvariant()
        $rest = $Matches[2] -replace '\\', '/'
        return "/mnt/$drive/$rest"
    }
    throw "Nao foi possivel converter o caminho para WSL: $WindowsPath"
}

Write-Host "====================================================" -ForegroundColor Cyan
Write-Host "  REA Setup Kit - Instalacao Completa (Win + WSL)   " -ForegroundColor Cyan
Write-Host "====================================================" -ForegroundColor Cyan

# --- ETAPA 1: WINDOWS ---
if (-not $SkipWindows) {
    Write-Host ""
    Write-Host "[1/3] Configurando Windows + REA + MCP ($Client)..." -ForegroundColor Yellow

    if (-not (Test-SupportedNode)) {
        Write-Host "Node.js suportado (22.23.4+, 24.22.1+ ou 26.12.1+) nao encontrado." -ForegroundColor Yellow
        if (Get-Command winget -ErrorAction SilentlyContinue) {
            Write-Host "Instalando Node.js LTS via winget..." -ForegroundColor Cyan
            & winget install --id OpenJS.NodeJS.LTS --exact --accept-package-agreements --accept-source-agreements
            Write-Host ""
            Write-Host "Node.js instalado! Feche e reabra o PowerShell, depois rode .\setup-all.ps1 novamente." -ForegroundColor Green
            exit 0
        } else {
            throw "Instale o Node.js 24+ em https://nodejs.org/ e rode .\setup-all.ps1 novamente."
        }
    }

    & "$RepoRoot\scripts\setup-windows.ps1" -Client $Client
}

# --- ETAPA 2: WSL UBUNTU 24.04 ---
if (-not $SkipWsl) {
    Write-Host ""
    Write-Host "[2/3] Verificando WSL 2 ($WslDistro)..." -ForegroundColor Yellow

    if (-not (Get-Command wsl -ErrorAction SilentlyContinue)) {
        throw "Comando 'wsl' nao encontrado. Ative o WSL no Windows e rode .\setup-all.ps1 novamente."
    }

    $distros = (& wsl -l -q 2>$null) -replace "`0", "" | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne "" }
    if ($distros -notcontains $WslDistro) {
        Write-Host "Distribuicao '$WslDistro' nao instalada. Iniciando instalacao do WSL 2..." -ForegroundColor Cyan
        & wsl --update
        & wsl --set-default-version 2
        & wsl --install -d $WslDistro
        Write-Host ""
        Write-Host "Proximo passo:" -ForegroundColor Green
        Write-Host "  1. Se o Windows pedir reinicializacao, reinicie o PC."
        Write-Host "  2. Crie seu usuario e senha quando a janela do $WslDistro abrir."
        Write-Host "  3. Depois rode novamente: .\setup-all.ps1"
        exit 0
    }

    & wsl --set-default $WslDistro | Out-Null

    Write-Host ""
    Write-Host "[3/3] Instalando REA e provedores ($Providers) dentro do $WslDistro..." -ForegroundColor Yellow
    Write-Host "      (O sudo dentro do Ubuntu pode pedir sua senha do Linux.)" -ForegroundColor DarkGray

    $wslRepo = Convert-ToWslPath $RepoRoot
    & wsl -d $WslDistro -- bash -c "cd '$wslRepo' && bash scripts/setup-wsl-base.sh"

    if ($Providers -ne "none") {
        $flag = "--$Providers"
        & wsl -d $WslDistro -- bash -c "cd '$wslRepo' && bash scripts/setup-wsl-providers.sh $flag"
    }
}

Write-Host ""
Write-Host "====================================================" -ForegroundColor Green
Write-Host "  Tudo pronto!                                      " -ForegroundColor Green
Write-Host "  - Reinicie o $Client para ativar o MCP do REA.    " -ForegroundColor Green
Write-Host "  - No Ubuntu (WSL), rode: rea doctor --provider ghidra" -ForegroundColor Green
Write-Host "====================================================" -ForegroundColor Green
