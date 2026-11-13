$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$python = Join-Path $root ".venv\Scripts\python.exe"
$mt5 = "C:\Program Files\MetaTrader 5\terminal64.exe"
$runtimeDir = Join-Path $root "data"
$runtimeFile = Join-Path $runtimeDir "runtime.json"
$logDir = Join-Path $root "logs"

function Test-LocalUrl([string]$url) {
    try {
        $response = Invoke-WebRequest -Uri $url -UseBasicParsing -TimeoutSec 2
        return $response.StatusCode -ge 200 -and $response.StatusCode -lt 500
    } catch {
        return $false
    }
}

function Wait-LocalUrl([string]$url, [int]$seconds = 45) {
    $deadline = (Get-Date).AddSeconds($seconds)
    while ((Get-Date) -lt $deadline) {
        if (Test-LocalUrl $url) { return $true }
        Start-Sleep -Milliseconds 500
    }
    return $false
}

try {
    if (-not (Test-Path -LiteralPath $python)) { throw "No existe el entorno Python del proyecto. Ejecuta primero la instalación indicada en README.md." }
    if (-not (Test-Path -LiteralPath (Join-Path $root "frontend\dist\index.html"))) { throw "La interfaz compilada no está disponible. Ejecuta la compilación del proyecto una vez." }

    if (-not (Get-Process -Name terminal64 -ErrorAction SilentlyContinue) -and (Test-Path -LiteralPath $mt5)) {
        Start-Process -FilePath $mt5 | Out-Null
        Start-Sleep -Seconds 3
    }

    New-Item -ItemType Directory -Force -Path $runtimeDir, $logDir | Out-Null
    $pids = [ordered]@{}

    # Reuse only the previous GOLD TERMINAL AI backend, never an unrelated process.
    if (Test-Path -LiteralPath $runtimeFile) {
        try {
            $previous = Get-Content -LiteralPath $runtimeFile -Raw | ConvertFrom-Json
            $previousPid = [int]$previous.backend
            $previousProcess = Get-Process -Id $previousPid -ErrorAction SilentlyContinue
            if ($previousProcess -and $previousProcess.Path -eq $python) {
                Stop-Process -Id $previousPid -Force
                Start-Sleep -Milliseconds 500
            }
        } catch { }
    }

    if (-not (Test-LocalUrl "http://127.0.0.1:8000/api/health")) {
        $backend = Start-Process -FilePath $python -ArgumentList @("-m", "uvicorn", "app.main:app", "--app-dir", "backend", "--host", "127.0.0.1", "--port", "8000") -WorkingDirectory $root -WindowStyle Hidden -RedirectStandardOutput (Join-Path $logDir "backend.out.log") -RedirectStandardError (Join-Path $logDir "backend.err.log") -PassThru
        $pids.backend = $backend.Id
    }

    if (-not (Wait-LocalUrl "http://127.0.0.1:8000/api/health")) { throw "El backend no respondió. Revisa logs/backend.err.log." }

    $pids | ConvertTo-Json | Set-Content -LiteralPath $runtimeFile -Encoding UTF8

    $browserCandidates = @(
        "$env:ProgramFiles\Microsoft\Edge\Application\msedge.exe",
        "${env:ProgramFiles(x86)}\Microsoft\Edge\Application\msedge.exe",
        "$env:ProgramFiles\Google\Chrome\Application\chrome.exe",
        "${env:ProgramFiles(x86)}\Google\Chrome\Application\chrome.exe",
        "$env:ProgramFiles\BraveSoftware\Brave-Browser\Application\brave.exe"
    )
    $browser = $browserCandidates | Where-Object { Test-Path -LiteralPath $_ } | Select-Object -First 1
    if ($browser) {
        Start-Process -FilePath $browser -ArgumentList "--app=http://127.0.0.1:8000/" | Out-Null
    } else {
        Start-Process "http://127.0.0.1:8000/" | Out-Null
    }
} catch {
    $errorFile = Join-Path $logDir "launcher.err.log"
    New-Item -ItemType Directory -Force -Path $logDir | Out-Null
    ("{0} {1}" -f (Get-Date -Format s), $_.Exception.ToString()) | Add-Content -LiteralPath $errorFile
    try {
        Add-Type -AssemblyName PresentationFramework -ErrorAction SilentlyContinue
        [System.Windows.MessageBox]::Show("GOLD TERMINAL AI no pudo iniciarse. Revisa logs\\launcher.err.log.", "GOLD TERMINAL AI", "OK", "Error") | Out-Null
    } catch { }
    exit 1
}
