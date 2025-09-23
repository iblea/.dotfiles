@echo off
chcp 65001 >nul 2>&1
setlocal enabledelayedexpansion

echo WSL 바로가기 경로로 이동 중...

set "link_dir=%USERPROFILE%\Desktop"
set "link_file=src.lnk"

REM PowerShell로 src.lnk의 대상 경로 획득
REM for /f "delims=" %%i in ('powershell -Command "(New-Object -ComObject Shell.Application).Namespace((Get-Location).Path).ParseName('src.lnk').GetLink.Path"') do (

for /f "delims=" %%i in ('powershell -Command "(New-Object -ComObject Shell.Application).Namespace('%link_dir%').ParseName('%link_file%').GetLink.Path"') do (
    set "target_path=%%i"
)

REM 경로가 비어있는지 확인
if "!target_path!"=="" (
    echo 에러: src.lnk 파일의 대상 경로를 찾을 수 없습니다.
    echo src.lnk 파일이 현재 디렉토리에 있는지 확인해주세요.
    pause
    exit /b 1
)

echo 대상 경로: !target_path!

REM WSL 경로인지 확인 (\\wsl.localhost\로 시작하는지)
REM echo !target_path! | findstr /C:"\\wsl.localhost\" >nul
REM if !errorlevel! equ 0 (
REM     echo WSL 경로 감지됨. WSL Ubuntu로 이동합니다.
REM     
REM     REM WSL Ubuntu가 실행 중인지 확인하고 시작
REM     echo WSL Ubuntu 시작 중...
REM     wsl -d Ubuntu -e echo "WSL Ready" >nul 2>&1
REM     
REM     REM WSL 경로를 Linux 경로로 변환
REM     REM \\wsl.localhost\Ubuntu\home\jhhwang\src -> /home/jhhwang/src
REM     set "wsl_path=!target_path!"
REM     set "wsl_path=!wsl_path:\\wsl.localhost\Ubuntu=!"
REM     set "wsl_path=!wsl_path:\=/!"
REM     
REM     echo Linux 경로: !wsl_path!
REM     echo WSL Ubuntu 터미널에서 해당 디렉토리로 이동합니다.
REM     echo.
REM     
REM     REM WSL에서 해당 디렉토리로 이동하고 bash 실행
REM     wsl -d Ubuntu -e bash -c "cd '!wsl_path!' && echo 'Current directory:' && pwd && exec bash"
REM     
REM ) else (

    echo Windows 경로 감지됨. Windows 명령창에서 이동합니다.
    
    REM 일반 Windows 경로라면 pushd 사용
    pushd "!target_path!"
    if !errorlevel! equ 0 (
        echo 성공적으로 이동했습니다: !target_path!
        echo Windows 명령창을 유지합니다.
        cmd /k
    ) else (
        echo 에러: 해당 경로로 이동할 수 없습니다: !target_path!
        pause
        exit /b 1
    )

REM )

endlocal