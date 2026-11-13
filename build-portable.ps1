$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $root

$python = Join-Path $root ".venv\Scripts\python.exe"
$systemPython = "C:\Users\olive\AppData\Local\Programs\Python\Python312\python.exe"
$pnpm = "C:\Users\olive\.cache\codex-runtimes\codex-primary-runtime\dependencies\bin\fallback\pnpm.cmd"
$export = Join-Path $root "export"
$build = Join-Path $root "build\portable"
$frontendDist = Join-Path $root "frontend\dist"
$modelAssets = Join-Path $root "models"

if (-not (Test-Path -LiteralPath $python)) { throw "No existe .venv. Instala las dependencias del backend primero." }
if (-not (Test-Path -LiteralPath (Join-Path $frontendDist "index.html"))) {
    & $pnpm --dir frontend run build
    if ($LASTEXITCODE -ne 0) { throw "No se pudo compilar el frontend." }
}
$hasPyInstaller = & $python -c "import importlib.util; print(bool(importlib.util.find_spec('PyInstaller')))"
if ($hasPyInstaller -notmatch "True") {
    if (-not (Test-Path -LiteralPath $systemPython)) { throw "No se encontró Python 3.12 para instalar PyInstaller." }
    & $systemPython -m pip install --target (Join-Path $root ".venv\Lib\site-packages") pyinstaller
    if ($LASTEXITCODE -ne 0) { throw "No se pudo instalar PyInstaller en el entorno local." }
}

New-Item -ItemType Directory -Force -Path $export, $build | Out-Null
& $python -m PyInstaller --noconfirm --clean --onefile --noconsole --name "GOLD TERMINAL AI v9" --distpath $export --workpath $build --specpath $build --paths (Join-Path $root "backend") --paths (Join-Path $root "backend\vendor\Kronos") --add-data "$frontendDist;frontend_dist" --add-data "$modelAssets;models" --collect-all MetaTrader5 (Join-Path $root "backend\launcher.py")
if ($LASTEXITCODE -ne 0) { throw "PyInstaller no pudo crear el ejecutable." }

Write-Host "Ejecutable creado en: $(Join-Path $export 'GOLD TERMINAL AI v9.exe')"
