
# change username_windows to custom_user
# vim $PROFILE
function jcd {
    Set-Location "C:\Users\username_windows"
    Write-Host "cd: $(Get-Location)" -ForegroundColor Cyan
}

function ll { Get-ChildItem }
function clear { Clear-Host }
function cc { Clear-Host }
function vi { vim.exe @args }
function home { Set-Location "$HOME" }

