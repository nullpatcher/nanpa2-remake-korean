<#
    동급생2 리메이크 한글패치 v1.0 설치 프로그램

    원본 게임 파일(nanpa2_re.exe, script.arc, layer.arc)은 전혀 수정하지 않습니다.
    - script.arc / layer.arc: 원본을 game folder\backup\ 에 백업해두고, 패치를
      적용한 새 파일로 교체합니다.
    - nanpa2_re.exe: 건드리지 않고, 그대로 복사한 nanpa2_k.exe를 새로 만들어
      거기에만 한글 패치를 적용합니다. 게임은 nanpa2_k.exe로 실행하세요.
#>
param(
    [string]$GamePath
)

$ErrorActionPreference = "Stop"
$Version = "v1.0"
$InstallDir = $PSScriptRoot
$GamePathFile = Join-Path $InstallDir "game_path.txt"
$XdeltaExe = Join-Path $InstallDir "tools\xdelta3.exe"

$DefaultGamePath = "D:\Games\FGRemake\nanpa2_re"

function Test-GameDir($path) {
    return ($path -and (Test-Path $path) -and (Test-Path (Join-Path $path "nanpa2_re.exe")))
}

function Find-GamePath {
    if (Test-GameDir $DefaultGamePath) { return $DefaultGamePath }

    $regRoots = @(
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
        "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*",
        "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*"
    )
    foreach ($root in $regRoots) {
        $entries = Get-ItemProperty $root -ErrorAction SilentlyContinue
        foreach ($e in $entries) {
            if ($e.DisplayName -and ($e.DisplayName -match "同級生2" -or $e.DisplayName -match "nanpa2" -or
                                      $e.DisplayName -match "동급생\s*2" -or $e.DisplayName -match "FG\s*REMAKE")) {
                if (Test-GameDir $e.InstallLocation) { return $e.InstallLocation }
            }
        }
    }

    foreach ($drive in (Get-PSDrive -PSProvider FileSystem -ErrorAction SilentlyContinue)) {
        foreach ($parent in @("Games", "Program Files", "Program Files (x86)", "")) {
            $p = if ($parent) { Join-Path $drive.Root $parent } else { $drive.Root }
            if (-not (Test-Path $p)) { continue }
            $dirs = Get-ChildItem $p -Directory -ErrorAction SilentlyContinue |
                Where-Object { $_.Name -match "nanpa2" -or $_.Name -match "FGRemake" -or $_.Name -match "同級生" }
            foreach ($d in $dirs) {
                if (Test-GameDir $d.FullName) { return $d.FullName }
                $subdirs = Get-ChildItem $d.FullName -Directory -ErrorAction SilentlyContinue
                foreach ($sd in $subdirs) {
                    if (Test-GameDir $sd.FullName) { return $sd.FullName }
                }
            }
        }
    }
    return $null
}

function Backup-Original($GamePath, $relName) {
    # backup\<file>은 항상 "패치를 한 번도 안 댄 순수 원본"이어야 한다 -- 이후 버전
    # 업그레이드 때 diff를 이 원본 기준으로 다시 적용하기 위한 고정점이다. 이미
    # backup이 있다면(예전 버전이 설치돼 있던 상태) 그건 이미 원본이므로 절대
    # 덮어쓰지 않는다. 처음 설치하는 경우에만 지금 게임 폴더에 있는 파일을
    # 원본으로 간주해서 백업한다.
    $target = Join-Path $GamePath $relName
    $backupDir = Join-Path $GamePath "backup"
    $backupTarget = Join-Path $backupDir $relName
    if (-not (Test-Path $backupTarget)) {
        if (-not (Test-Path $target)) {
            throw "게임 폴더에 $relName 파일이 없습니다. 게임 설치 상태를 확인해주세요."
        }
        if (-not (Test-Path $backupDir)) {
            New-Item -ItemType Directory -Force -Path $backupDir | Out-Null
        }
        Copy-Item -Path $target -Destination $backupTarget
    }
    return @{ Target = $target; Backup = $backupTarget }
}

function Invoke-ArcPatch($GamePath, $relName, $diffRelPath) {
    Write-Host "  $relName 패치 중... (용량이 커서 시간이 걸릴 수 있습니다)"
    $paths = Backup-Original $GamePath $relName
    $diffFile = Join-Path $InstallDir $diffRelPath
    $tempOut = Join-Path $env:TEMP "$relName.patching"

    # 항상 backup(원본)을 기준으로 diff를 적용한다 -- 이전 버전 패치가 이미
    # 설치돼 있어도(게임 폴더의 파일 자체는 원본이 아닐 수 있음) 상관없이,
    # 새 인스톨러를 그냥 다시 실행하기만 하면 버전 업그레이드가 된다
    # (언인스톨 후 재설치할 필요 없음).
    & $XdeltaExe -f -d -s $paths.Backup $diffFile $tempOut
    if ($LASTEXITCODE -ne 0) {
        throw "$relName 패치에 실패했습니다 (xdelta3 종료 코드 $LASTEXITCODE). 게임 파일이 원본과 다를 수 있습니다."
    }

    Move-Item -Path $tempOut -Destination $paths.Target -Force
    Write-Host "  $relName 패치 완료"
}

function Wait-ForKeyPress {
    Write-Host ""
    Write-Host "아무 키나 누르면 창을 닫습니다..."
    try {
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    } catch {
        Read-Host | Out-Null
    }
}

try {
    Write-Host "==============================================="
    Write-Host " 동급생2 리메이크 한글패치 $Version 설치 프로그램"
    Write-Host "==============================================="
    Write-Host ""

    if (-not $GamePath -and (Test-Path $GamePathFile)) {
        $GamePath = (Get-Content $GamePathFile -Raw).Trim()
    }

    if (-not (Test-GameDir $GamePath)) {
        Write-Host "게임 설치 경로를 찾는 중..."
        $auto = Find-GamePath
        if ($auto) {
            $GamePath = $auto
        } else {
            $GamePath = Read-Host "게임 설치 경로를 자동으로 찾지 못했습니다. 직접 입력해주세요 (nanpa2_re.exe가 있는 폴더)"
        }
    }

    if (-not (Test-GameDir $GamePath)) {
        throw "유효한 게임 경로가 아닙니다 (nanpa2_re.exe를 찾을 수 없음): $GamePath"
    }

    Set-Content -Path $GamePathFile -Value $GamePath -NoNewline
    Write-Host "게임 경로: $GamePath"

    $VersionFile = Join-Path $GamePath "backup\patch_version.txt"
    if (Test-Path $VersionFile) {
        $prevVersion = (Get-Content $VersionFile -Raw).Trim()
        Write-Host "기존 설치된 버전: $prevVersion -> $Version 로 업그레이드합니다."
    }
    Write-Host ""

    Write-Host "[1/3] 대사(script.arc) 패치"
    Invoke-ArcPatch $GamePath "script.arc" "diffs\script.arc.vcdiff"
    Write-Host ""

    Write-Host "[2/3] 이미지 속 텍스트(layer.arc) 패치"
    Invoke-ArcPatch $GamePath "layer.arc" "diffs\layer.arc.vcdiff"
    Write-Host ""

    Write-Host "[3/3] 실행 파일(nanpa2_k.exe) 생성"
    $sourceExe = Join-Path $GamePath "nanpa2_re.exe"
    $patchedExe = Join-Path $GamePath "nanpa2_k.exe"

    try {
        Copy-Item -Path $sourceExe -Destination $patchedExe -Force
    } catch {
        throw "nanpa2_k.exe를 만들 수 없습니다 (파일이 사용 중일 수 있습니다). 게임을 완전히 종료한 뒤 다시 시도해주세요."
    }

    . (Join-Path $InstallDir "patch_exe.ps1")
    $count = Invoke-ExePatch -TargetPath $patchedExe
    Write-Host "  nanpa2_k.exe 생성 완료 ($count 개 패치 적용)"
    Write-Host ""

    Set-Content -Path $VersionFile -Value $Version -NoNewline

    Write-Host "==============================================="
    Write-Host " 설치 완료!"
    Write-Host "==============================================="
    Write-Host " 게임은 nanpa2_k.exe로 실행해주세요."
    Write-Host " (nanpa2_re.exe는 원본 그대로 남아있습니다)"
    Write-Host " 되돌리려면 uninstall.ps1을 실행하세요."
} catch {
    Write-Host ""
    Write-Host "오류가 발생했습니다: $_" -ForegroundColor Red
} finally {
    Wait-ForKeyPress
}
