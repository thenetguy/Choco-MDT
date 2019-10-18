$AppsFolder="Choco"

$DeploymentPSDrive= "DS001:"

#Check if Microsoft Deployment Toolkit is installed
Write-Host -ForegroundColor Green -BackgroundColor Black "Checking if Microsoft Deployment Toolkit is installed ..."
Start-Sleep -Seconds 5
$CheckMDT= Test-Path "C:\Program Files\Microsoft Deployment Toolkit\bin\MicrosoftDeploymentToolkit.psd1"
if ($CheckMDT)
{
Write-Host -ForegroundColor Green -BackgroundColor Black "Microsoft Deployment Toolkitmust is installed, lets continue"
Start-Sleep -Seconds 5
}  
else
{
Write-Host -ForegroundColor Red -BackgroundColor Black "Microsoft Deployment Toolkit must be installed before running this script. Please install MDT and run this script again"
exit
}
$CheckDS= Test-Path "$DeploymentPSDrive"
if ($CheckDS)
{
Write-Host -ForegroundColor Green -BackgroundColor Black "MDT Deploymentshare $DeploymentPSDrive is present, lets continue"
Start-Sleep -Seconds 5
}  
else
{
Write-Host -ForegroundColor Red -BackgroundColor Black "Deploymentshare $DeploymentPSDrive is not found. Please create the Deploymentshare then run this script again"
exit
}
#import MicrosoftDeploymentToolkit.psd1
Write-Host -ForegroundColor Green -BackgroundColor Black "Importing MicrosoftDeploymentToolkit.psd1"
Start-Sleep -Seconds 5
Import-Module "C:\Program Files\Microsoft Deployment Toolkit\bin\MicrosoftDeploymentToolkit.psd1"
#Create choco folder under applications in MDT
Write-Host -ForegroundColor Green -BackgroundColor Black "Creating $AppsFolder folder under Applications in MDT"
Start-Sleep -Seconds 5
New-Item -path "$DeploymentPSDrive/Applications" -enable "True" -Name "$AppsFolder" -Comments "" -ItemType "folder" -Verbose
#Import app list from apps.txt *muser be located in the same folder as this script*
Write-Host -ForegroundColor Green -BackgroundColor Black "Importing app list from apps.txt into MDT"
Start-Sleep -Seconds 5
$Apps = Get-Content -Path .\apps.txt
#add apps from apps.txt to MDT
ForEach($Apps In $Apps)
{
import-MDTApplication -path "DS001:\Applications\Choco" -enable "True" -Name "$Apps" -ShortName "$Apps" -Version "" -Publisher "" -Language "" -CommandLine "powershell.exe choco install $Apps -Y --Force" -WorkingDirectory "" -NoSource -Verbose
}
Start-Sleep -Seconds 5