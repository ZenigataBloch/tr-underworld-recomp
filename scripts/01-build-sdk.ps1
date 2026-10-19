# Milestone 1, passo A: clona ReXGlue al tag v0.10.0 e compila. NON installa.
# Prerequisiti (da verificare): git, CMake >= 3.25, Ninja, Clang (clang/clang++ nel PATH),
# Windows SDK / ambiente MSVC (lancia da "x64 Native Tools Command Prompt" -> powershell).
param(
  [string]$Work = "$PSScriptRoot\..\work",
  [string]$Config = "Release"
)
$ErrorActionPreference = "Stop"
$Tag = "v0.10.0"
$ExpectedCommit = "f5337cdc947ff6d4c4196737e2c807a48f2a1fc2"

foreach ($t in "git","cmake","ninja","clang","clang++") {
  if (-not (Get-Command $t -ErrorAction SilentlyContinue)) { throw "Manca nel PATH: $t" }
}
cmake --version | Select-Object -First 1
clang --version | Select-Object -First 1

New-Item -ItemType Directory -Force $Work | Out-Null
$Sdk = Join-Path $Work "rexglue-sdk"
if (-not (Test-Path $Sdk)) {
  git clone https://github.com/rexglue/rexglue-sdk.git $Sdk
}
git -C $Sdk fetch --tags
if ($LASTEXITCODE -ne 0) { throw "Fallito (exit code $LASTEXITCODE): git fetch" }
git -C $Sdk checkout $Tag
if ($LASTEXITCODE -ne 0) { throw "Fallito (exit code $LASTEXITCODE): git checkout" }
$Head = (git -C $Sdk rev-parse HEAD).Trim()
if ($Head -ne $ExpectedCommit) { throw "Commit inatteso: $Head (atteso $ExpectedCommit)" }
git -C $Sdk submodule update --init --recursive
if ($LASTEXITCODE -ne 0) { throw "Fallito (exit code $LASTEXITCODE): git submodule" }

# Se esiste un diff di patch, applicalo (un unico file, vedi patches/rexglue-tru.diff)
$Patch = Join-Path $PSScriptRoot "..\patches\rexglue-tru.diff"
if ((Test-Path $Patch) -and ((Get-Item $Patch).Length -gt 0)) {
  git -C $Sdk apply --check $Patch
  git -C $Sdk apply $Patch
}

Push-Location $Sdk
cmake --preset win-amd64
if ($LASTEXITCODE -ne 0) { throw "Fallito (exit code $LASTEXITCODE): cmake configure" }
$sw = [Diagnostics.Stopwatch]::StartNew()
cmake --build out/build/win-amd64 --config $Config
$buildExit = $LASTEXITCODE
$sw.Stop()
Pop-Location
if ($buildExit -ne 0) { throw ("BUILD FALLITA (exit code $buildExit) dopo {0:n0} s" -f $sw.Elapsed.TotalSeconds) }
"BUILD RIUSCITA (exit code 0) in {0:n0} s. Nessuna installazione eseguita." -f $sw.Elapsed.TotalSeconds
