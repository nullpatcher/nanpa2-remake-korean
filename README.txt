동급생2 리메이크 한글패치 v1.0
================================

설치 방법
---------
1. install.ps1 을 마우스 오른쪽 클릭 → "PowerShell로 실행"
   (또는 PowerShell 창을 열고 이 폴더에서 .\install.ps1 실행)
2. 게임 설치 경로를 자동으로 찾거나, 못 찾으면 직접 입력합니다.
3. 설치가 끝나면 nanpa2_k.exe로 게임을 실행하세요.
   (nanpa2_re.exe는 원본 그대로 남아있고 전혀 수정되지 않습니다.)

제거 방법
---------
uninstall.ps1 을 실행하면 원본 파일로 되돌리고 nanpa2_k.exe를 삭제합니다.

문제 해결
---------
- "이 시스템에서 스크립트 실행이 사용하지 않도록 설정되어 있으므로..."
  라는 오류가 나오면, PowerShell을 관리자 권한으로 열고 아래 명령을 한 번
  실행한 뒤 다시 시도하세요:
    Set-ExecutionPolicy -Scope CurrentUser RemoteSigned
- 이 파일이 .pat 확장자라 압축 프로그램이 안 열리면, 확장자를 .zip으로
  바꾼 뒤 열어주세요.

포함된 구성 요소
----------------
- xdelta3 (Apache License 2.0, https://github.com/jmacd/xdelta) --
  대사/이미지 패치 파일을 원본 게임 파일에 적용하는 데 사용됩니다.
  라이선스 전문은 tools/xdelta3-LICENSE.txt 참고.
