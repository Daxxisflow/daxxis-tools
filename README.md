# daxxis-tools

Small, dependency-free Windows tools from a one-person operations shop. Each one solves a problem I hit running a local-first AI workstation. MIT licensed. No telemetry, no accounts, nothing phones home.

| Tool | What it does | Needs |
|---|---|---|
| `win-ocr/Read-Screenshots.ps1` | OCRs every PNG/JPG in a folder with the OCR engine already inside Windows 10/11 (no install, no cloud) and writes one `.txt` per image | Windows PowerShell 5.1 |
| `ollama/run_ollama_serve_hidden.vbs` | Starts `ollama serve` at logon with no console window and the API pinned to `127.0.0.1` so a stray `OLLAMA_HOST=0.0.0.0` can never expose it | Ollama for Windows |
| `guard/Guard-Volume.ps1` | Exit-code guard for scheduled tasks: exits 3 when a named drive letter or volume label is mounted, so automation never runs while a sensitive volume is open | Windows PowerShell 5.1 |

## Why these exist

- The Windows OCR engine reads a settings screenshot in under a second and needs no Python, no Tesseract, no API key.
- Most "expose Ollama to Docker" advice sets `OLLAMA_HOST=0.0.0.0`, which also exposes an unauthenticated API to your LAN. The launcher pins the bind per process instead.
- A scheduled task that runs while an encrypted volume is mounted is the easiest way to leak its contents into a corpus or a backup. A three-line guard in front of every task closes that door.

## Use

```powershell
# OCR a folder of screenshots
powershell -NoProfile -ExecutionPolicy Bypass -File .\win-ocr\Read-Screenshots.ps1 -Source "C:\Screenshots" -OutDir "C:\Screenshots\_text" -NewerThan "2026-09-01"

# Guard a task (put this first in the task's launcher; stop if it exits 3)
powershell -NoProfile -ExecutionPolicy Bypass -File .\guard\Guard-Volume.ps1 -DriveLetter Y -LabelMatch SEALED
```

## Author

Daxxis (daxxisflow.com). Field guides on running a solo AI operations home are on Leanpub.
