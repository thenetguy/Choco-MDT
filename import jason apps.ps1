

##############################################################################################################################

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

################################################################################################################################

#import MicrosoftDeploymentToolkit.psd1

Write-Host -ForegroundColor Green -BackgroundColor Black "Importing MicrosoftDeploymentToolkit.psd1"
Start-Sleep -Seconds 5
Import-Module "C:\Program Files\Microsoft Deployment Toolkit\bin\MicrosoftDeploymentToolkit.psd1"



###################################################################################################################################

#setup log file

$Logfile = ".\mdt-auto-deployment.log"

###################################################################################################################################
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
        Write-Host -ForegroundColor Green "$Date ($Level): $Log"
    } 
    elseif ($Level -eq "Warn") {
        Write-Host -ForegroundColor Yellow "$Date ($Level): $Log"
    } 
    else {
        Write-Host -ForegroundColor Red "$Date ($Level): $Log"
    }
    Add-content $Logfile -Value "$Date ($Level): $Log"
}

function Exit-Script {
    Pause
    Exit
}



####################################################################################################################################

#import Apps from Application.json
    Write-Log -Level Info -Log "Importing applications.json"
    $Applications = Test-Path ".\applications.json"
    if (!$Applications) {
        Write-Log -Level Error -Log "No applications.json file found in script directory"
        Exit-Script
    }
    else {
        try {
            $Applist = Get-Content ".\Applications.json" | ConvertFrom-Json
        }
        catch {
            Write-Log -Level Error -Log "Failed to load applications.json. Please check syntax and try again"
            Exit-Script
        }
    }




#######################################################################################################################################


#Import applications.json and download Office Deployment Tool
if ($IncludeApplications) {
    Write-Log -Level Info -Log "Importing applications.json"
    $Applications = Test-Path "$PSScriptRoot\applications.json"
    if (!$Applications) {
        Write-Log -Level Error -Log "No applications.json file found in script directory"
        Exit-Script
    }
    else {
        try {
            $Applist = gc "$PSScriptRoot\applications.json" | ConvertFrom-Json
        }
        catch {
            Write-Log -Level Error -Log "Failed to load applications.json. Please check syntax and try again"
            Exit-Script
        }
    }



}

#########################################################################################################################################

#import apps into mdt
if ($IncludeApplications) {
    foreach ($Application in $AppList) {
        Write-Log -Level Info -Log "Downloading and importing $($Application.Name)"
        New-Item -Path "$PSScriptRoot\mdt_apps\$($application.name)" -ItemType Directory -Force | Out-Null
        $params = @{
            Source      = $Application.download
            Destination = "$PSScriptRoot\mdt_apps\$($application.name)\$($Application.filename)"
        }
        try {
            Download-File @params -ErrorAction Stop
            $params = @{
                Path                  = "DS001:\Applications"
                Name                  = $Application.Name
                ShortName             = $Application.Name
                Publisher             = ""
                Language              = ""
                Enable                = "True"
                Version               = $Application.version
                CommandLine           = $Application.install
 #               WorkingDirectory      = ".\Applications\$($Application.name)"
 #              ApplicationSourcePath = "$PSScriptRoot\mdt_apps\$($application.name)"
 #               DestinationFolder     = $Application.name
            }
            Import-MDTApplication @params | Out-Null
        }
        catch {
            Write-Log -Level Warn -Log "Failed to download $($Application.name). Check URL is valid in applications.json. ($($_))"
        }
    }
    Remove-Item -Path "$PSScriptRoot\mdt_apps" -Recurse -Force -Confirm:$false | Out-Null
}