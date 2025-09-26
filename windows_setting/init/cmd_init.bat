@echo off
REM change username_windows to custom_user
REM REG ADD "HKCU\Software\Microsoft\Command Processor" /v AutoRun /t REG_SZ /d "C:\Users\username_windows\cmd_init.bat" /f
REM chcp 65001 >nul 2>&1

doskey jcd=cd /d "C:\Users\username_windows"

doskey ll=dir /w $*
doskey clear=cls
doskey cc=cls
doskey vi=vim.exe
doskey home=cd /d "%USERPROFILE%"