# Opzione B: su Windows senza core.symlinks, i symlink di libmspack diventano file di testo.
# Questo script legge i symlink REALI dal commit del submodule e sostituisce ogni segnaposto
# con una copia del file di destinazione. Tocca solo la cartella work\.
param(
  [string]$Work = "$PSScriptRoot\..\work"
)
$ErrorActionPreference = "Stop"
$Lib = Join-Path $Work "rexglue-sdk\thirdparty\libmspack"
if (-not (Test-Path $Lib)) { throw "Submodule non trovato: $Lib" }

$entries = git -C $Lib ls-tree -r HEAD | Where-Object { $_ -match '^120000 ' }
$n = 0
foreach ($e in $entries) {
  $path = ($e -split "`t", 2)[1]                       # percorso relativo del symlink
  $blob = (($e -split "`t", 2)[0] -split ' ')[2]
  $target = (git -C $Lib cat-file -p $blob).Trim()      # es. ../../libmspack/mspack/lzxd.c
  $linkAbs = Join-Path $Lib $path
  $src = [IO.Path]::GetFullPath((Join-Path (Split-Path $linkAbs) $target))
  if (-not (Test-Path $src)) { throw "Destinazione mancante per ${path}: $src" }
  $item = Get-Item $linkAbs -Force
  if ($item.Attributes -band [IO.FileAttributes]::ReparsePoint) { "gia' symlink vero: $path"; continue }
  Copy-Item $src $linkAbs -Force
  $n++
}
"Sostituiti $n segnaposto con copie."
