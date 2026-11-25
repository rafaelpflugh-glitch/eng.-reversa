<#
.SYNOPSIS
    Registra o servidor MCP "rea-wsl" no Antigravity (~/.gemini/config/mcp_config.json),
    permitindo usar os motores Linux (Ghidra completo, Binwalk, Unblob, Rizin, GDB,
    Wakaru, JADX, TShark, WABT, sigrok-cli, pwntools) diretamente do chat no Windows.
.EXAMPLE
    .\scripts\register-wsl-mcp.ps1
#>
[CmdletBinding()]
param(
    [string]$WslDistro = "Ubuntu-24.04",
    [string]$ServerName = "rea-wsl",
    [string]$ConfigPath = (Join-Path $HOME ".gemini\config\mcp_config.json")
)

$ErrorActionPreference = "Stop"

$configDir = Split-Path -Parent $ConfigPath
if (-not (Test-Path $configDir)) {
    New-Item -ItemType Directory -Path $configDir -Force | Out-Null
}

if (Test-Path $ConfigPath) {
    $backupPath = "$ConfigPath.rea-wsl.backup"
    if (-not (Test-Path $backupPath)) {
        Copy-Item -Path $ConfigPath -Destination $backupPath -Force
    }
    $raw = Get-Content -Path $ConfigPath -Raw -Encoding UTF8
    $json = if ([string]::IsNullOrWhiteSpace($raw)) { [pscustomobject]@{} } else { $raw | ConvertFrom-Json }
} else {
    $json = [pscustomobject]@{}
}

if (-not ($json.PSObject.Properties.Name -contains "mcpServers") -or $null -eq $json.mcpServers) {
    $json | Add-Member -NotePropertyName "mcpServers" -NotePropertyValue ([pscustomobject]@{}) -Force
}

$entry = [pscustomobject]@{
    command = "wsl.exe"
    args    = @("-d", $WslDistro, "--", "bash", "-c", 'exec "$HOME/.local/bin/rea-wsl-mcp"')
}

if ($json.mcpServers.PSObject.Properties.Name -contains $ServerName) {
    $json.mcpServers.$ServerName = $entry
} else {
    $json.mcpServers | Add-Member -NotePropertyName $ServerName -NotePropertyValue $entry
}

$formatted = $json | ConvertTo-Json -Depth 10
[System.IO.File]::WriteAllText($ConfigPath, "$formatted`n", [System.Text.UTF8Encoding]::new($false))

Write-Host "==> Servidor MCP '$ServerName' registrado em: $ConfigPath" -ForegroundColor Green
Write-Host "    Distro WSL: $WslDistro" -ForegroundColor Cyan
Write-Host "    Reinicie o Antigravity para ativar o servidor '$ServerName'." -ForegroundColor Yellow
