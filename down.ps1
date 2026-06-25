Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot
Set-Location $repoRoot

$envFile = Join-Path $PSScriptRoot ".env"
$compose = Join-Path $PSScriptRoot "docker-compose.yml"

& docker compose --env-file $envFile -f $compose down @args

