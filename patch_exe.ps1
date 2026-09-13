# nanpa2_k.exe 바이트 패치 적용 (순수 PowerShell, Python 불필요).
# patch_data.ps1(scripts/gen_ps_patch_table.py로 자동 생성됨)의 $AllPatches를 그대로 적용한다.
# Python판 patches/patch_nanpa2.py의 apply_patch()와 동일한 안전 규칙:
# 패치 전 원본 바이트가 예상과 다르면 즉시 중단(다른 버전의 exe이거나 이미 패치된 파일).

function ConvertFrom-HexString {
    param([string]$Hex)
    if ($Hex.Length % 2 -ne 0) { throw "홀수 길이 hex 문자열: $Hex" }
    $bytes = New-Object byte[] ($Hex.Length / 2)
    for ($i = 0; $i -lt $bytes.Length; $i++) {
        $bytes[$i] = [Convert]::ToByte($Hex.Substring($i * 2, 2), 16)
    }
    return $bytes
}

function Invoke-ExePatch {
    param(
        [Parameter(Mandatory)][string]$TargetPath
    )

    $dataScript = Join-Path $PSScriptRoot "patch_data.ps1"
    if (-not (Test-Path $dataScript)) {
        throw "패치 데이터 파일이 없습니다: $dataScript"
    }
    . $dataScript

    $bytes = [System.IO.File]::ReadAllBytes($TargetPath)

    $applied = 0
    foreach ($patch in $AllPatches) {
        $orig = ConvertFrom-HexString $patch.Orig
        $new = ConvertFrom-HexString $patch.New
        $offset = $patch.Offset

        if ($offset + $orig.Length -gt $bytes.Length) {
            throw "패치 범위가 파일 크기를 벗어남 (label=$($patch.Label), offset=$offset) -- 다른 버전의 exe일 수 있습니다."
        }

        for ($i = 0; $i -lt $orig.Length; $i++) {
            if ($bytes[$offset + $i] -ne $orig[$i]) {
                $actualHex = ([BitConverter]::ToString($bytes[$offset..($offset + $orig.Length - 1)])) -replace '-', ''
                throw "패치 검증 실패 (label=$($patch.Label), offset=0x$($offset.ToString('X')))`n예상: $($patch.Orig)`n실제: $actualHex`n다른 버전의 exe이거나 이미 패치된 파일일 수 있습니다."
            }
        }

        for ($i = 0; $i -lt $new.Length; $i++) {
            $bytes[$offset + $i] = $new[$i]
        }
        $applied++
    }

    [System.IO.File]::WriteAllBytes($TargetPath, $bytes)
    return $applied
}
