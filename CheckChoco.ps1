Write-Host -ForegroundColor Green -BackgroundColor black "checking if C:\ProgramData\chocolatey\choco.exe is installed"
Start-Sleep -Seconds 5
$Checkchoco= Test-Path C:\ProgramData\chocolatey\choco.exe
if ($Checkchoco)
{
Write-Host -ForegroundColor yellow -BackgroundColor black "Choco is already installed. exiting..."
Start-Sleep -Seconds 5
exit
}  
else
{
Write-Host -ForegroundColor Green -BackgroundColor black "Choco is not installed, Installing Choco..."
Start-Sleep -Seconds 5
Set-ExecutionPolicy Bypass -Scope Process -Force; iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))

Write-Host -ForegroundColor Green -BackgroundColor black "Choco Has been installed on this system. exiting"
Start-Sleep -Seconds 10
}
