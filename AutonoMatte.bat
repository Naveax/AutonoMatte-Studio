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
$Payload = Join-Path $Root '.payload'
$Runtime = Join-Path $Root '.runtime'
$Wheel = Join-Path $Runtime 'autonomatte-0.6.1-py3-none-any.whl'
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

function Ensure-Wheel {
    if (Test-Path -LiteralPath $Wheel) { return }
    Write-Title 'Uygulama paketi hazırlanıyor'
    $parts = Get-ChildItem -LiteralPath $Payload -Filter 'wheel.part*.b64' | Sort-Object Name
    if ($parts.Count -eq 0) { throw 'Embedded application payload was not found.' }
    $encoded = ($parts | ForEach-Object { Get-Content -Raw -LiteralPath $_.FullName }) -join ''
    [IO.File]::WriteAllBytes($Wheel, [Convert]::FromBase64String($encoded))
}

function Install-CoreRuntime {
    Write-Title 'Temel bağımlılıklar kuruluyor'
    Invoke-Checked $Python @(
        '-m','pip','install',
        'numpy==1.26.4',
        'Pillow==11.3.0',
        'scipy==1.16.3',
        'fastapi>=0.115,<1',
        'uvicorn>=0.32,<1',
        'python-multipart>=0.0.12'
    )
    Invoke-Checked $Python @('-m','pip','install','--no-deps','--force-reinstall',$Wheel)
    Invoke-Checked $Python @('-m','pip','check')
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
    Ensure-Wheel

    $stamp = Join-Path $Runtime 'autonomatte-0.6.1.ready'
    if ((Test-Path $stamp) -and -not $Universal) { return }

    Install-CoreRuntime
    $gpu = Get-GpuMode
    Write-Title "Hızlandırma bağımlılıkları kuruluyor ($gpu)"
    if ($Universal) {
        try {
            Invoke-Checked $Python @('-m','pip','install','torch','torchvision','--index-url','https://download.pytorch.org/whl/cu128')
        } catch {
            Invoke-Checked $Python @('-m','pip','install','torch','torchvision')
        }
        Invoke-Checked $Python @('-m','pip','install','transformers>=4.49,<6','accelerate>=1.2','safetensors>=0.4','huggingface-hub>0.25','opencv-python>=4.10','timm>=1.0','scikit-image>=0.24','kornia>=0.8','einops>=0.8','tqdm>=4.67','prettytable>=3.12','rembg[cpu]>=2.0.67','pillow-heif>=0.18')
    } elseif ($gpu -eq 'nvidia') {
        try {
            Invoke-Checked $Python @('-m','pip','install','torch','torchvision','--index-url','https://download.pytorch.org/whl/cu128')
        } catch {
            Invoke-Checked $Python @('-m','pip','install','torch','torchvision')
        }
        Invoke-Checked $Python @('-m','pip','install','transformers>=4.49,<6','accelerate>=1.2','safetensors>=0.4','huggingface-hub>0.25','opencv-python>=4.10','timm>=1.0','scikit-image>=0.24','kornia>=0.8','einops>=0.8','tqdm>=4.67','prettytable>=3.12','rembg[gpu]>=2.0.67','pillow-heif>=0.18')
        try { Invoke-Checked $Python @('-m','pip','install','git+https://github.com/PramaLLC/BEN2.git') } catch { Write-Warning 'BEN2 kurulamadı; BiRefNet kullanılacak.' }
    } elseif ($gpu -eq 'amd') {
        Invoke-Checked $Python @('-m','pip','install','rembg[cpu]>=2.0.67','onnxruntime-directml>=1.20','pillow-heif>=0.18')
    } else {
        Invoke-Checked $Python @('-m','pip','install','rembg[cpu]>=2.0.67','pillow-heif>=0.18')
    }
    Invoke-Checked $Python @('-m','pip','check')
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
