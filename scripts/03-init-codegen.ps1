# Milestone 1, passo C: rexglue init + codegen sul TUO default.xex.
# Il progetto generato va in work\tru-project, FUORI dal repo (.gitignore lo esclude).
param(
  [Parameter(Mandatory)][string]$XexPath,    # es. D:\TRU\default.xex (tua copia)
  [Parameter(Mandatory)][string]$GameRoot,   # cartella dei dati del gioco estratti
  [string]$Work = "$PSScriptRoot\..\work",
  [string]$Name = "tru"
)
$ErrorActionPreference = "Stop"
# Usa la CLI installata se c'e', altrimenti quella appena compilata (verificato: out\win-amd64\Release).
$Cli = Join-Path $Work "rexglue-sdk\out\install\win-amd64\bin\rexglue.exe"
if (-not (Test-Path $Cli)) { $Cli = Join-Path $Work "rexglue-sdk\out\win-amd64\Release\rexglue.exe" }
if (-not (Test-Path $Cli)) { throw "rexglue.exe non trovato: compila prima con 01-build-sdk.ps1" }
"Uso CLI: $Cli"
$Proj = Join-Path $Work "tru-project"

$existing = Get-ChildItem $Proj -Filter *_manifest.toml -ErrorAction SilentlyContinue | Select-Object -First 1
if ($existing) {
  "Progetto gia' inizializzato: salto init ($($existing.FullName))"
} else {
  & $Cli init --project-name $Name --xex-path $XexPath --game-root $GameRoot --project-root $Proj
  if ($LASTEXITCODE -ne 0) { throw "init fallito (exit code $LASTEXITCODE)" }
}

# Verificato nel sorgente v0.10.0: init genera <nome>_manifest.toml e codegen prende quel manifest.
$cfg = Get-ChildItem $Proj -Filter *_manifest.toml | Select-Object -First 1
if (-not $cfg) { throw "Nessun *_manifest.toml in $Proj" }
"Manifest: $($cfg.FullName)"

# Codegen senza --force: si ferma sugli errori di validazione, che e' quello che vogliamo vedere.
$log = Join-Path $Work "codegen-01.log"
& $Cli codegen $cfg.FullName 2>&1 | Tee-Object -FilePath $log
"codegen exit code: $LASTEXITCODE"
"Log salvato in $log"
