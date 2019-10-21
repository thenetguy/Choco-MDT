
#################### Start User Editable section ####################
# Change $AppsFolderName  to whatever folder name you want Chocolatey Apps to be installed in MDT under Applications
# Change $Deploymentshare to match your MDT Deployment Share location

$AppsFolderName  = "Chocolatey Apps"
$Deploymentshare = "C:\DeploymentShare"

#################### End User Editable section ######################
#
#
#
#Requires -RunAsAdministrator
#################Check if Microsoft Deployment Toolkit is installed ################

Write-Host -ForegroundColor Yellow -BackgroundColor Black "Checking if Microsoft Deployment Toolkit is installed ..."
Start-Sleep -Seconds 1
$CheckMDT = Get-WmiObject -Query "SELECT * FROM Win32_Product Where Name Like '%Microsoft Deployment Toolkit%'"
if ($CheckMDT) {
    Write-Host -ForegroundColor Green -BackgroundColor Black "Microsoft Deployment Toolkit is installed, lets continue"
    Start-Sleep -Seconds 1
}  
else {
    Write-Host -ForegroundColor Red -BackgroundColor Black "Microsoft Deployment Toolkit must be installed before running this script. Please install MDT and run this script again"
    Start-Sleep -Seconds 10
    exit
}


################ Check Windows Assessment and Deployment Kit is installed ################

Write-Host -ForegroundColor Yellow -BackgroundColor Black "Checking if Windows Assessment and Deployment Kit is installed..."
$CheckADK = Get-WmiObject -Query "SELECT * FROM Win32_Product Where Name Like '%Windows Deployment Tools%'"
if ($CheckADK) {
    Write-Host -ForegroundColor Green -BackgroundColor Black "Windows Assessment and Deployment Kit is installed, lets continue"
    Start-Sleep -Seconds 1
}  
else {
    Write-Host -ForegroundColor Red -BackgroundColor Black "Windows Assessment and Deployment Kit must be installed before running this script. Please install MDT and run this script again"
    Start-Sleep -Seconds 10
    exit
}


################# Import Microsoft Deployment Toolkit PowerShell Module ################

Write-Host -ForegroundColor Green -BackgroundColor Black "Importing Microsoft Deployment Toolkit PowerShell Module"
Start-Sleep -Seconds 1
Import-Module "C:\Program Files\Microsoft Deployment Toolkit\bin\MicrosoftDeploymentToolkit.psd1"


################## Check if Apps.csv is located in the same folder #################

Write-Host -ForegroundColor Yellow -BackgroundColor Black "Checking if Apps.csv is located in the same folder..."
Start-Sleep -Seconds 0
$CheckApps = Test-Path ".\apps.csv"
if ($CheckApps) {
    Write-Host -ForegroundColor Green -BackgroundColor Black "Apps.csv is found. Lets continue"
    Start-Sleep -Seconds 0
}  
else {
    Write-Host -ForegroundColor Red -BackgroundColor Black "Unable to find apps.csv in the same folder as this script. make sure apps.CSV is located in the same folder as this script and run this script again"
    Start-Sleep -Seconds 10
    exit
}


################### Import app list from apps.csv ##################

Write-Host -ForegroundColor Green -BackgroundColor Black "Importing app list from apps.csv into MDT"
Start-Sleep -Seconds 1
$apps = Import-Csv .\apps.csv

################### Create $AppsFolderName folder under applications in MDT ##################

    Write-Host -ForegroundColor Green -BackgroundColor Black "Creating $AppsFolderName folder under Applications in MDT"
    Start-Sleep -Seconds 1
    New-PSDrive -Name "DS001" -PSProvider MDTProvider -Root "$Deploymentshare"
    New-Item -path "DS001:/Applications" -enable "True" -Name "$AppsFolderName" -Comments "" -ItemType "folder" -Verbose

################### Importing Chocolatey Apps from Apps.csv to MDT ################### 

ForEach ($Apps In $Apps) {
    import-MDTApplication -path "DS001:\Applications\$AppsFolderName" -enable "True" -Name $Apps.Name -ShortName $Apps.ShortName -Version $Apps.Version -Publisher $Apps.Publisher -Language $Apps.Language -CommandLine $Apps.Install -WorkingDirectory "" -NoSource -Verbose
}

Start-Sleep -Seconds 5
