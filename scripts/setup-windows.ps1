<#
.SYNOPSIS
    Instala o REA (rea-agents) no Windows e configura a integracao MCP no agente selecionado.
.EXAMPLE
    .\scripts\setup-windows.ps1 -Client antigravity
.EXAMPLE
    .\scripts\setup-windows.ps1 -Client antigravity -WithFrida
#>
[CmdletBinding()]
param(
    [string]$Client = "antigravity",
    [switch]$WithFrida,
    [switch]$SkipSetup
)

$ErrorActionPreference = "Stop"

Write-Host "==> Verificando Node.js..." -ForegroundColor Cyan
$nodeVersionRaw = (& node -v).Trim()
if (-not $nodeVersionRaw) {
    throw "Node.js nao encontrado. Instale Node 22.23.4+, 24.22.1+ ou 26.12.1+ via https://nodejs.org/ ou 'winget install OpenJS.NodeJS.LTS'."
}
Write-Host "    Node detectado: $nodeVersionRaw"

Write-Host "==> Instalando/atualizando rea-agents globalmente..." -ForegroundColor Cyan
if ($WithFrida) {
    & npm.cmd install --global --allow-scripts=frida rea-agents
} else {
    & npm.cmd install --global rea-agents
}

Write-Host "==> Verificando CLI do REA..." -ForegroundColor Cyan
$reaVersion = (& rea --version).Trim()
Write-Host "    REA instalado: $reaVersion"

if (-not $SkipSetup) {
    Write-Host "==> Executando rea setup para o cliente '$Client'..." -ForegroundColor Cyan
    Push-Location $HOME
    try {
        & rea setup --client $Client
    } finally {
        Pop-Location
    }

    Write-Host "==> Validando configuracao com rea doctor..." -ForegroundColor Cyan
    & rea doctor --client $Client
}

Write-Host ""
Write-Host "Concluido! Reinicie o cliente '$Client' para carregar o servidor MCP do REA." -ForegroundColor Green
