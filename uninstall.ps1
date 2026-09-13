<#
    동급생2 리메이크 한글패치 v1.0 제거 프로그램

    install.ps1이 설치한 것(script.arc, layer.arc, nanpa2_k.exe)을 되돌립니다.
    game folder\backup\ 에 저장된 원본으로 script.arc / layer.arc를 복원하고,
    nanpa2_k.exe를 삭제합니다. nanpa2_re.exe(원본)는 애초에 건드리지 않았으므로
    복원할 필요가 없습니다.
#>
param(
    [string]$GamePath
)

$ErrorActionPreference = "Stop"
$InstallDir = $PSScriptRoot
$GamePathFile = Join-Path $InstallDir "game_path.txt"
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
    Write-Host " 동급생2 리메이크 한글패치 v1.0 제거 프로그램"
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

    $BackupDir = Join-Path $GamePath "backup"
    $PatchedExe = Join-Path $GamePath "nanpa2_k.exe"

    if (Test-Path $PatchedExe) {
        Remove-Item -Path $PatchedExe -Force
        Write-Host "  삭제:  nanpa2_k.exe"
    } else {
        Write-Host "  nanpa2_k.exe가 없습니다 (이미 제거됐거나 설치한 적이 없음)."
    }

    foreach ($name in @("script.arc", "layer.arc")) {
        $backupFile = Join-Path $BackupDir $name
        if (-not (Test-Path $backupFile)) {
            Write-Host "  백업된 $name 이 없습니다 -- 건너뜁니다."
            continue
        }
        $target = Join-Path $GamePath $name
        Copy-Item -Path $backupFile -Destination $target -Force
        Write-Host "  복원:  $name"
    }

    Write-Host ""
    Write-Host "제거 완료. 게임 경로: $GamePath"
} catch {
    Write-Host ""
    Write-Host "오류가 발생했습니다: $_" -ForegroundColor Red
} finally {
    Wait-ForKeyPress
}
