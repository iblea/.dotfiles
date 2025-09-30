
chcp 65001 | Out-Null
# 1. Move Directory to mouse_jiggler.exe
Set-Location -Path "C:\MouseJiggler_portable"

# 2. already running process die
while (Get-Process -Name "MouseJiggler" -ErrorAction SilentlyContinue) {
    Stop-Process -Name "MouseJiggler" -Force -ErrorAction SilentlyContinue
    Start-Sleep -Milliseconds 500  # 프로세스 종료 대기
}

# 3. execute MouseJiggler

echo "Start Mouse Jiggler.exe..."
Start-Sleep 3
# Start-Job -ScriptBlock {

Start-Process cmd -ArgumentList "/c start """" "".\MouseJiggler.exe"" -j -m True -z False -s 60" -WindowStyle Hidden

# Start-Process -FilePath ".\MouseJiggler.exe" `
#     -ArgumentList "-j", "-m", "True", "-z", "False", "-s", "60" `
#     -WorkingDirectory (Get-Location)

#     -WindowStyle Hidden

# }

echo "daemon starter"

# print process
Get-Process -Name "MouseJiggler" -ErrorAction SilentlyContinue

echo ''
echo 'Run Jiggler'

