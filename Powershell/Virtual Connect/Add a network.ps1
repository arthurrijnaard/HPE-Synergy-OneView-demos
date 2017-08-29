# -------------------------------------------------------------------------------------------------------
#   by lionel.jullien@hpe.com
#   June 2016
#
#   Script to add a network using a VLAN ID to a Synergy environment. 
#   The Virtual Connect/OneView internal name generated by the script is Production-VLANID.
#   The script add the VLAN to the uplinkset and network set present in OneView 
#  
#   This script demonstrates that with a single line of code, we can present easily and quickly a VLAN to all Compute modules present in the Synergy frames managed by OneView 
#        
#   OneView administrator account is required. 
# 
# --------------------------------------------------------------------------------------------------------
   
#################################################################################
#        (C) Copyright 2017 Hewlett Packard Enterprise Development LP           #
#################################################################################
#                                                                               #
# Permission is hereby granted, free of charge, to any person obtaining a copy  #
# of this software and associated documentation files (the "Software"), to deal #
# in the Software without restriction, including without limitation the rights  #
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell     #
# copies of the Software, and to permit persons to whom the Software is         #
# furnished to do so, subject to the following conditions:                      #
#                                                                               #
# The above copyright notice and this permission notice shall be included in    #
# all copies or substantial portions of the Software.                           #
#                                                                               #
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR    #
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,      #
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE   #
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER        #
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, #
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN     #
# THE SOFTWARE.                                                                 #
#                                                                               #
#################################################################################



#################################################################################
#                                Global Variables                               #
#################################################################################

$LIG="LIG-MLAG"
$Uplinkset="M-LAG-Comware"
$Networkprefix="Production-"
$NetworkSet="Production Networks"

# OneView Credentials
$username = "Administrator" 
$password = "password" 
$IP = "192.168.1.110" 




# Import the OneView 3.10 library

Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force

    if (-not (get-module HPOneview.310)) 
    {  
    Import-module HPOneview.310
    }

   
$PWord = ConvertTo-SecureString –String $password –AsPlainText -Force
$cred = New-Object –TypeName System.Management.Automation.PSCredential –ArgumentList $Username, $PWord


# Connection to the Synergy Composer

If ($connectedSessions -and ($connectedSessions | ?{$_.name -eq $IP}))
{
    Write-Verbose "Already connected to $IP."
}

Else
{
    Try 
    {
        Connect-HPOVMgmt -appliance $IP -PSCredential $cred -Verbose| Out-Null
    }
    Catch 
    {
        throw $_
    }
}

               
import-HPOVSSLCertificate -ApplianceConnection ($connectedSessions | ?{$_.name -eq $IP})


clear-host

write-host "`nThe following Production networks are available:"
Get-HPOVNetwork -type Ethernet | where {$_.Name -match $Networkprefix} | % {$_.name}


$VLAN = Read-Host "`n`nEnter the VLAN ID you want to add" 
 

Write-host "`nCreating a Network Production-$VLAN in OneView " -ForegroundColor Yellow 
New-HPOVNetwork -Name "$networkprefix$VLAN" -type Ethernet -vlanID "$VLAN" -VLANType "Tagged" -purpose General -smartLink $True -typicalBandwidth 2500 -maximumBandwidth 10000 | Out-Null

# PAUSE



Write-host ""
Write-host "Adding Network Production-$VLAN to Logical Interconnect Group" -ForegroundColor Yellow
$lig = Get-HPOVLogicalInterconnectGroup -Name $LIG 
$uplink_set = $lig.uplinkSets | where-Object {$_.name -eq $uplinkset} 
$uplink_Set.networkUris += (Get-HPOVNetwork -Name $networkprefix$VLAN).uri
$err = Set-HPOVResource $lig | Wait-HPOVTaskComplete | Out-Null

# PAUSE


# This takes long time ! Average is 6/7mn with 3 frames but we don't need to wait for the demo

Write-host ""
Write-host "Updating all Logical Interconnects from the Logical Interconnect group" -ForegroundColor Yellow

$err = Get-HPOVLogicalInterconnect | Update-HPOVLogicalInterconnect -confirm:$false | Out-Null  #| Wait-HPOVTaskComplete | Out-Null

# As long as the network is detected in the uplinkset we continue
do {
$uplinksetnew= (Get-HPOVUplinkSet -Name $uplinkset).networkUris  | where { $_ -eq $vlanuri }  
   } 
until ($uplinksetnew -eq $vlanuri)



# PAUSE


$vlanuri = (Get-HPOVNetwork -Name $networkprefix$VLAN).uri

Write-host ""
Write-host "Adding Network $networkprefix$vlan in NetworkSet to populate all profiles" -ForegroundColor Yellow



$netset = Get-HPOVNetworkSet -Name $NetworkSet
$netset.networkUris += (Get-HPOVNetwork -Name Production-$VLAN).uri
$add = Set-HPOVNetworkSet $netset | Wait-HPOVTaskComplete | Out-Null


if (

(Get-HPOVNetworkSet -Name $NetworkSet).networkUris  -ccontains $vlanuri
)

{
 Write-host ""
 Write-host "Network VLAN ID $vlan has been added successfully" -ForegroundColor Yellow
 }
 else
 {
 Write-host ""
 Write-Warning "The network VLAN ID $vlan has NOT been added successfully" 
 }
