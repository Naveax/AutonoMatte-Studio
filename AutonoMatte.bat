@echo off
setlocal EnableExtensions
set "AUTONOMATTE_SELF=%~f0"
set "AUTONOMATTE_ARGS=%*"
PowerShell -NoLogo -NoProfile -ExecutionPolicy Bypass -Command "$raw=Get-Content -Raw -LiteralPath $env:AUTONOMATTE_SELF; $mark='#<AUTONOMATTE_POWERSHELL>'; $i=$raw.IndexOf($mark); if($i -lt 0){throw 'Launcher payload not found'}; $code=$raw.Substring($i+$mark.Length); & ([ScriptBlock]::Create($code))"
set "AUTONOMATTE_EXIT=%ERRORLEVEL%"
if not "%AUTONOMATTE_EXIT%"=="0" pause
exit /b %AUTONOMATTE_EXIT%
#<AUTONOMATTE_POWERSHELL>
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$Root = Split-Path -Parent $env:AUTONOMATTE_SELF
$App = Join-Path $Root '.app'
$Runtime = Join-Path $Root '.runtime'
$Models = Join-Path $Root '.models'
$Python = Join-Path $Runtime 'Scripts\python.exe'
$Mode = [string]$env:AUTONOMATTE_ARGS
if ($null -eq $Mode) { $Mode = '' }
$Mode = $Mode.Trim()

Set-Location $Root
New-Item -ItemType Directory -Force -Path $Models | Out-Null
$env:HF_HOME = $Models
$env:HUGGINGFACE_HUB_CACHE = Join-Path $Models 'hub'
$env:U2NET_HOME = Join-Path $Models 'u2net'
$env:HF_HUB_DISABLE_SYMLINKS_WARNING = '1'
$env:OMP_NUM_THREADS = '2'
$env:MKL_NUM_THREADS = '2'
$env:OPENBLAS_NUM_THREADS = '2'
$env:NUMEXPR_NUM_THREADS = '2'

function Write-Title([string]$Text) {
    Write-Host "`n=== $Text ===" -ForegroundColor Cyan
}

function Invoke-Checked {
    param([string]$Exe, [string[]]$Arguments)
    & $Exe @Arguments
    if ($LASTEXITCODE -ne 0) {
        throw "Command failed ($LASTEXITCODE): $Exe $($Arguments -join ' ')"
    }
}

function Find-PythonCommand {
    $candidates = @(
        @('py', '-3.11'),
        @('py', '-3.12'),
        @('python', '')
    )
    foreach ($entry in $candidates) {
        try {
            if ($entry[1]) {
                $cmd = $entry[0]
                & $cmd $entry[1] -c "import sys; assert (3,10) <= sys.version_info[:2] < (3,13)" 2>$null
            } else {
                $cmd = $entry[0]
                & $cmd -c "import sys; assert (3,10) <= sys.version_info[:2] < (3,13)" 2>$null
            }
            if ($LASTEXITCODE -eq 0) { return $entry }
        } catch {}
    }
    return $null
}

function Ensure-Python {
    $found = Find-PythonCommand
    if ($null -ne $found) { return $found }
    $winget = Get-Command winget -ErrorAction SilentlyContinue
    if ($null -eq $winget) {
        throw 'Python 3.11/3.12 not found. Install Python 3.11 x64 and run AutonoMatte.bat again.'
    }
    Write-Title 'Python 3.11 kuruluyor'
    & winget install --id Python.Python.3.11 --exact --silent --accept-package-agreements --accept-source-agreements
    if ($LASTEXITCODE -ne 0) { throw 'Python automatic installation failed.' }
    $env:Path = [Environment]::GetEnvironmentVariable('Path','Machine') + ';' + [Environment]::GetEnvironmentVariable('Path','User')
    $found = Find-PythonCommand
    if ($null -eq $found) { throw 'Python installed but was not detected. Restart Windows and run again.' }
    return $found
}

function Get-GpuMode {
    if ($null -ne (Get-Command nvidia-smi -ErrorAction SilentlyContinue)) { return 'nvidia' }
    try {
        $names = @(Get-CimInstance Win32_VideoController -ErrorAction Stop | ForEach-Object { $_.Name })
        if ($names | Where-Object { $_ -match 'AMD|Radeon' }) { return 'amd' }
    } catch {}
    return 'cpu'
}

function Ensure-Runtime([switch]$Universal) {
    if (-not (Test-Path -LiteralPath $Python)) {
        Write-Title 'İlk kurulum hazırlanıyor'
        $base = Ensure-Python
        if ($base[1]) {
            $baseCmd = $base[0]
            Invoke-Checked $baseCmd @($base[1], '-m', 'venv', $Runtime)
        } else {
            $baseCmd = $base[0]
            Invoke-Checked $baseCmd @('-m', 'venv', $Runtime)
        }
        Invoke-Checked $Python @('-m','pip','install','--upgrade','pip','setuptools','wheel')
    }

    $stamp = Join-Path $Runtime 'autonomatte-0.6.1.ready'
    if ((Test-Path $stamp) -and -not $Universal) { return }

    $gpu = Get-GpuMode
    Write-Title "Bağımlılıklar kuruluyor ($gpu)"
    if ($Universal) {
        try {
            Invoke-Checked $Python @('-m','pip','install','torch','torchvision','--index-url','https://download.pytorch.org/whl/cu128')
        } catch {
            Invoke-Checked $Python @('-m','pip','install','torch','torchvision')
        }
        Invoke-Checked $Python @('-m','pip','install','-e',"${App}[birefnet,rembg-cpu,formats]")
    } elseif ($gpu -eq 'nvidia') {
        try {
            Invoke-Checked $Python @('-m','pip','install','torch','torchvision','--index-url','https://download.pytorch.org/whl/cu128')
        } catch {
            Invoke-Checked $Python @('-m','pip','install','torch','torchvision')
        }
        Invoke-Checked $Python @('-m','pip','install','-e',"${App}[birefnet,rembg-gpu,formats]")
        try { Invoke-Checked $Python @('-m','pip','install','git+https://github.com/PramaLLC/BEN2.git') } catch { Write-Warning 'BEN2 kurulamadı; BiRefNet kullanılacak.' }
    } elseif ($gpu -eq 'amd') {
        Invoke-Checked $Python @('-m','pip','install','-e',"${App}[rembg-dml,formats]")
    } else {
        Invoke-Checked $Python @('-m','pip','install','-e',"${App}[rembg-cpu,formats]")
    }
    Set-Content -LiteralPath $stamp -Value (Get-Date).ToString('o') -Encoding UTF8
}

function Migrate-Models {
    Write-Title 'Eski modeller taşınıyor'
    Invoke-Checked $Python @('-m','autonomatte.models_cli','--cache',$Models,'migrate','--project-root',$Root)
}

function Ensure-RecommendedModels {
    $inventory = & $Python -m autonomatte.models_cli --cache $Models list | ConvertFrom-Json
    if (@($inventory | Where-Object { $_.installed }).Count -gt 0) { return }
    Write-Title 'Donanıma uygun modeller indiriliyor'
    try {
        Invoke-Checked $Python @('-m','autonomatte.models_cli','--cache',$Models,'prefetch','--recommended','--limit','2')
    } catch {
        Write-Warning 'Model indirme tamamlanamadı. İnternet bağlantısını kontrol edin; uygulama klasik/çizim motorlarıyla yine açılacak.'
    }
}

function Prepare-GitHubBundle {
    Ensure-Runtime -Universal
    Migrate-Models
    Write-Title 'Evrensel model paketi indiriliyor'
    $all = @(
        'ben2',
        'birefnet-hr-general',
        'birefnet-hr',
        'birefnet-dynamic',
        'birefnet-dynamic-matting',
        'rembg-isnet',
        'rembg-u2net'
    )
    foreach ($model in $all) {
        try {
            Invoke-Checked $Python @('-m','autonomatte.models_cli','--cache',$Models,'prefetch',$model)
        } catch {
            Write-Warning "$model indirilemedi: $($_.Exception.Message)"
        }
    }
    & $Python -m autonomatte.models_cli --cache $Models list | Set-Content -LiteralPath (Join-Path $Models 'MODEL_INVENTORY.json') -Encoding UTF8

    $git = Get-Command git -ErrorAction SilentlyContinue
    if ($null -ne $git) {
        try {
            & git lfs install
            & git lfs track '*.onnx' '*.safetensors' '*.pth' '*.pt' '*.bin'
        } catch { Write-Warning 'Git LFS yapılandırması tamamlanamadı.' }
    }
    Write-Host "`nGitHub paketi hazırlandı. Modeller: $Models" -ForegroundColor Green
    Write-Host 'Bu klasörü GitHub Desktop veya git + Git LFS ile yükleyin.' -ForegroundColor Green
}

if ($Mode -eq '--reset-runtime') {
    if (Test-Path $Runtime) { Remove-Item -Recurse -Force $Runtime }
    Write-Host 'Runtime silindi. Sonraki çift tıklamada yeniden kurulacak.' -ForegroundColor Green
    exit 0
}

if ($Mode -eq '--prepare-github') {
    Prepare-GitHubBundle
    exit 0
}

Ensure-Runtime
Migrate-Models
Ensure-RecommendedModels

if ($Mode -eq '--doctor') {
    Invoke-Checked $Python @('-m','autonomatte.doctor','--cache',$Models)
    exit 0
}

Write-Title 'AutonoMatte Studio başlatılıyor'
& $Python -m autonomatte.webapp
exit $LASTEXITCODE
