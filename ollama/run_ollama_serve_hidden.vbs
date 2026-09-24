' run_ollama_serve_hidden.vbs
' Starts "ollama serve" with NO console window, bound to LOOPBACK ONLY.
'
' Why wscript.exe: it is a GUI-subsystem binary, so it never owns a console.
' .Run with window style 0 starts the child hidden from its first instruction,
' unlike a Run-key shortcut or a Task Scheduler action on a console exe, which
' paints a conhost window at every logon.
'
' Why bWaitOnReturn = False: a Run-key launcher does not read an exit code, so
' there is nothing to propagate and no reason to leave a wscript.exe resident
' for the life of the server. The child survives this script exiting.
' NOTE: because of that, NOTHING downstream can infer success from an exit code.
' The only proof this worked is the socket check (netstat -ano | findstr 11434)
' plus GET http://127.0.0.1:11434/api/version.
'
' Why OLLAMA_HOST is pinned: 127.0.0.1:11434 is already ollama's default, so
' this changes no behaviour. It is set so that the bind is stated rather than
' inherited, and so that a stray Machine/User-scope OLLAMA_HOST (e.g. 0.0.0.0,
' the common internet advice for reaching ollama from a container) CANNOT widen
' it. The ollama API has no auth and no TLS; containers reach a loopback-only
' host port through host.docker.internal instead.
'
' Install: put the path of this file in a Run key value (HKCU\...\Run, name
' OllamaServe, value: wscript.exe "<path>\run_ollama_serve_hidden.vbs").
' Rollback: delete that Run value. This file is inert without it. MIT.

Option Explicit

Dim sh, exePath, rc
Set sh = CreateObject("WScript.Shell")

exePath = sh.ExpandEnvironmentStrings("%LOCALAPPDATA%") & "\Programs\Ollama\ollama.exe"

' Process scope only - nothing is written to the Machine or User environment.
sh.Environment("PROCESS")("OLLAMA_HOST") = "127.0.0.1:11434"

rc = sh.Run("""" & exePath & """ serve", 0, False)

WScript.Quit rc
