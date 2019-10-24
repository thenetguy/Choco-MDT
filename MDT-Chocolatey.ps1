#################### Start User Editable section ####################
# Change $AppsFolderName  to whatever folder name you want Chocolatey Apps to be installed in MDT under Applications
# Change $Deploymentshare to match your MDT Deployment Share location

$AppsFolderName = "Chocolatey Apps"
$Deploymentshare = "C:\DeploymentShare"

#################### End User Editable section ######################
#
#
#
#Requires -RunAsAdministrator
#####################################################################

############  logging function ############
$Logfile = ".\MDT-Choco.log"
function Write-Log {
    param (
        [Parameter(Mandatory = $True)]
        [string]$Log,
        [Parameter(Mandatory = $True)]
        [ValidateSet("Info", "Warn", "Error")]
        [string]$Level
    )
    $Date = Get-Date
    if ($Level -eq "Info") {
        Write-Host -ForegroundColor Green -BackgroundColor Black "$Date ($Level): $Log"
    } 
    elseif ($Level -eq "Warn") {
        Write-Host -ForegroundColor Yellow -BackgroundColor Black "$Date ($Level): $Log"
    } 
    else {
        Write-Host -ForegroundColor Red -BackgroundColor Black "$Date ($Level): $Log"
    }
    Add-content $Logfile -Value "$Date ($Level): $Log"
}


#### search the reg for installed apps function #############
function Get-LD_InstalledSoftware {
    [CmdletBinding()]
    Param
    (
        # Wildcard characters allowed - and recommended.
        [Parameter()]
        [string]
        $DisplayName = '*',
 
        # Wildcard characters allowed.
        [Parameter()]
        [string]
        $DisplayVersion = '*',
 
        # Use 'yyyyMMdd' format.
        [Parameter()]
        [string]
        $InstallDate = '*',
 
        # Wildcard characters allowed.
        [Parameter()]
        [string]
        $Publisher = '*',
 
        # Wildcard characters allowed, but normally this otta be left to the default.
        [Parameter()]
        [string]
        $UninstallString = '*'
    )
   
    # registry locations for installed software
    $Provider = 'Registry::'
    $All = 'HKEY_LOCAL_MACHINE\SOFTWARE'
    $Current = 'HKEY_CURRENT_USER\SOFTWARE'
    $64_32 = 'Microsoft\Windows\CurrentVersion\Uninstall\*'
    $32_on_64 = 'WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*'
    # join reg locations
    $RPathAllUser = -join ($Provider, (Join-Path -Path $All -ChildPath $64_32))
    $RPathCurrentUser = -join ($Provider, (Join-Path -Path $Current -ChildPath $64_32))
    $RPathAllUser32 = -join ($Provider, (Join-Path -Path $All -ChildPath $32_on_64))
    $RPathCurrentUser32 = -join ($Provider, (Join-Path -Path $Current -ChildPath $32_on_64))

    # get all values from all 4 registry locations
    $Result = Get-ItemProperty -Path $RPathAllUser, $RPathCurrentUser, $RPathAllUser32, $RPathCurrentUser32 |
    # skip items without a DisplayName
    Where-Object DisplayName -ne $null |
    Where-Object {
        $_.DisplayName -like $DisplayName -and
        $_.DisplayVersion -like $DisplayVersion -and
        $_.InstallDate -like $InstallDate -and
        $_.Publisher -like $Publisher -and
        $_.UninstallString -like $UninstallString
    } |
    Sort-Object -Property DisplayName

    $Result
}
########################################################



#################Check if Microsoft Deployment Toolkit is installed ################

Write-Log -Level Warn -Log "Checking if Microsoft Deployment Toolkit is installed on this Machine ($env:COMPUTERNAME)"

Start-Sleep -Seconds 1
$CheckMDT = Get-LD_InstalledSoftware -DisplayName "*Microsoft Deployment Toolkit*"
if ($CheckMDT) {
    
    Write-Log -Level Info -Log "Microsoft Deployment Toolkit is installed on this Machine ($env:COMPUTERNAME)"
    Start-Sleep -Seconds 1
}  
else {
    Write-Log -Level Error -Log "Microsoft Deployment Toolkit must be installed before running this script. Please install MDT and run this script again"
    Start-Sleep -Seconds 1
    exit
}


################ Check Windows Assessment and Deployment Kit is installed ################

Write-Log -Level warn -Log "Checking If Windows Assessment and Deployment Kit is installed on this Machine ($env:COMPUTERNAME) "
$CheckADK = Get-LD_InstalledSoftware -DisplayName "*Windows Deployment Tools*"
if ($CheckADK) {
    Write-Log -Level Info -Log "Windows Assessment and Deployment Kit is installed on this Machine ($env:COMPUTERNAME)"
    Start-Sleep -Seconds 1
}  
else {
    Write-Log -Level Error -Log "Windows Assessment and Deployment Kit must be installed before running this script. Please install MDT and run this script again"
    Start-Sleep -Seconds 10
    exit
}


################# Import Microsoft Deployment Toolkit PowerShell Module ################

Write-Log -Level Info -Log "Importing Microsoft Deployment Toolkit PowerShell Module"
Start-Sleep -Seconds 1
Import-Module "C:\Program Files\Microsoft Deployment Toolkit\bin\MicrosoftDeploymentToolkit.psd1"


################## Check if Apps.csv is located in the same folder #################

Write-Log -Level Warn -Log "Checking if Apps.csv is located in $PSScriptRoot\"
Start-Sleep -Seconds 0
$CheckApps = Test-Path ".\apps.csv"
if ($CheckApps) {
    Write-Log -Level Info -Log "Apps.csv is found"
    Start-Sleep -Seconds 0
}  
else {
    Write-Log -Level Error -Log "Unable to find $PSScriptRoot\apps.csv"
    Write-Log -Level Error -Log "make sure $PSScriptRoot\apps.csv is present and run this script again "
    Start-Sleep -Seconds 10
    exit
}


################### Import app list from apps.csv ##################

Write-Log -Level Info -Log "Importing app list from apps.csv into MDT"
Start-Sleep -Seconds 1
$apps = Import-Csv .\apps.csv

################### Create $AppsFolderName folder under applications in MDT ##################

Write-Log -Level Info -Log "Creating $AppsFolderName folder under Applications in MDT"
Start-Sleep -Seconds 1
New-PSDrive -Name "DS001" -PSProvider MDTProvider -Root "$Deploymentshare"
New-Item -path "DS001:/Applications" -enable "True" -Name "$AppsFolderName" -Comments "" -ItemType "folder" -Verbose

################### Importing Chocolatey Apps from Apps.csv to MDT ################### 

ForEach ($Apps In $Apps) {
    import-MDTApplication -path "DS001:\Applications\$AppsFolderName" -enable "True" -Name $Apps.Name -ShortName $Apps.ShortName -Version $Apps.Version -Publisher $Apps.Publisher -Language $Apps.Language -CommandLine $Apps.CommandLine -WorkingDirectory "" -NoSource -Verbose
}


Start-Sleep -Seconds 0