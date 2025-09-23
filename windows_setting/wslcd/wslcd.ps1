# WSL 바로가기 경로로 이동하는 PowerShell 스크립트
# (New-Object -ComObject Shell.Application).Namespace((Get-Location).Path).ParseName('src.lnk').GetLink.Pat

chcp 65001 | Out-Null
Write-Host "Moving to WSL shortcut path..." -ForegroundColor Green

$link_dir = "$env:USERPROFILE\Desktop"
$link_path = "src.lnk"

try {
    # PowerShell로 src.lnk의 대상 경로 획득
    $shell = New-Object -ComObject Shell.Application
    $folder = $shell.Namespace($link_dir)
    $item = $folder.ParseName($link_path)
    
    if ($item -eq $null) {
        throw "Cannot find src.lnk file."
    }
    
    $target_path = $item.GetLink.Path
    
    # 경로가 비어있는지 확인
    if ([string]::IsNullOrWhiteSpace($target_path)) {
        Write-Host "Error: Cannot find target path of src.lnk file." -ForegroundColor Red
        Write-Host "Please check if src.lnk exists in current directory." -ForegroundColor Red
        Read-Host "Press Enter to continue"
        exit 1
    }
    
    Write-Host "Target path: $target_path" -ForegroundColor Cyan
    
    # WSL 경로인지 확인 (\\wsl.localhost\로 시작하는지)
    <#
    if ($target_path -like "\\wsl.localhost\*") {
        Write-Host "WSL path detected. Moving in WSL terminal" -ForegroundColor Yellow
        
        # WSL Ubuntu가 실행 중인지 확인하고 시작
        Write-Host "WSL Ubuntu 시작 중..." -ForegroundColor Yellow
        try {
            wsl -d Ubuntu -e echo "WSL Ready" | Out-Null
        } catch {
            Write-Host "WSL Ubuntu Start Failed!" -ForegroundColor Red
        }
        
        # WSL 경로를 Linux 경로로 변환
        # \\wsl.localhost\Ubuntu\home\jhhwang\src -> /home/jhhwang/src
        $wsl_path = $target_path -replace "\\\\wsl\.localhost\\Ubuntu", "" -replace "\\", "/"
        
        Write-Host "Linux Path: $wsl_path" -ForegroundColor Cyan
        Write-Host "Move this directory in WSL Ubuntu terminal." -ForegroundColor Green
        Write-Host ""
        
        # WSL에서 해당 디렉토리로 이동하고 bash 실행
        wsl -d Ubuntu -e bash -c "cd '$wsl_path' && echo 'Current directory:' && pwd && exec bash"
        
    } else {
    #>
    
        Write-Host "Windows path detected. Moving in Windows command prompt." -ForegroundColor Yellow
        
        # 일반 Windows 경로라면 Push-Location 사용
        try {
            Push-Location -Path $target_path -ErrorAction Stop
            Write-Host "Successfully moved to: $target_path" -ForegroundColor Green
            Write-Host "PowerShell session maintained." -ForegroundColor Green
            
            # 새로운 PowerShell 세션을 해당 디렉토리에서 시작
            # Start-Process powershell -WorkingDirectory $target_path
            
        } catch {
            Write-Host "Error: Cannot move to path: $target_path" -ForegroundColor Red
            Write-Host "Error details: $($_.Exception.Message)" -ForegroundColor Red
            Read-Host "계속하려면 Enter를 누르세요"
            exit 1
        }
    
    <# } #>

} catch {
    Write-Host "Error occurred during script execution: $($_.Exception.Message)" -ForegroundColor Red
    Read-Host "Press Enter to continue"
    exit 1
} finally {
    # COM 객체 해제
    if ($shell) {
        [System.Runtime.Interopservices.Marshal]::ReleaseComObject($shell) | Out-Null
    }
}