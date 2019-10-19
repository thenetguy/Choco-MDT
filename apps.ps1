#################### Start User Editable section ####################
# Change $Appfolder to whatever folder Name you want apps to be installed in MDT under Applications
$AppsFolderName  = "Choco"
$Deploymentshare = "C:\DeploymentShare"
#################### End User Editable section ######################
#
#
#
#
#Check if Microsoft Deployment Toolkit is installed

Write-Host -ForegroundColor Green -BackgroundColor Black "Checking if Microsoft Deployment Toolkit is installed ..."
Start-Sleep -Seconds 5
$CheckMDT = Test-Path "C:\Program Files\Microsoft Deployment Toolkit\bin\MicrosoftDeploymentToolkit.psd1"
if ($CheckMDT) {
    Write-Host -ForegroundColor Green -BackgroundColor Black "Microsoft Deployment Toolkit is installed, lets continue"
    Start-Sleep -Seconds 5
}  
else {
    Write-Host -ForegroundColor Red -BackgroundColor Black "Microsoft Deployment Toolkit must be installed before running this script. Please install MDT and run this script again"
    exit
}

#Check if Apps.txt is located in the same folder

Write-Host -ForegroundColor Green -BackgroundColor Black "Checking if Apps.txt is located in the same folder..."
Start-Sleep -Seconds 5
$CheckApps = Test-Path ".\apps.txt"
if ($CheckApps) {
    Write-Host -ForegroundColor Green -BackgroundColor Black "Apps.txt is found. Lets continue"
    Start-Sleep -Seconds 5
}  
else {
    Write-Host -ForegroundColor Red -BackgroundColor Black "Unable to find apps.txt in the same folder as this script. make sure apps.txt is located in the same folder as this script."
    Start-Sleep -Seconds 5
    exit
}

#import MicrosoftDeploymentToolkit.psd1

Write-Host -ForegroundColor Green -BackgroundColor Black "Importing MicrosoftDeploymentToolkit.psd1"
Start-Sleep -Seconds 5
Import-Module "C:\Program Files\Microsoft Deployment Toolkit\bin\MicrosoftDeploymentToolkit.psd1"

#Create $AppsFolder folder under applications in MDT

Write-Host -ForegroundColor Green -BackgroundColor Black "Creating $AppsFolderName folder under Applications in MDT"
Start-Sleep -Seconds 5
New-PSDrive -Name "DS001" -PSProvider MDTProvider -Root "$Deploymentshare"
New-Item -path "DS001:/Applications" -enable "True" -Name "$AppsFolderName" -Comments "" -ItemType "folder" -Verbose

#Import app list from apps.txt *must be located in the same folder as this script*
Write-Host -ForegroundColor Green -BackgroundColor Black "Importing app list from apps.txt into MDT"
Start-Sleep -Seconds 5
$Apps = Get-Content -Path .\apps.txt

#add apps from apps.txt to MDT

ForEach ($Apps In $Apps) {
    import-MDTApplication -path "DS001:\Applications\$AppsFolderName" -enable "True" -Name "$Apps" -ShortName "$Apps" -Version "" -Publisher "" -Language "" -CommandLine "powershell.exe choco install $Apps -Y --Force" -WorkingDirectory "" -NoSource -Verbose
}


Start-Sleep -Seconds 15
