﻿#import MicrosoftDeploymentToolkit.psd1
Write-Host -ForegroundColor Green -BackgroundColor black "importing MicrosoftDeploymentToolkit.psd1..."
Start-Sleep -Seconds 5
Import-Module "C:\Program Files\Microsoft Deployment Toolkit\bin\MicrosoftDeploymentToolkit.psd1"
#Create choco folder under applications in MDT
Write-Host -ForegroundColor Green -BackgroundColor black "Creating choco folder under applications in MDT"
Start-Sleep -Seconds 5
new-item -path "DS001:\Applications" -enable "True" -Name "Choco" -Comments "" -ItemType "folder" -Verbose
#import app list from apps.txt *muser be located in the same folder as this script*
Write-Host -ForegroundColor Green -BackgroundColor black "importing app list from apps.txt into MDT"
Start-Sleep -Seconds 5
$Apps = Get-Content -Path .\apps.txt
#add apps from apps.txt to MDT
ForEach($Apps In $Apps)
{
import-MDTApplication -path "DS001:\Applications\Choco" -enable "True" -Name "$Apps" -ShortName "$Apps" -Version "" -Publisher "" -Language "" -CommandLine "powershell.exe choco install $Apps -Y --Force" -WorkingDirectory "" -NoSource -Verbose
}
pause