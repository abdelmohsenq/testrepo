Install-WindowsFeature -name Web-Server -IncludeManagementTools

Install-WindowsFeature Web-Asp-Net45

Invoke-WebRequest https://download.visualstudio.microsoft.com/download/pr/0e1818d5-9aae-49fa-8085-8e933a470a23/b95543b4ad23cbe1e6981f6efff9272c/dotnet-sdk-3.1.113-win-x64.exe -outfile $env:temp\dotnet-dev-win-x64.exe
Start-Process $env:temp\dotnet-dev-win-x64.exe -ArgumentList '/quiet' -Wait

Invoke-WebRequest https://download.visualstudio.microsoft.com/download/pr/0f60f951-edec-48a1-aaa1-2f5b5bcbb704/e205315e03bb9f4ac0a6a7efd5d89178/dotnet-hosting-3.1.13-win.exe -outfile $env:temp\DotNetCore.WindowsHosting.exe
Start-Process $env:temp\DotNetCore.WindowsHosting.exe -ArgumentList '/quiet' -Wait

Install-WindowsFeature NET-Framework-Features

Remove-Item -Recurse C:\inetpub\wwwroot\*

Install-WindowsFeature -Name Web-Mgmt-Service
Set-ItemProperty -Path  HKLM:\SOFTWARE\Microsoft\WebManagement\Server -Name EnableRemoteManagement -Value 1
Set-Service -name WMSVC -StartupType Automatic
if ((Get-Service WMSVC).Status -ne "Running") {
    net start wmsvc
}

$msiFile = [System.IO.Path]::GetTempFileName() | Rename-Item -NewName { $_ -replace 'tmp$', 'msi' } -PassThru
Invoke-WebRequest -Uri http://download.microsoft.com/download/0/1/D/01DC28EA-638C-4A22-A57B-4CEF97755C6C/WebDeploy_amd64_en-US.msi -OutFile $msiFile
$logFile = [System.IO.Path]::GetTempFileName()
$arguments= '/i ' + $msiFile + ' ADDLOCAL=ALL /qn /norestart LicenseAccepted="0" /lv ' + $logFile
$proc = (Start-Process -file msiexec -arg $arguments -Passthru)
$proc | Wait-Process
Get-Content $logFile

Stop-Service was -Force
Start-Service w3svc