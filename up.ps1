param(
  [switch]$Foreground
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot
Set-Location $repoRoot

$envFile = Join-Path $PSScriptRoot ".env"
if (-not (Test-Path $envFile)) {
  Copy-Item (Join-Path $PSScriptRoot "env.example") $envFile -Force
  Write-Host "Created deployment\.env from env.example"
}

$compose = Join-Path $PSScriptRoot "docker-compose.yml"

if ($Foreground) {
  & docker compose --env-file $envFile -f $compose up --build @args
} else {
  & docker compose --env-file $envFile -f $compose up --build -d @args
  Write-Host "Started in background. Use .\down.ps1 to stop."
}

