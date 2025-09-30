
chcp 65001 | Out-Null
# 1. Move Directory to mouse_jiggler.exe
Set-Location -Path "C:\MouseJiggler_portable"

# 2. already running process die
while (Get-Process -Name "MouseJiggler" -ErrorAction SilentlyContinue) {
    Stop-Process -Name "MouseJiggler" -Force -ErrorAction SilentlyContinue
    Start-Sleep -Milliseconds 500  # 프로세스 종료 대기
}

# 3. execute MouseJiggler
.\MouseJiggler.exe -j -m -s 60


# print process
Get-Process -Name "MouseJiggler" -ErrorAction SilentlyContinue

echo 'done'

