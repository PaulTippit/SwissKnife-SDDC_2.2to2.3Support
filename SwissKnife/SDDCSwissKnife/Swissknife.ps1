#####################################
# VxRack Swiss Knife version 0.7	#
# Created by Ben Mayer				#
# benedikt.mayer@vce.com 			#
# Contributions By:                 #
# Ben Sier                          #
# Luke Jones                        #
# Maciej Lipinski                   #
#####################################
Write-Host "--------------------------------------------------------------"
Write-Host "Loading PowerCLI..."
Add-PSSnapin VMware.VimAutomation.Core
Write-Host "Loading settings.conf..."
#[xml]$ConfigFile = Get-Content settings.xml
#$ESXHosts = $ConfigFile.Settings.IPs.ESX
#$IDRACs = $ConfigFile.Settings.IPs.IDRAC
#$IDRACpw = $ConfigFile.Settings.Passwords.IDRAC
#$ESXpw = $ConfigFile.Settings.Passwords.ESX
#$VRMip = $ConfigFile.Settings.IPs.VRM
#$VRMpw = $ConfigFile.Settings.Passwords.VRM

Write-Host "--------------------------------------------------------------"
Write-Host "This script provides a collection actions to `r`nautomate tasks during VxRack imaging or deployment.`r`nUpdate settings.xml based on your enviorment`r`nbefore launching the script."
Write-Host "--------------------------------------------------------------"

function Port902 {
foreach ($ESX in $ESXHosts)
		{	
		$ErrorActionPreference = 'SilentlyContinue'
		$Socket = New-Object Net.Sockets.TcpClient
        $Socket.Connect($ESX, 902)
                       
     
        if ($Socket.Connected) {
            "${ESX}: Port 902 is open"
            $Socket.Close()
        }
        else {
            "${ESX}: Port 902 is closed or filtered"
        }
        
        $Socket.Dispose()
        $Socket = $null
        
		}
}

function ESXReboot {
foreach ($ESX in $ESXHosts)
		{	
		Connect-VIServer -Server $ESX -User root -Password $ESXpw -Force
		Restart-VMHost -VMHost $ESX -force -confirm:$false 
		Write-Host "Rebooting $($ESX)"
        
		}
		Disconnect-VIServer -Server * -Force -confirm:$false
}

function ESXShutdown {
foreach ($ESX in $ESXHosts)
		{	
		Connect-VIServer -Server $ESX -User root -Password $ESXpw -Force
		Stop-VMHost -VMHost $ESX -force -confirm:$false 
		Write-Host "Shutting down $($ESX)"		
        
		}
		Disconnect-VIServer -Server * -Force -confirm:$false
}

function ESXEnterMaintMode {
foreach ($ESX in $ESXHosts)
		{	
		Connect-VIServer -Server $ESX -User root -Password $ESXpw -Force
		Set-VMHost -vmhost $ESX -state maintenance  
        Write-Host "Enter maintenance mode on $($ESX)"
		}
		Disconnect-VIServer -Server * -Force -confirm:$false
}
function ESXExitMaintMode {
foreach ($ESX in $ESXHosts)
		{	
		Connect-VIServer -Server $ESX -User root -Password $ESXpw -Force
		Set-VMHost -vmhost $ESX -state connected  
        Write-Host "Exit maintenance mode on $($ESX)"
		}
		Disconnect-VIServer -Server * -Force -confirm:$false
}

function ESXHostStatus {
foreach ($ESX in $ESXHosts)
		{	
		Connect-VIServer -Server $ESX -User root -Password $ESXpw -Force
		}
        Get-VMHost | format-table
		Disconnect-VIServer -Server * -Force -confirm:$false
}

function ESXLSIVib {
foreach ($ESX in $ESXHosts)
		{	
		Connect-VIServer -Server $ESX -User root -Password $ESXpw -Force
        $ESXCLI = Get-ESXCLI -VMhost $ESX
        $vibs = $ESXCLI.software.vib.list()
        foreach ($vib in $vibs) { 
            if ($vib.Name -like "*lsi-mr3*") {
                write-host $vib.Name, $vib.Version
            }
        }
		Disconnect-VIServer -Server * -Force -confirm:$false
		}

}

function ESXMaintenanceModeCheck {
foreach ($ESX in $ESXHosts)
		{	
		Connect-VIServer -Server $ESX -User root -Password $ESXpw -Force
        $ESXCLI = Get-ESXCLI -VMhost $ESX
        $ESXCLI.system.maintenanceMode.get()
       	Disconnect-VIServer -Server * -Force -confirm:$false
		}

}

function ESXDiskCount {
foreach ($ESX in $ESXHosts)
		{	
		echo y | .\plink root@$ESX -pw $ESXpw ls /dev/disks | grep naa -c
		}
		
}


function DellStorageVersion {


foreach ($IDRAC in $IDRACs)
		{
		$stcont = racadm -r $IDRAC -u root -p $IDRACpw storage get controllers -o | select-string -pattern "FirmwareVersion                  = 25"
		Write-Host "$($IDRAC): $($stcont)"
		}

}



function DellBIOSVersion {


foreach ($IDRAC in $IDRACs)
		{
		$bios = racadm -r $IDRAC -u root -p $IDRACpw getversion -b | select-string -pattern "BIOS"
		Write-Host "$($IDRAC): $($bios)"
		}

}

function ResetDellServer {


foreach ($IDRAC in $IDRACs)
		{
		Write-Host "Resetting Sever: $($IDRAC)"
		racadm -r $IDRAC -u root -p $IDRACpw serveraction powercycle
		
		}

}


function ResetIDRAC {


foreach ($IDRAC in $IDRACs)
		{
		Write-Host "Resetting iDRAC: $($IDRAC)"
		racadm -r $IDRAC -u root -p $IDRACpw racreset
		
		}

}

function CheckSystemModel {


foreach ($IDRAC in $IDRACs)
		{
		$sysmod = racadm -r $IDRAC -u root -p $IDRACpw getsysinfo | select-string -pattern "System Model"
		Write-Host "$($IDRAC): $($sysmod)"
		
		}

}

function GetPerformanceProfile {


foreach ($IDRAC in $IDRACs)
		{
		$perfpro = racadm -r $IDRAC -u root -p $IDRACpw get BIOS.SysProfileSettings.Sysprofile | select-string -pattern "Sysprofile="
		Write-Host "$($IDRAC): $($perfpro)"
		
		}

}


function SetPerformanceProfile {


foreach ($IDRAC in $IDRACs)
		{
		Write-Host "Setting Profile for $($IDRAC)"
		racadm -r $IDRAC -u root -p $IDRACpw set BIOS.SysProfileSettings.Sysprofile PerfOptimized
		racadm -r $IDRAC -u root -p $IDRACpw jobqueue create BIOS.Setup1-1
		racadm -r $IDRAC -u root -p $IDRACpw serveraction powercycle
		}

}

function SetPowerSupplyRedundancy {


foreach ($IDRAC in $IDRACs)
		{
		Write-Host "Setting Profile for $($IDRAC)"
		racadm -r $IDRAC -u root -p $IDRACpw set System.Power.Hotspare.Enable 0
		}

}

function NUMACheck {


foreach ($IDRAC in $IDRACs)
		{
		Write-Host "Setting Profile for $($IDRAC)"
		racadm -r $IDRAC -u root -p $IDRACpw get BIOS.MemSettings.NodeInterleave
		}

}

function LoadPM {
$PMlocation = Read-Host -Prompt 'Provide file path'

foreach ($IDRAC in $IDRACs)
		{
		Write-Host "Loading PM on $($IDRAC)"
		racadm -r $IDRAC -u root -p $IDRACpw update -f $PMlocation
		racadm -r $IDRAC -u root -p $IDRACpw serveraction powercycle
		}
}

function iDRACUpdate {
$FWlocation = Read-Host -Prompt 'Provide file path'

foreach ($IDRAC in $IDRACs)
		{
		Write-Host "Updating iDRAC on $($IDRAC)"
		racadm -r $IDRAC -u root -p $IDRACpw fwupdate -u -p -d $FWlocation
		}
}

function ExportConfig {

foreach ($IDRAC in $IDRACs)
		{
		Write-Host "Exporting configuration on $($IDRAC)"
		racadm -r $IDRAC -u root -p $IDRACpw get -f .\drac_cfg\$IDRAC.xml
		}
}



function MapiDracESXi {


foreach ($IDRAC in $IDRACs)
		{
		$hostname = racadm -r $IDRAC -u root -p $IDRACpw getsysinfo | select-string -pattern "Host Name"
		Write-Host "$($IDRAC): $($hostname)"
		
		}

}



function LookupPW {
echo y | .\plink root@$VRMip -pw $VRMpw /home/vrack/bin/vrm-cli.sh --lookup-password

}
function RotatePW {
echo y | .\plink root@$VRMip -pw $VRMpw /home/vrack/bin/vrm-cli.sh --rotate-all

}

function FakeRotatePW {
echo y | .\plink root@$VRMip -pw $VRMpw /home/vrack/bin/vrm-cli.sh --rotate-all-fake

}
function SOSHC {
echo y | .\plink root@$VRMip -pw $VRMpw /opt/vmware/evosddc-support/sos --health-check

}



function Menu {
Do {
@'
--------------------------------------------------------------
Main Menu
--------------------------------------------------------------
1. ESXi
2. iDRAC
3. SDDC Manager
--------------------------------------------------------------
 
'@
 
    $MainMenu = Read-Host -Prompt 'Enter 1 - 3 or Q to quit'
    Switch ($MainMenu) {
        1 {
            Do {
@'

--------------------------------------------------------------
ESXi Menu
--------------------------------------------------------------
1. Check ESXi listenting on Port 902
2. Reboot ESXi
3. Shutdown ESXi
4. Enter Maintenance Mode
5. Exit Maintenance Mode
6. Get ESXi Host Status
7. Get LSI VIB
8. Check if Hosts in Maintenance Mode
--------------------------------------------------------------
 
'@
    $ESXMenu = Read-Host -Prompt 'Enter 1 - 8 or B for Back'
	
	Switch ($ESXMenu) {
        1 {Port902}
		2 {ESXReboot}
		3 {ESXShutdown}
		4 {ESXEnterMaintMode}
		5 {ESXExitMaintMode}
		6 {ESXHostStatus}
        7 {ESXLSIVib}
        8 {ESXMaintenanceModeCheck}
		}
	
	} Until (
    $ESXMenu -eq 'B'
)
      }
	}
	

	
	
	    Switch ($MainMenu) {
        2 {
            Do {
@'
 
--------------------------------------------------------------
iDRAC Menu
--------------------------------------------------------------
1.  Get BIOS Version
2.  Get Storage Controller Version
3.  Reset Server
4.  Reset iDRAC
5.  Display System Model
6.  Get BIOS Performance Profile
7.  Set BIOS Performance Profile to Performance
8.  Update FW or Load Personality Module
9.  Update iDRAC
10. Export Config
11. Map iDRAC to ESXi Hostname
12. Set Power Supply Redundancy Hot Spare PSU to Disable
13. Check Node Interleaving Disabled
--------------------------------------------------------------
 
'@
    $DellMenu = Read-Host -Prompt 'Enter 1 - 13 or B for Back'
	Switch ($DellMenu) {
        1 {DellBIOSVersion}
		2 {DellStorageVersion}
		3 {ResetDellServer}
		4 {ResetIDRAC}
		5 {CheckSystemModel}
		6 {GetPerformanceProfile}
		7 {SetPerformanceProfile}
		8 {LoadPM}
		9 {iDRACUpdate}
		10 {ExportConfig}
		11 {MapiDracESXi}
        12 {SetPowerSupplyRedundancy}
        13 {NUMACheck}
		}
	
	} Until (
    $DellMenu -eq 'B'
)
      }
	}
	
	Switch ($MainMenu) {
        3 {
            Do {@'
 
--------------------------------------------------------------
SDDC Manager 
--------------------------------------------------------------
1. Lookup Passwords
2. Rotate Passwords
3. Fake Rotate Passwords
4. Run SoS Health Check
--------------------------------------------------------------
 
'@
    $VRMMenu = Read-Host -Prompt 'Enter 1 - 4 or B for Back'
	Switch ($VRMMenu) {
        1 {LookupPW}
		2 {RotatePW}
		3 {FakeRotatePW}
		4 {SOSHC}
		}
	
	} Until (
    $VRMMenu -eq 'B'
)
      }
	}
	
	  
} Until (
    $MainMenu -eq 'Q'
)
}

@'
--------------------------------------------------------------
|Select stage
--------------------------------------------------------------
1. Pre Second Boot
2. Post Second Boot
--------------------------------------------------------------
 
'@
 
    $MainMenu = Read-Host -Prompt 'Enter 1 - 2'
    Switch ($MainMenu) {
        1 {
                [xml]$ConfigFile = Get-Content settings_pre_2nd_boot.xml
            }
        2 {
                [xml]$ConfigFile = Get-Content settings_post_2nd_boot.xml
            }
    }

$ESXHosts = $ConfigFile.Settings.IPs.ESX
$IDRACs = $ConfigFile.Settings.IPs.IDRAC
$IDRACpw = $ConfigFile.Settings.Passwords.IDRAC
$ESXpw = $ConfigFile.Settings.Passwords.ESX
$VRMip = $ConfigFile.Settings.IPs.VRM
$VRMpw = $ConfigFile.Settings.Passwords.VRM

Menu

