@echo off
set uaccheck=0
:CheckUAC
>nul 2>&1 "%SYSTEMROOT%\system32\cacls.exe" "%SYSTEMROOT%\system32\config\system"
if '%errorlevel%' NEQ '0' (
    goto UACAccess
) else ( goto Done )

:UACAccess
echo "Request to get admin permission"
echo Set UAC = CreateObject^("Shell.Application"^) > "%temp%\uac_get_admin.vbs"
set params = %*:"=""
echo UAC.ShellExecute "cmd.exe", "/c %~s0 %params%", "", "runas", 1 >> "%temp%\uac_get_admin.vbs"
"%temp%\uac_get_admin.vbs"
del "%temp%\uac_get_admin.vbs"
exit /b

:Done
echo "Success to get admin permission"
echo.

REM powershell.exe "$env:APPDATA\..\wsl_connect.ps1"
if exist "%APPDATA%\..\wsl_connect.ps1" (
powershell.exe "%APPDATA%\..\wsl_connect.ps1"
powershell.exe "Start-Service sshd"

"C:\Windows\System32\bash.exe" -c "sudo service ssh start"
"C:\Windows\System32\bash.exe" -c "sudo service nginx start"
"C:\Windows\System32\bash.exe" -c "sudo service php7.2-fpm start"
) else (
echo "not found wsl_connect.ps1 script"
)

REM windows defender off
if exist "%homepath%\defender_disable.reg" (
regedit.exe /S %homepath%\defender_disable.reg
) else (
echo "not found defender_disable.reg"
)


exit /b