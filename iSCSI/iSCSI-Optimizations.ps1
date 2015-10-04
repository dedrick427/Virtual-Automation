

add-pssnapin vmware.vimautomation.core
$viServer = Read-Host 'Name or IP Address of ESXi or vCenter'

$cred = Get-Credential
$MaxIOSize = 4
Connect-viserver $viServer -Credential $cred

$ESXiHosts = Get-VMHost
$NumDS = (Get-Datastore).count
$iHBA = ($ESXiHosts[0] | Get-VMhostHBA -type iSCSI).device
$ESXCli = Get-EsxCli -VMHost $ESXiHosts[0]
$LinkSpeed = ($ESXCli.iscsi.networkportal.list($iHBA))[0].CurrentSpeed
ForEach ($ESXiHost in $ESXiHosts) {
    $iSCSIs = $ESXiHost | Get-ScsiLun -CanonicalName "naa.*"
    ForEach ($iSCSI in $iSCSIs) {
        $PathCnt = ($iSCSI | Get-ScsiLunPath).count
        $ioSwitch = [System.Math]::Round($NumDS/$PathCnt)
        $Limit = [System.Math]::Round((($LinkSpeed / 8) / $MaxIOSize))
        If ($ioSwitch -gt $Limit) {$ioSwitch = $Limit}
        If ($iSCSI.MultipathPolicy -ne "RoundRobin") {
            $iSCSI | Set-ScsiLun -MultipathPolicy RoundRobin -CommandsToSwitchPath $ioSwitch
        } Else {
            $iSCSI | Set-ScsiLun -CommandsToSwitchPath $ioSwitch
        }
    }
}
