# Install IIS (with Management Console)
Install-WindowsFeature -name Web-Server -IncludeManagementTools

# Install ASP.NET 4.6
Install-WindowsFeature Web-Asp-Net45

# ADDED:
Install-WindowsFeature NET-Framework-Features # Not needed

# ADDED: Install the .NET Core SDK
$dotnetSdkFile = [System.IO.Path]::GetTempFileName() | Rename-Item -NewName { $_ -replace 'tmp$', 'exe' } -PassThru
Invoke-WebRequest -Uri https://download.visualstudio.microsoft.com/download/pr/0e1818d5-9aae-49fa-8085-8e933a470a23/b95543b4ad23cbe1e6981f6efff9272c/dotnet-sdk-3.1.113-win-x64.exe -OutFile $dotnetSdkFile
Start-Process $dotnetSdkFile -ArgumentList '/quiet' -Wait

# ADDED: Install the .NET Core Windows Server Hosting bundle
$dotnethostingFile = [System.IO.Path]::GetTempFileName() | Rename-Item -NewName { $_ -replace 'tmp$', 'exe' } -PassThru
Invoke-WebRequest -Uri https://download.visualstudio.microsoft.com/download/pr/0f60f951-edec-48a1-aaa1-2f5b5bcbb704/e205315e03bb9f4ac0a6a7efd5d89178/dotnet-hosting-3.1.13-win.exe -OutFile $dotnethostingFile
Start-Process $dotnethostingFile -ArgumentList '/quiet' -Wait

# ADDED: Install the .NET Core runtime
$dotnetruntimeFile = [System.IO.Path]::GetTempFileName() | Rename-Item -NewName { $_ -replace 'tmp$', 'exe' } -PassThru
Invoke-WebRequest -Uri https://download.visualstudio.microsoft.com/download/pr/aa717f57-3ae5-48fa-a3ab-0018338d0726/fb37276b1575772461701339110e7a54/windowsdesktop-runtime-3.1.13-win-x64.exe -OutFile $dotnetruntimeFile
Start-Process $dotnetruntimeFile -ArgumentList '/quiet' -Wait

# Delete contents of wwwroot
Remove-Item -Recurse C:\inetpub\wwwroot\*

# Install Web Management Service (enable and start service)
Install-WindowsFeature -Name Web-Mgmt-Service
Set-ItemProperty -Path  HKLM:\SOFTWARE\Microsoft\WebManagement\Server -Name EnableRemoteManagement -Value 1
Set-Service -name WMSVC -StartupType Automatic
if ((Get-Service WMSVC).Status -ne "Running") {
    net start wmsvc
}

# Install Web Deploy 3.6
# Download file from Microsoft Downloads and save to local temp file (%LocalAppData%/Temp/2)
$msiFile = [System.IO.Path]::GetTempFileName() | Rename-Item -NewName { $_ -replace 'tmp$', 'msi' } -PassThru
Invoke-WebRequest -Uri http://download.microsoft.com/download/0/1/D/01DC28EA-638C-4A22-A57B-4CEF97755C6C/WebDeploy_amd64_en-US.msi -OutFile $msiFile
# Prepare a log file name
$logFile = [System.IO.Path]::GetTempFileName()
# Prepare the arguments to execute the MSI
$arguments= '/i ' + $msiFile + ' ADDLOCAL=ALL /qn /norestart LicenseAccepted="0" /lv ' + $logFile
# Sample = msiexec /i C:\Users\{user}\AppData\Local\Temp\2\tmp9267.msi ADDLOCAL=ALL /qn /norestart LicenseAccepted="0" /lv $logFile
# Execute the MSI and wait for it to complete
$proc = (Start-Process -file msiexec -arg $arguments -Passthru)
$proc | Wait-Process
Get-Content $logFile

# ADDED: Restart the web server so that system PATH updates take effect
Stop-Service was -Force
Start-Service w3svc
