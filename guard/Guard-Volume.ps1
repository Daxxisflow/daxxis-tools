# Guard-Volume.ps1 - exit-code guard for scheduled tasks and launchers.
# Answers one question: is the named drive letter, or any volume whose label matches, mounted right now?
#   exit 0 = not mounted, the task may run      exit 3 = MOUNTED: the caller must stop and do nothing.
# It never mounts, dismounts, reads or lists the volume. Put it first in every launcher and stop on exit 3.
# Usage: powershell -NoProfile -ExecutionPolicy Bypass -File Guard-Volume.ps1 -DriveLetter Y -LabelMatch SEALED [-Quiet]
# MIT License (c) 2026 Daxxis.
param([string]$DriveLetter = 'Y', [string]$LabelMatch = 'SEALED', [switch]$Quiet)
$mounted = $false; $why = @()
$vol = Get-Volume -DriveLetter $DriveLetter -ErrorAction SilentlyContinue
if ($vol) { $mounted = $true; $why += "drive letter $DriveLetter is mounted (label '$($vol.FileSystemLabel)')" }
if ($LabelMatch) {
  $lab = Get-Volume -ErrorAction SilentlyContinue | Where-Object { $_.FileSystemLabel -match $LabelMatch }
  if ($lab) { $mounted = $true; $why += ("a volume labelled like '$LabelMatch' is mounted as " + (($lab | ForEach-Object { "$($_.DriveLetter):" }) -join ' ')) }
}
if ($mounted) {
  if (-not $Quiet) { Write-Output ("VOLUME-GUARD: STOP. " + ($why -join '; ') + ". No automation runs while this volume is open.") }
  exit 3
}
if (-not $Quiet) { Write-Output "VOLUME-GUARD: clear." }
exit 0
