# Milestone 1, passo D: configura e compila il progetto del gioco generato da 'rexglue init'.
# DA LANCIARE DA "x64 Native Tools Command Prompt for VS" -> powershell (serve l'ambiente VS).
# ATTENZIONE: compila ~250 file C++ generati, molto pesante per CPU/RAM e puo' durare a lungo.
# Lancia solo quando non stai giocando. Il codegen e' parte della build (rigenera solo se serve).
param(
  [string]$Work = $(if (Test-Path "$PSScriptRoot\work") { "$PSScriptRoot\work" } else { "$PSScriptRoot\..\work" }),
  [string]$Preset = "win-amd64-release",
  [int]$Jobs = 0          # 0 = default di ninja; se la RAM non basta prova -Jobs 4
)
$ErrorActionPreference = "Stop"
$Proj = Join-Path $Work "tru-project"
$Prefix = Join-Path $Work "rexglue-sdk\out\install\win-amd64"
if (-not (Test-Path (Join-Path $Proj "CMakeLists.txt"))) { throw "Progetto non trovato: $Proj" }
foreach ($t in "cmake","ninja","clang","clang++") {
  if (-not (Get-Command $t -ErrorAction SilentlyContinue)) { throw "Manca nel PATH: $t (lancia dall'ambiente VS)" }
}
$log = Join-Path $Work "build-game-01.log"

Push-Location $Proj
try {
  cmake --preset $Preset "-DCMAKE_PREFIX_PATH=$Prefix" 2>&1 | Tee-Object -FilePath $log
  if ($LASTEXITCODE -ne 0) { throw "CONFIGURE FALLITO (exit code $LASTEXITCODE), vedi $log" }

  $sw = [Diagnostics.Stopwatch]::StartNew()
  if ($Jobs -gt 0) { cmake --build "out/build/$Preset" -j $Jobs 2>&1 | Tee-Object -FilePath $log -Append }
  else             { cmake --build "out/build/$Preset"        2>&1 | Tee-Object -FilePath $log -Append }
  $code = $LASTEXITCODE
  $sw.Stop()
  if ($code -ne 0) { throw ("BUILD FALLITA (exit code $code) dopo {0:n0} s, vedi $log" -f $sw.Elapsed.TotalSeconds) }
  "BUILD RIUSCITA (exit code 0) in {0:n0} s. Log: $log" -f $sw.Elapsed.TotalSeconds
} finally { Pop-Location }

Get-ChildItem (Join-Path $Proj "out") -Recurse -File -Include *.exe,*.dll -ErrorAction SilentlyContinue |
  Where-Object { $_.FullName -notmatch 'CompilerId' } |
  Select-Object FullName,Length | Format-Table -AutoSize | Out-String -Width 250
