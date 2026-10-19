# Milestone 1, passo B: installa l'SDK nel prefisso locale (out\install\win-amd64).
# ATTENZIONE: registra anche l'SDK nel registro pacchetti CMake dell'utente,
# così find_package(rexglue) lo trova. Lancia solo dopo conferma.
param(
  [string]$Work = "$PSScriptRoot\..\work",
  [string]$Config = "Release"
)
$ErrorActionPreference = "Stop"
$Sdk = Join-Path $Work "rexglue-sdk"
Push-Location $Sdk
cmake --build out/build/win-amd64 --config $Config --target install
$e = $LASTEXITCODE
Pop-Location
if ($e -ne 0) { throw "INSTALL FALLITO (exit code $e)" }
$bin = Join-Path $Sdk "out\install\win-amd64\bin"
"Installato. CLI: $bin\rexglue.exe (aggiungi $bin al PATH se vuoi)"
& "$bin\rexglue.exe" --help
