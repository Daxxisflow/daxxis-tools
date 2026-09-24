# Read-Screenshots.ps1 - OCR every PNG/JPG in a folder with the OCR engine built into Windows 10/11.
# No install, no cloud, no API key. Writes one UTF-8 .txt per image (same base name) into -OutDir.
# Usage: powershell -NoProfile -ExecutionPolicy Bypass -File Read-Screenshots.ps1 -Source <folder> -OutDir <folder> [-NewerThan "2026-09-01 00:00"]
# MIT License (c) 2026 Daxxis.
param(
  [Parameter(Mandatory=$true)][string]$Source,
  [Parameter(Mandatory=$true)][string]$OutDir,
  [string]$NewerThan = "1900-01-01"
)
Add-Type -AssemblyName System.Runtime.WindowsRuntime
$null = [Windows.Media.Ocr.OcrEngine,Windows.Foundation,ContentType=WindowsRuntime]
$null = [Windows.Graphics.Imaging.BitmapDecoder,Windows.Foundation,ContentType=WindowsRuntime]
$null = [Windows.Storage.StorageFile,Windows.Foundation,ContentType=WindowsRuntime]
$asTask = ([System.WindowsRuntimeSystemExtensions].GetMethods() | Where-Object { $_.Name -eq 'AsTask' -and $_.GetParameters().Count -eq 1 -and $_.GetParameters()[0].ParameterType.Name -eq 'IAsyncOperation`1' })[0]
function Await($op, $type) { $t = $asTask.MakeGenericMethod($type).Invoke($null, @($op)); $t.Wait() | Out-Null; $t.Result }
$engine = [Windows.Media.Ocr.OcrEngine]::TryCreateFromUserProfileLanguages()
if (-not $engine) { throw "No OCR language pack for the current user profile language. Settings > Time & language > Language > add the language's optional features (OCR)." }
New-Item -ItemType Directory -Force $OutDir | Out-Null
$cut = Get-Date $NewerThan
$files = @(Get-ChildItem $Source -File | Where-Object { $_.Extension -match '^\.(png|jpg|jpeg|bmp)$' -and $_.LastWriteTime -gt $cut } | Sort-Object LastWriteTime)
$n = 0
foreach ($f in $files) {
  try {
    $sf  = Await ([Windows.Storage.StorageFile]::GetFileFromPathAsync($f.FullName)) ([Windows.Storage.StorageFile])
    $st  = Await ($sf.OpenAsync([Windows.Storage.FileAccessMode]::Read)) ([Windows.Storage.Streams.IRandomAccessStream])
    $dec = Await ([Windows.Graphics.Imaging.BitmapDecoder]::CreateAsync($st)) ([Windows.Graphics.Imaging.BitmapDecoder])
    $bmp = Await ($dec.GetSoftwareBitmapAsync()) ([Windows.Graphics.Imaging.SoftwareBitmap])
    $res = Await ($engine.RecognizeAsync($bmp)) ([Windows.Media.Ocr.OcrResult])
    $txt = ($res.Lines | ForEach-Object { $_.Text }) -join "`n"
    $st.Dispose()
  } catch { $txt = "OCR-FAIL: $($_.Exception.Message)" }
  Set-Content -Path (Join-Path $OutDir ([IO.Path]::GetFileNameWithoutExtension($f.Name) + ".txt")) -Value $txt -Encoding utf8
  $n++
}
"done: $n image(s) from $Source -> $OutDir"
