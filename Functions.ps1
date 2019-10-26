    #region Test-Host 
	
	function Test-Host
	{
	        
	    <#
	        .Synopsis 
	            Test a host for connectivity using either WMI ping or TCP port
	            
	        .Description
	            Allows you to test a host for connectivity before further processing
	            
	        .Parameter Server
	            Name of the Server to Process.
	            
	        .Parameter TCPPort
	            TCP Port to connect to. (default 135)
	            
	        .Parameter Timeout
	            Timeout for the TCP connection (default 1 sec)
	            
	        .Parameter Property
	            Name of the Property that contains the value to test.
	            
	        .Example
	            cat ServerFile.txt | Test-Host | Invoke-DoSomething
	            Description
	            -----------
	            To test a list of hosts.
	            
	        .Example
	            cat ServerFile.txt | Test-Host -tcp 80 | Invoke-DoSomething
	            Description
	            -----------
	            To test a list of hosts against port 80.
	            
	        .Example
	            Get-ADComputer | Test-Host -property dnsHostname | Invoke-DoSomething
	            Description
	            -----------
	            To test the output of Get-ADComputer using the dnshostname property
	            
	            
	        .OUTPUTS
	            System.Object
	            
	        .INPUTS
	            System.String
	            
	        .Link
	            Test-Port
	            
	        NAME:      Test-Host
	        AUTHOR:    YetiCentral\bshell
	        Website:   www.bsonposh.com
	        LASTEDIT:  02/04/2009 18:25:15
	        #Requires -Version 2.0
	    #>
	    
	    [CmdletBinding()]
	    
	    Param(
	    
	        [Parameter(ValueFromPipelineByPropertyName=$true,ValueFromPipeline=$true,Mandatory=$True)]
	        [string]$ComputerName,
	        
	        [Parameter()]
	        [int]$TCPPort=80,
	        
	        [Parameter()]
	        [int]$timeout=3000,
	        
	        [Parameter()]
	        [string]$property
	        
	    )
	    Begin 
	    {
	    
	        function PingServer 
	        {
	            Param($MyHost)
	            $ErrorActionPreference = "SilentlyContinue"
	            Write-Verbose " [PingServer] :: Pinging [$MyHost]"
	            try
	            {
	                $pingresult = Get-WmiObject win32_pingstatus -f "address='$MyHost'"
	                $ResultCode = $pingresult.statuscode
	                Write-Verbose " [PingServer] :: Ping returned $ResultCode"
	                if($ResultCode -eq 0) {$true} else {$false}
	            }
	            catch
	            {
	                Write-Verbose " [PingServer] :: Ping Failed with Error: ${error[0]}"
	                $false
	            }
	        }
	    
	    }
	    
	    Process 
	    {
	    
	        Write-Verbose " [Test-Host] :: Begin Process"
	        if($ComputerName -match "(.*)(\$)$")
	        {
	            $ComputerName = $ComputerName -replace "(.*)(\$)$",'$1'
	        }
	        Write-Verbose " [Test-Host] :: ComputerName   : $ComputerName"
	        if($TCPPort)
	        {
	            Write-Verbose " [Test-Host] :: Timeout  : $timeout"
	            Write-Verbose " [Test-Host] :: Port     : $TCPPort"
	            if($property)
	            {
	                Write-Verbose " [Test-Host] :: Property : $Property"
	                $Result = Test-Port $_.$property -tcp $TCPPort -timeout $timeout
	                if($Result)
	                {
	                    if($_){ $_ }else{ $ComputerName }
	                }
	            }
	            else
	            {
	                Write-Verbose " [Test-Host] :: Running - 'Test-Port $ComputerName -tcp $TCPPort -timeout $timeout'"
	                $Result = Test-Port $ComputerName -tcp $TCPPort -timeout $timeout
	                if($Result)
	                {
	                    if($_){ $_ }else{ $ComputerName }
	                } 
	            }
	        }
	        else
	        {
	            if($property)
	            {
	                Write-Verbose " [Test-Host] :: Property : $Property"
	                try
	                {
	                    if(PingServer $_.$property)
	                    {
	                        if($_){ $_ }else{ $ComputerName }
	                    } 
	                }
	                catch
	                {
	                    Write-Verbose " [Test-Host] :: $($_.$property) Failed Ping"
	                }
	            }
	            else
	            {
	                Write-Verbose " [Test-Host] :: Simple Ping"
	                try
	                {
	                    if(PingServer $ComputerName){$ComputerName}
	                }
	                catch
	                {
	                    Write-Verbose " [Test-Host] :: $ComputerName Failed Ping"
	                }
	            }
	        }
	        Write-Verbose " [Test-Host] :: End Process"
	    
	    }
	    
	}
	    
	#endregion 
    
    
    
    #region Test-Port 
	
	function Test-Port
	{
	        
	    <#
	        .Synopsis 
	            Test a host to see if the specified port is open.
	            
	        .Description
	            Test a host to see if the specified port is open.
	                        
	        .Parameter TCPPort 
	            Port to test (Default 135.)
	            
	        .Parameter Timeout 
	            How long to wait (in milliseconds) for the TCP connection (Default 3000.)
	            
	        .Parameter ComputerName 
	            Computer to test the port against (Default in localhost.)
	            
	        .Example
	            Test-Port -tcp 3389
	            Description
	            -----------
	            Returns $True if the localhost is listening on 3389
	            
	        .Example
	            Test-Port -tcp 3389 -ComputerName MyServer1
	            Description
	            -----------
	            Returns $True if MyServer1 is listening on 3389
	                    
	        .OUTPUTS
	            System.Boolean
	            
	        .INPUTS
	            System.String
	            
	        .Link
	            Test-Host
	            Wait-Port
	            
	        .Notes
	            NAME:      Test-Port
	            AUTHOR:    bsonposh
	            Website:   http://www.bsonposh.com
	            Version:   1
	            #Requires -Version 2.0
	    #>
	    
	    [Cmdletbinding()]
	    Param(
	        [Parameter()]
	        [int]$TCPport = 135,
	        [Parameter()]
	        [int]$TimeOut = 3000,
	        [Alias("dnsHostName")]
	        [Parameter(ValueFromPipelineByPropertyName=$true,ValueFromPipeline=$true)]
	        [String]$ComputerName = $env:COMPUTERNAME
	    )
	    Begin 
	    {
	        Write-Verbose " [Test-Port] :: Start Script"
	        Write-Verbose " [Test-Port] :: Setting Error state = 0"
	    }
	    
	    Process 
	    {
	    
	        Write-Verbose " [Test-Port] :: Creating [system.Net.Sockets.TcpClient] instance"
	        $tcpclient = New-Object system.Net.Sockets.TcpClient
	        
	        Write-Verbose " [Test-Port] :: Calling BeginConnect($ComputerName,$TCPport,$null,$null)"
	        try
	        {
	            $iar = $tcpclient.BeginConnect($ComputerName,$TCPport,$null,$null)
	            Write-Verbose " [Test-Port] :: Waiting for timeout [$timeout]"
	            $wait = $iar.AsyncWaitHandle.WaitOne($TimeOut,$false)
	        }
	        catch [System.Net.Sockets.SocketException]
	        {
	            Write-Verbose " [Test-Port] :: Exception: $($_.exception.message)"
	            Write-Verbose " [Test-Port] :: End"
	            return $false
	        }
	        catch
	        {
	            Write-Verbose " [Test-Port] :: General Exception"
	            Write-Verbose " [Test-Port] :: End"
	            return $false
	        }
	    
	        if(!$wait)
	        {
	            $tcpclient.Close()
	            Write-Verbose " [Test-Port] :: Connection Timeout"
	            Write-Verbose " [Test-Port] :: End"
	            return $false
	        }
	        else
	        {
	            Write-Verbose " [Test-Port] :: Closing TCP Socket"
	            try
	            {
	                $tcpclient.EndConnect($iar) | out-Null
	                $tcpclient.Close()
	            }
	            catch
	            {
	                Write-Verbose " [Test-Port] :: Unable to Close TCP Socket"
	            }
	            $true
	        }
	    }
	    End 
	    {
	        Write-Verbose " [Test-Port] :: End Script"
	    }
	}  
	#endregion 


#region Get-IP 

function Get-IP
{
        
    <#
        .Synopsis 
            Get the IP of the specified host.
            
        .Description
            Get the IP of the specified host.
            
        .Parameter ComputerName
            Name of the Computer to get IP (Default localhost.)
                
        .Example
            Get-IP
            Description
            -----------
            Get IP information the localhost
            
            
        .OUTPUTS
            PSCustomObject
            
        .INPUTS
            System.String
        
        .Notes
            NAME:      Get-IP
            AUTHOR:    YetiCentral\bshell
            Website:   www.bsonposh.com
            #Requires -Version 2.0
    #>
    
    [Cmdletbinding()]
    Param(
        [alias('dnsHostName')]
        [Parameter(ValueFromPipelineByPropertyName=$true,ValueFromPipeline=$true)]
        [string]$ComputerName = $Env:COMPUTERNAME
    )
    Process
    {
        $NICs = Get-WmiObject Win32_NetworkAdapterConfiguration -Filter "IPEnabled='$True'" -ComputerName $ComputerName
        foreach($Nic in $NICs)
        {
            $myobj = @{
                Name          = $Nic.Description
                MacAddress    = $Nic.MACAddress
                IP4           = $Nic.IPAddress | where{$_ -match "\d+\.\d+\.\d+\.\d+"}
                IP6           = $Nic.IPAddress | where{$_ -match "\:\:"}
                IP4Subnet     = $Nic.IPSubnet  | where{$_ -match "\d+\.\d+\.\d+\.\d+"}
                DefaultGWY    = $Nic.DefaultIPGateway | Select -First 1
                DNSServer     = $Nic.DNSServerSearchOrder
                WINSPrimary   = $Nic.WINSPrimaryServer
                WINSSecondary = $Nic.WINSSecondaryServer
            }
            $obj = New-Object PSObject -Property $myobj
            $obj.PSTypeNames.Clear()
            $obj.PSTypeNames.Add('BSonPosh.IPInfo')
            $obj
        }
    }
}
    
#endregion 


function Get-Processor
{
        
    <#
        .Synopsis 
            Gets the Computer Processor info for specified host.
            
        .Description
            Gets the Computer Processor info for specified host.
            
        .Parameter ComputerName
            Name of the Computer to get the Computer Processor info from (Default is localhost.)
            
        .Example
            Get-Processor
            Description
            -----------
            Gets Computer Processor info from local machine
    
        .Example
            Get-Processor -ComputerName MyServer
            Description
            -----------
            Gets Computer Processor info from MyServer
            
        .Example
            $Servers | Get-Processor
            Description
            -----------
            Gets Computer Processor info for each machine in the pipeline
            
        .OUTPUTS
            PSCustomObject
            
        .INPUTS
            System.String
            
        .Link
            N/A
            
        .Notes
            NAME:      Get-Processor
            AUTHOR:    bsonposh
            Website:   http://www.bsonposh.com
            Version:   1
            #Requires -Version 2.0
    #>
    
    [Cmdletbinding()]
    Param(
        [alias('dnsHostName')]
        [Parameter(ValueFromPipelineByPropertyName=$true,ValueFromPipeline=$true)]
        [string]$ComputerName = $Env:COMPUTERNAME
    )
    
    Process 
    {
    
        if($ComputerName -match "(.*)(\$)$")
        {
            $ComputerName = $ComputerName -replace "(.*)(\$)$",'$1'
        }
        if(Test-Host -ComputerName $ComputerName -TCPPort 135)
        {
            try
            {
                $CPUS = Get-WmiObject Win32_Processor -ComputerName $ComputerName -ea STOP
                foreach($CPU in $CPUs)
                {
                    $myobj = @{
                        ComputerName = $ComputerName
                        Name         = $CPU.Name
                        Manufacturer = $CPU.Manufacturer
                        Speed        = $CPU.MaxClockSpeed
                        Cores        = $CPU.NumberOfCores
                        L2Cache      = $CPU.L2CacheSize
                        Stepping     = $CPU.Stepping
                    }
                }
                $obj = New-Object PSObject -Property $myobj
                $obj.PSTypeNames.Clear()
                $obj.PSTypeNames.Add('BSonPosh.Computer.Processor')
                $obj
            }
            catch
            {
                Write-Host " Host [$ComputerName] Failed with Error: $($Error[0])" -ForegroundColor Red
            }
        }
        else
        {
            Write-Host " Host [$ComputerName] Failed Connectivity Test " -ForegroundColor Red
        }
    
    }
}
    
#endregion


#region Get-MemoryConfiguration 
	
function Get-MemoryConfiguration
{
        
    <#
        .Synopsis 
            Gets the Memory Config for specified host.
            
        .Description
            Gets the Memory Config for specified host.
            
        .Parameter ComputerName
            Name of the Computer to get the Memory Config from (Default is localhost.)
            
        .Example
            Get-MemoryConfiguration
            Description
            -----------
            Gets Memory Config from local machine
    
        .Example
            Get-MemoryConfiguration -ComputerName MyServer
            Description
            -----------
            Gets Memory Config from MyServer
            
        .Example
            $Servers | Get-MemoryConfiguration
            Description
            -----------
            Gets Memory Config for each machine in the pipeline
            
        .OUTPUTS
            PSCustomObject
            
        .Notes
            NAME:      Get-MemoryConfiguration 
            AUTHOR:    YetiCentral\bshell
            Website:   www.bsonposh.com
            #Requires -Version 2.0
    #>
    
    [Cmdletbinding()]
    Param(
        [alias('dnsHostName')]
        [Parameter(ValueFromPipelineByPropertyName=$true,ValueFromPipeline=$true)]
        [string]$ComputerName = $Env:COMPUTERNAME
    )
    
    Process 
    {
    
        Write-Verbose " [Get-MemoryConfiguration] :: Begin Process"
        if($ComputerName -match "(.*)(\$)$")
        {
            $ComputerName = $ComputerName -replace "(.*)(\$)$",'$1'
        }
        if(Test-Host $ComputerName -TCPPort 135)
        {
            Write-Verbose " [Get-MemoryConfiguration] :: Processing $ComputerName"
            try
            {
                $MemorySlots = Get-WmiObject Win32_PhysicalMemory -ComputerName $ComputerName -ea STOP
                foreach($Dimm in $MemorySlots)
                {
                    $myobj = @{}
                    $myobj.ComputerName = $ComputerName
                    $myobj.Description  = $Dimm.Tag
                    $myobj.Slot         = $Dimm.DeviceLocator
                    $myobj.Speed        = $Dimm.Speed
                    $myobj.SizeGB       = $Dimm.Capacity/1gb
                    
                    $obj = New-Object PSObject -Property $myobj
                    $obj.PSTypeNames.Clear()
                    $obj.PSTypeNames.Add('BSonPosh.MemoryConfiguration')
                    $obj
                }
            }
            catch
            {
                Write-Host " Host [$ComputerName] Failed with Error: $($Error[0])" -ForegroundColor Red
            }    
        }
        else
        {
            Write-Host " Host [$ComputerName] Failed Connectivity Test " -ForegroundColor Red
        }
        Write-Verbose " [Get-MemoryConfiguration] :: End Process"
    
    }
}
    
#endregion 


#region Get-NetStat 
	            #Need to Implement
	            #[Parameter()]
	            #[int]$ID,
	            #[Parameter()]
	            #[int]$RemotePort,
	            #[Parameter()]
	            #[string]$RemoteAddress,
                function Get-NetStat
                {
                
                    <#
                        .Synopsis 
                            Get the Network stats of the local host.
                            
                        .Description
                            Get the Network stats of the local host.
                            
                        .Parameter ProcessName
                            Name of the Process to get Network stats for.
                        
                        .Parameter State
                            State to return: Valid Values are: "LISTENING", "ESTABLISHED", "CLOSE_WAIT", or "TIME_WAIT"
                
                        .Parameter Interval
                            Number of times you want to run netstat. Cannot be used with Loop.
                            
                        .Parameter Sleep
                            Time between calls to netstat. Used with Interval or Loop.
                            
                        .Parameter Loop
                            Loops netstat calls until you press ctrl-c. Cannot be used with Internval.
                            
                        .Example
                            Get-NetStat
                            Description
                            -----------
                            Returns all Network stat information on the localhost
                        
                        .Example
                            Get-NetStat -ProcessName chrome
                            Description
                            -----------
                            Returns all Network stat information on the localhost for process chrome.
                            
                        .Example
                            Get-NetStat -State ESTABLISHED
                            Description
                            -----------
                            Returns all the established connections on the localhost
                            
                        .Example
                            Get-NetStat -State ESTABLISHED -Loop
                            Description
                            -----------
                            Loops established connections.
                            
                        .OUTPUTS
                            PSCustomObject
                            
                        .INPUTS
                            System.String
                        
                        .Notes
                            NAME:      Get-NetStat
                            AUTHOR:    YetiCentral\bshell
                            Website:   www.bsonposh.com
                            #Requires -Version 2.0
                
                    #>
                    
                    [Cmdletbinding(DefaultParameterSetName="All")]
                    Param(
                        [Parameter()]
                        [string]$ProcessName,
                
                        [Parameter()]
                        [ValidateSet("LISTENING", "ESTABLISHED", "CLOSE_WAIT","TIME_WAIT")]
                        [string]$State,
                        
                        [Parameter(ParameterSetName="Interval")]
                        [int]$Interval,
                        
                        [Parameter()]
                        [int]$Sleep = 1,
                        
                        [Parameter(ParameterSetName="Loop")]
                        [switch]$Loop
                    )
                
                    function Parse-Netstat ($NetStat)
                    {
                        Write-Verbose " [Parse-Netstat] :: Parsing Netstat results"
                        switch -regex ($NetStat)
                        {
                            $RegEx  
                            {
                                Write-Verbose " [Parse-Netstat] :: creating Custom object"
                                $myobj = @{
                                    Protocol      = $matches.Protocol
                                    LocalAddress  = $matches.LocalAddress.split(":")[0]
                                    LocalPort     = $matches.LocalAddress.split(":")[1]
                                    RemoteAddress = $matches.RemoteAddress.split(":")[0]
                                    RemotePort    = $matches.RemoteAddress.split(":")[1]
                                    State         = $matches.State
                                    ProcessID     = $matches.PID
                                    ProcessName   = Get-Process -id $matches.PID -ea 0 | %{$_.name}
                                }
                                
                                $obj = New-Object PSCustomObject -Property $myobj
                                $obj.PSTypeNames.Clear()
                                $obj.PSTypeNames.Add('BSonPosh.NetStatInfo')
                                Write-Verbose " [Parse-Netstat] :: Created object for [$($obj.LocalAddress):$($obj.LocalPort)]"
                                
                                if($ProcessName)
                                {
                                    $obj | where{$_.ProcessName -eq $ProcessName}
                                }
                                elseif($State)
                                {
                                    $obj | where{$_.State -eq $State}
                                }
                                else
                                {
                                    $obj
                                }
                                
                            }
                        }
                    }
                    
                    [RegEX]$RegEx = '\s+(?<Protocol>\S+)\s+(?<LocalAddress>\S+)\s+(?<RemoteAddress>\S+)\s+(?<State>\S+)\s+(?<PID>\S+)'
                    $Connections = @{}
                    
                    switch -exact ($pscmdlet.ParameterSetName)
                    {    
                        "All"           {
                                            Write-Verbose " [Get-NetStat] :: ParameterSet - ALL"
                                            $NetStatResults = netstat -ano | ?{$_ -match "(TCP|UDP)\s+\d"}
                                            Parse-Netstat $NetStatResults
                                        }
                        "Interval"      {
                                            Write-Verbose " [Get-NetStat] :: ParameterSet - Interval"
                                            for($i = 1 ; $i -le $Interval ; $i++)
                                            {
                                                Start-Sleep $Sleep
                                                $NetStatResults = netstat -ano | ?{$_ -match "(TCP|UDP)\s+\d"}
                                                Parse-Netstat $NetStatResults | Out-String
                                            }
                                        }
                        "Loop"          {
                                            Write-Verbose " [Get-NetStat] :: ParameterSet - Loop"
                                            Write-Host
                                            Write-Host "Protocol LocalAddress  LocalPort RemoteAddress  RemotePort State       ProcessName   PID"
                                            Write-Host "-------- ------------  --------- -------------  ---------- -----       -----------   ---" -ForegroundColor White
                                            $oldPos = $Host.UI.RawUI.CursorPosition
                                            [console]::TreatControlCAsInput = $true
                                            while($true)
                                            {
                                                Write-Verbose " [Get-NetStat] :: Getting Netstat data"
                                                $NetStatResults = netstat -ano | ?{$_ -match "(TCP|UDP)\s+\d"}
                                                Write-Verbose " [Get-NetStat] :: Getting Netstat data from Netstat"
                                                $Results = Parse-Netstat $NetStatResults 
                                                Write-Verbose " [Get-NetStat] :: Parse-NetStat returned $($results.count) results"
                                                foreach($Result in $Results)
                                                {
                                                    $Key = $Result.LocalPort
                                                    $Value = $Result.ProcessID
                                                    $msg = "{0,-9}{1,-14}{2,-10}{3,-15}{4,-11}{5,-12}{6,-14}{7,-10}" -f  $Result.Protocol,$Result.LocalAddress,$Result.LocalPort,
                                                                                                                         $Result.RemoteAddress,$Result.RemotePort,$Result.State,
                                                                                                                         $Result.ProcessName,$Result.ProcessID
                                                    if($Connections.$Key -eq $Value)
                                                    {
                                                        Write-Host $msg
                                                    }
                                                    else
                                                    {
                                                        $Connections.$Key = $Value
                                                        Write-Host $msg -ForegroundColor Yellow
                                                    }
                                                }
                                                if ($Host.UI.RawUI.KeyAvailable -and (3 -eq [int]$Host.UI.RawUI.ReadKey("AllowCtrlC,IncludeKeyUp,NoEcho").Character))
                                                {
                                                    Write-Host "Exiting now..." -foregroundcolor Yellow
                                                    Write-Host
                                                    [console]::TreatControlCAsInput = $false
                                                    break
                                                }
                                                $Host.UI.RawUI.CursorPosition = $oldPos
                                                start-sleep $Sleep
                                            }
                                        }
                    }
                }
                
                #endregion 
                
                
#region Get-NicInfo 
	
function Get-NICInfo
{

    <#
        .Synopsis  
            Gets the NIC info for specified host
            
        .Description
            Gets the NIC info for specified host
            
        .Parameter ComputerName
            Name of the Computer to get the NIC info from (Default is localhost.)
            
        .Example
            Get-NicInfo
            # Gets NIC info from local machine
    
        .Example
            Get-NicInfo -ComputerName MyServer
            Description
            -----------
            Gets NIC info from MyServer
            
        .Example
            $Servers | Get-NicInfo
            Description
            -----------
            Gets NIC info for each machine in the pipeline
            
        .OUTPUTS
            PSCustomObject
            
        .Notes
            NAME:      Get-NicInfo 
            AUTHOR:    YetiCentral\bshell
            Website:   www.bsonposh.com
            #Requires -Version 2.0
    #>
    
    [Cmdletbinding()]
    Param(
        [alias('dnsHostName')]
        [Parameter(ValueFromPipelineByPropertyName=$true,ValueFromPipeline=$true)]
        [string]$ComputerName = $Env:COMPUTERNAME
    )

    Process
    {
        if($ComputerName -match "(.*)(\$)$")
        {
            $ComputerName = $ComputerName -replace "(.*)(\$)$",'$1'
        }
        
        if(Test-Host -ComputerName $ComputerName -TCPPort 135)
        {
            try
            {
                $NICS = Get-WmiObject -class Win32_NetworkAdapterConfiguration -ComputerName $ComputerName
                
                foreach($NIC in $NICS)
                {
                    $Query = "Select Name,NetConnectionID FROM Win32_NetworkAdapter WHERE Index='$($NIC.Index)'"
                    $NetConnnectionID = Get-WmiObject -Query $Query -ComputerName $ComputerName
                    
                    $myobj = @{
                        ComputerName = $ComputerName
                        Name         = $NetConnnectionID.Name
                        NetID        = $NetConnnectionID.NetConnectionID
                        MacAddress   = $NIC.MacAddress
                        IP           = $NIC.IPAddress | ?{$_ -match "\d*\.\d*\.\d*\."}
                        Subnet       = $NIC.IPSubnet  | ?{$_ -match "\d*\.\d*\.\d*\."}
                        Enabled      = $NIC.IPEnabled
                        Index        = $NIC.Index
                    }
                    
                    $obj = New-Object PSObject -Property $myobj
                    $obj.PSTypeNames.Clear()
                    $obj.PSTypeNames.Add('BSonPosh.NICInfo')
                    $obj
                }
            }
            catch
            {
                Write-Host " Host [$ComputerName] Failed with Error: $($Error[0])" -ForegroundColor Red
            }
        }
        else
        {
            Write-Host " Host [$ComputerName] Failed Connectivity Test " -ForegroundColor Red
        }
    }
} 

#endregion 

#region Get-MotherBoard
	
function Get-MotherBoard
{
        
    <#
        .Synopsis 
            Gets the Mother Board info for specified host.
            
        .Description
            Gets the Mother Board info for specified host.
            
        .Parameter ComputerName
            Name of the Computer to get the Mother Board info from (Default is localhost.) 
            
        .Example
            Get-MotherBoard
            Description
            -----------
            Gets Mother Board info from local machine
    
        .Example
            Get-MotherBoard -ComputerName MyOtherDesktop
            Description
            -----------
            Gets Mother Board info from MyOtherDesktop
            
        .Example
            $Windows7Machines | Get-MotherBoard
            Description
            -----------
            Gets Mother Board info for each machine in the pipeline
            
        .OUTPUTS
            PSCustomObject
            
        .INPUTS
            System.String
            
        .Link
            N/A
            
        .Notes
            NAME:      Get-MotherBoard
            AUTHOR:    bsonposh
            Website:   http://www.bsonposh.com
            Version:   1
            #Requires -Version 2.0
    #>
    
    [Cmdletbinding()]
    Param(
        [alias('dnsHostName')]
        [Parameter(ValueFromPipelineByPropertyName=$true,ValueFromPipeline=$true)]
        [string]$ComputerName = $Env:COMPUTERNAME
    )
    
    Process 
    {
    
        if($ComputerName -match "(.*)(\$)$")
        {
            $ComputerName = $ComputerName -replace "(.*)(\$)$",'$1'
        }
        if(Test-Host -ComputerName $ComputerName -TCPPort 135)
        {
            try
            {
                $MBInfo = Get-WmiObject Win32_BaseBoard -ComputerName $ComputerName -ea STOP
                $myobj = @{
                    ComputerName     = $ComputerName
                    Name             = $MBInfo.Product
                    Manufacturer     = $MBInfo.Manufacturer
                    Version          = $MBInfo.Version
                    SerialNumber     = $MBInfo.SerialNumber
                 }
                
                $obj = New-Object PSObject -Property $myobj
                $obj.PSTypeNames.Clear()
                $obj.PSTypeNames.Add('BSonPosh.Computer.MotherBoard')
                $obj
            }
            catch
            {
                Write-Host " Host [$ComputerName] Failed with Error: $($Error[0])" -ForegroundColor Red
            }
        }
        else
        {
            Write-Host " Host [$ComputerName] Failed Connectivity Test " -ForegroundColor Red
        }
    
    }
}
    
#endregion # Get-MotherBoard


#region Get-SystemType 
	
function Get-SystemType
{
        
    <#
        .Synopsis 
            Gets the system type for specified host
            
        .Description
            Gets the system type info for specified host
            
        .Parameter ComputerName
            Name of the Computer to get the System Type from (Default is localhost.)
            
        .Example
            Get-SystemType
            Description
            -----------
            Gets System Type from local machine
    
        .Example
            Get-SystemType -ComputerName MyServer
            Description
            -----------
            Gets System Type from MyServer
            
        .Example
            $Servers | Get-SystemType
            Description
            -----------
            Gets System Type for each machine in the pipeline
            
        .OUTPUTS
            PSObject
            
        .Notes
            NAME:      Get-SystemType 
            AUTHOR:    YetiCentral\bshell
            Website:   www.bsonposh.com
            #Requires -Version 2.0
    #>
    
    [Cmdletbinding()]
    Param(
        [alias('dnsHostName')]
        [Parameter(ValueFromPipelineByPropertyName=$true,ValueFromPipeline=$true)]
        [string]$ComputerName = $Env:COMPUTERNAME
    )
    
    Begin 
    {
    
        function ConvertTo-ChassisType($Type)
        {
            switch ($Type)
            {
                1    {"Other"}
                2    {"Unknown"}
                3    {"Desktop"}
                4    {"Low Profile Desktop"}
                5    {"Pizza Box"}
                6    {"Mini Tower"}
                7    {"Tower"}
                8    {"Portable"}
                9    {"Laptop"}
                10    {"Notebook"}
                11    {"Hand Held"}
                12    {"Docking Station"}
                13    {"All in One"}
                14    {"Sub Notebook"}
                15    {"Space-Saving"}
                16    {"Lunch Box"}
                17    {"Main System Chassis"}
                18    {"Expansion Chassis"}
                19    {"SubChassis"}
                20    {"Bus Expansion Chassis"}
                21    {"Peripheral Chassis"}
                22    {"Storage Chassis"}
                23    {"Rack Mount Chassis"}
                24    {"Sealed-Case PC"}
            }
        }
        function ConvertTo-SecurityStatus($Status)
        {
            switch ($Status)
            {
                1    {"Other"}
                2    {"Unknown"}
                3    {"None"}
                4    {"External Interface Locked Out"}
                5    {"External Interface Enabled"}
            }
        }
    
    }
    Process 
    {
    
        Write-Verbose " [Get-SystemType] :: Process Start"
        if($ComputerName -match "(.*)(\$)$")
        {
            $ComputerName = $ComputerName -replace "(.*)(\$)$",'$1'
        }
        if(Test-Host $ComputerName -TCPPort 135)
        {
            try
            {
                Write-Verbose " [Get-SystemType] :: Getting System (Enclosure) Type info use WMI"
                $SystemInfo = Get-WmiObject Win32_SystemEnclosure -ComputerName $ComputerName
                $CSInfo = Get-WmiObject -Query "Select Model FROM Win32_ComputerSystem" -ComputerName $ComputerName
                
                Write-Verbose " [Get-SystemType] :: Creating Hash Table"
                $myobj = @{}
                Write-Verbose " [Get-SystemType] :: Setting ComputerName   - $ComputerName"
                $myobj.ComputerName = $ComputerName
                
                Write-Verbose " [Get-SystemType] :: Setting Manufacturer   - $($SystemInfo.Manufacturer)"
                $myobj.Manufacturer = $SystemInfo.Manufacturer
                
                Write-Verbose " [Get-SystemType] :: Setting Module   - $($CSInfo.Model)"
                $myobj.Model = $CSInfo.Model
                
                Write-Verbose " [Get-SystemType] :: Setting SerialNumber   - $($SystemInfo.SerialNumber)"
                $myobj.SerialNumber = $SystemInfo.SerialNumber
                
                Write-Verbose " [Get-SystemType] :: Setting SecurityStatus - $($SystemInfo.SecurityStatus)"
                $myobj.SecurityStatus = ConvertTo-SecurityStatus $SystemInfo.SecurityStatus
                
                Write-Verbose " [Get-SystemType] :: Setting Type           - $($SystemInfo.ChassisTypes)"
                $myobj.Type = ConvertTo-ChassisType $SystemInfo.ChassisTypes
                
                Write-Verbose " [Get-SystemType] :: Creating Custom Object"
                $obj = New-Object PSCustomObject -Property $myobj
                $obj.PSTypeNames.Clear()
                $obj.PSTypeNames.Add('BSonPosh.SystemType')
                $obj
            }
            catch
            {
                Write-Verbose " [Get-SystemType] :: [$ComputerName] Failed with Error: $($Error[0])" 
            }
        }
    
    }
    
}
    
#endregion 

#region Get-RebootTime 

function Get-RebootTime
{
    <#
        .Synopsis 
            Gets the reboot time for specified host.
            
        .Description
            Gets the reboot time for specified host.
            
        .Parameter ComputerName
            Name of the Computer to get the reboot time from (Default is localhost.)
            
        .Example
            Get-RebootTime
            Description
            -----------
            Gets OS Version from local     
        
        .Example
            Get-RebootTime -Last
            Description
            -----------
            Gets last reboot time from local machine

        .Example
            Get-RebootTime -ComputerName MyServer
            Description
            -----------
            Gets reboot time from MyServer
            
        .Example
            $Servers | Get-RebootTime
            Description
            -----------
            Gets reboot time for each machine in the pipeline
            
        .OUTPUTS
            PSCustomObject
            
        .INPUTS
            System.String
            
        .Link
            N/A
            
        .Notes
            NAME:      Get-RebootTime
            AUTHOR:    bsonposh
            Website:   http://www.bsonposh.com
            Version:   1
            #Requires -Version 2.0
    #>
    
    [cmdletbinding()]
    Param(
        [alias('dnsHostName')]
        [Parameter(ValueFromPipelineByPropertyName=$true,ValueFromPipeline=$true)]
        [string]$ComputerName = $Env:COMPUTERNAME,
        
        [Parameter()]
        [Switch]$Last
    )
    process 
    {
    
        if($ComputerName -match "(.*)(\$)$")
        {
            $ComputerName = $ComputerName -replace "(.*)(\$)$",'$1'
        }
        if(Test-Host $ComputerName -TCPPort 135)
        {
            try
            {
                if($Last)
                {
                    $date = Get-WmiObject Win32_OperatingSystem -ComputerName $ComputerName -ea STOP | foreach{$_.LastBootUpTime}
                    $RebootTime = [System.DateTime]::ParseExact($date.split('.')[0],'yyyyMMddHHmmss',$null)
                    $myobj = @{}
                    $myobj.ComputerName = $ComputerName
                    $myobj.RebootTime = $RebootTime
                    
                    $obj = New-Object PSObject -Property $myobj
                    $obj.PSTypeNames.Clear()
                    $obj.PSTypeNames.Add('BSonPosh.RebootTime')
                    $obj
                }
                else
                {
                    $Query = "Select * FROM Win32_NTLogEvent WHERE SourceName='eventlog' AND EventCode='6009'"
                    Get-WmiObject -Query $Query -ea 0 -ComputerName $ComputerName | foreach {
                        $myobj = @{}
                        $RebootTime = [DateTime]::ParseExact($_.TimeGenerated.Split(".")[0],'yyyyMMddHHmmss',$null)
                        $myobj.ComputerName = $ComputerName
                        $myobj.RebootTime = $RebootTime
                        
                        $obj = New-Object PSObject -Property $myobj
                        $obj.PSTypeNames.Clear()
                        $obj.PSTypeNames.Add('BSonPosh.RebootTime')
                        $obj
                    }
                }
    
            }
            catch
            {
                Write-Host " Host [$ComputerName] Failed with Error: $($Error[0])" -ForegroundColor Red
            }
        }
        else
        {
            Write-Host " Host [$ComputerName] Failed Connectivity Test " -ForegroundColor Red
        }
    
    }
}
    
#endregion 

#region Get-USB
	
function Get-USB {
    <#
    .Synopsis
        Gets USB devices attached to the system
    .Description
        Uses WMI to get the USB Devices attached to the system
    .Example
        Get-USB
    .Example
        Get-USB | Group-Object Manufacturer  
    .Parameter ComputerName
        The name of the computer to get the USB devices from
    #>
    param($computerName = "localhost")
    Get-WmiObject Win32_USBControllerDevice -ComputerName $ComputerName `
        -Impersonation Impersonate -Authentication PacketPrivacy | 
        Foreach-Object { [Wmi]$_.Dependent }
}
#endregion


	#region Show-MsgBox
	<# 
	            .SYNOPSIS  
	            Shows a graphical message box, with various prompt types available. 
	 
	            .DESCRIPTION 
	            Emulates the Visual Basic MsgBox function.  It takes four parameters, of which only the prompt is mandatory 
	 
	            .INPUTS 
	            The parameters are:- 
	             
	            Prompt (mandatory):  
	                Text string that you wish to display 
	                 
	            Title (optional): 
	                The title that appears on the message box 
	                 
	            Icon (optional).  Available options are: 
	                Information, Question, Critical, Exclamation (not case sensitive) 
	                
	            BoxType (optional). Available options are: 
	                OKOnly, OkCancel, AbortRetryIgnore, YesNoCancel, YesNo, RetryCancel (not case sensitive) 
	                 
	            DefaultButton (optional). Available options are: 
	                1, 2, 3 
	 
	            .OUTPUTS 
	            Microsoft.VisualBasic.MsgBoxResult 
	 
	            .EXAMPLE 
	            C:\PS> Show-MsgBox Hello 
	            Shows a popup message with the text "Hello", and the default box, icon and defaultbutton settings. 
	 
	            .EXAMPLE 
	            C:\PS> Show-MsgBox -Prompt "This is the prompt" -Title "This Is The Title" -Icon Critical -BoxType YesNo -DefaultButton 2 
	            Shows a popup with the parameter as supplied. 
	 
	            .LINK 
	            http://msdn.microsoft.com/en-us/library/microsoft.visualbasic.msgboxresult.aspx 
	 
	            .LINK 
	            http://msdn.microsoft.com/en-us/library/microsoft.visualbasic.msgboxstyle.aspx 
	            #> 
	# By BigTeddy August 24, 2011 
	# http://social.technet.microsoft.com/profile/bigteddy/. 
	 
	function Show-MsgBox 
	{ 
	 
	 [CmdletBinding()] 
	    param( 
	    [Parameter(Position=0, Mandatory=$true)] [string]$Prompt, 
	    [Parameter(Position=1, Mandatory=$false)] [string]$Title ="", 
	    [Parameter(Position=2, Mandatory=$false)] [ValidateSet("Information", "Question", "Critical", "Exclamation")] [string]$Icon ="Information", 
	    [Parameter(Position=3, Mandatory=$false)] [ValidateSet("OKOnly", "OKCancel", "AbortRetryIgnore", "YesNoCancel", "YesNo", "RetryCancel")] [string]$BoxType ="OkOnly", 
	    [Parameter(Position=4, Mandatory=$false)] [ValidateSet(1,2,3)] [int]$DefaultButton = 1 
	    ) 
	[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.VisualBasic") | Out-Null 
	switch ($Icon) { 
	            "Question" {$vb_icon = [microsoft.visualbasic.msgboxstyle]::Question } 
	            "Critical" {$vb_icon = [microsoft.visualbasic.msgboxstyle]::Critical} 
	            "Exclamation" {$vb_icon = [microsoft.visualbasic.msgboxstyle]::Exclamation} 
	            "Information" {$vb_icon = [microsoft.visualbasic.msgboxstyle]::Information}} 
	switch ($BoxType) { 
	            "OKOnly" {$vb_box = [microsoft.visualbasic.msgboxstyle]::OKOnly} 
	            "OKCancel" {$vb_box = [microsoft.visualbasic.msgboxstyle]::OkCancel} 
	            "AbortRetryIgnore" {$vb_box = [microsoft.visualbasic.msgboxstyle]::AbortRetryIgnore} 
	            "YesNoCancel" {$vb_box = [microsoft.visualbasic.msgboxstyle]::YesNoCancel} 
	            "YesNo" {$vb_box = [microsoft.visualbasic.msgboxstyle]::YesNo} 
	            "RetryCancel" {$vb_box = [microsoft.visualbasic.msgboxstyle]::RetryCancel}} 
	switch ($Defaultbutton) { 
	            1 {$vb_defaultbutton = [microsoft.visualbasic.msgboxstyle]::DefaultButton1} 
	            2 {$vb_defaultbutton = [microsoft.visualbasic.msgboxstyle]::DefaultButton2} 
	            3 {$vb_defaultbutton = [microsoft.visualbasic.msgboxstyle]::DefaultButton3}} 
	$popuptype = $vb_icon -bor $vb_box -bor $vb_defaultbutton 
	$ans = [Microsoft.VisualBasic.Interaction]::MsgBox($prompt,$popuptype,$title) 
	return $ans 
	} #end
    #endregion
    
    function Get-LocalUser
{

<#
	.SYNOPSIS
		This script can be list all of local user account.
	.DESCRIPTION
		This script can be list all of local user account.
		The function is using WMI to connect to the remote machine
	.PARAMETER ComputerName
		Specifies the computers on which the command . The default is the local computer.
	.PARAMETER Credential
		A description of the Credential parameter.
	.EXAMPLE
		Get-LocalUser
		This example shows how to list all of local users on local computer.
	.NOTES
		Francois-Xavier Cat
		lazywinadmin.com
		@lazywinadmin
#>

	PARAM
	(
		[Alias('cn')]
		[String[]]$ComputerName = $Env:COMPUTERNAME,

		[String]$AccountName,

		[System.Management.Automation.PsCredential]$Credential
	)

	$Splatting = @{
		Class = "Win32_UserAccount"
		Namespace = "root\cimv2"
		Filter = "LocalAccount='$True'"
	}

	#Credentials
	If ($PSBoundParameters['Credential']) { $Splatting.Credential = $Credential }

	Foreach ($Computer in $ComputerName)
	{
		TRY
		{
			Write-Verbose -Message "[PROCESS] ComputerName: $Computer"
			Get-WmiObject @Splatting -ComputerName $Computer | Select-Object -Property Name, FullName, Caption, Disabled, Status, Lockout, PasswordChangeable, PasswordExpires, PasswordRequired, SID, SIDType, AccountType, Domain, Description
		}
		CATCH
		{
			Write-Warning -Message "[PROCESS] Issue connecting to $Computer"
		}
	}
}
#

function Get-LocalGroupMember
{
<#
    .SYNOPSIS
        Retrieve a Local Group membership
	.DESCRIPTION
        Retrieve a Local Group membership
	.PARAMETER ComputerName
		Specifies one or computers to query
	.PARAMETER GroupName
		Specifies the Group name
    .EXAMPLE
        Get-LocalGroupMember
    .NOTES
        Francois-Xavier Cat
        @lazywinadmin
        lazywinadmin.com
        To Add:
            Credential param
            Resurce Local and AD using ADSI or ActiveDirectory Module
            OnlyUser param
#>
	[CmdletBinding()]
	PARAM (
		[Parameter(ValueFromPipeline = $true,
				   ValueFromPipelineByPropertyName = $true)]
		[System.String[]]$ComputerName = $env:COMPUTERNAME,
		[System.String]$GroupName = "Administrators"
	)
	BEGIN
	{
		TRY
		{
			Add-Type -AssemblyName System.DirectoryServices.AccountManagement -ErrorAction 'Stop' -ErrorVariable ErrorBeginAddType
			$ctype = [System.DirectoryServices.AccountManagement.ContextType]::Machine
		}
		CATCH
		{
			Write-Warning -Message "[BEGIN] Something wrong happened"
			IF ($ErrorBeginAddType) { Write-Warning -Message "[BEGIN] Error while loading the Assembly: System.DirectoryServices.AccountManagement" }
			Write-Warning -Message $Error[0].Exception.Message
		}
	}
	PROCESS
	{
		FOREACH ($Computer in $ComputerName)
		{
			TRY
			{
				$context = New-Object -TypeName System.DirectoryServices.AccountManagement.PrincipalContext -ArgumentList $ctype, $computer
				$idtype = [System.DirectoryServices.AccountManagement.IdentityType]::SamAccountName
				$group = [System.DirectoryServices.AccountManagement.GroupPrincipal]::FindByIdentity($context, $idtype, $GroupName)
				$group.Members | Select-Object *, @{ Label = 'Server'; Expression = { $computer } }, @{ Label = 'Domain'; Expression = { $_.Context.Name } }
			}
			CATCH
			{
				Write-Warning -Message "[PROCESS] Something wrong happened"
				Write-Warning -Message $Error[0].Exception.Message
			}
		}
	}
}

#
