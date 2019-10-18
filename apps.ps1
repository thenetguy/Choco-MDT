Import-Module "C:\Program Files\Microsoft Deployment Toolkit\bin\MicrosoftDeploymentToolkit.psd1"
New-PSDrive -Name "DS001" -PSProvider MDTProvider -Root "C:\DeploymentShare"
new-item -path "DS001:\Applications" -enable "True" -Name "Choco" -Comments "" -ItemType "folder" -Verbose

$Apps = Get-Content -Path .\apps.txt

ForEach($Apps In $Apps)

{
import-MDTApplication -path "DS001:\Applications\Choco" -enable "True" -Name "$Apps" -ShortName "$Apps" -Version "" -Publisher "" -Language "" -CommandLine "powershell.exe choco install $Apps -Y --Force" -WorkingDirectory "" -NoSource -Verbose
}

pause