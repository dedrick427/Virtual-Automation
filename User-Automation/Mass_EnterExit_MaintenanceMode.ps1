#  I'm insanely impressed by the amount of notation I've included here...


add-pssnapin vmware.vimautomation.core

Function Exit-vmMaintenanceMode {
    [CmdletBinding()]
    Param (
        [Parameter(
            Position = 0,
            HelpMessage="Prefix of the ESXi Host Names.  Default is ESXi, as in ESXi01.vmware.local",
            ValueFromPipeline=$TRUE
        )] $Prefix="ESXi",
        [Parameter(
            Position = 1,
            HelpMessage="Enumeration of ESXi hosts to exit maintenance mode.  Example: `
                To exit maintenance mode on ESXi04 through ESXi10 type 4..10.  Default is 1..10",
            ValueFromPipeline=$TRUE
        )] [array]$Range=01..10,
        [Parameter(
            Position = 2,
            HelpMessage="Suffix of the ESXi Host Name.  Default is .vmware.local, and in ESXi02.vmware.local",
            ValueFromPipeline=$TRUE
        )] $Suffix=".vmware.local",
        [Parameter(
            Position = 3,
            HelpMessage="If set to true, then leading zeros will not be included, as in ESXi1.vmware.local `
                instead of ESXi01.vmware.local",
            ValueFromPipeline=$TRUE
        )] [switch]$NoLeadingZero=$FALSE
    )
    If (!($HOSTCreds)) {
        $HOSTCreds = Get-Credential
    }
    If ($NoLeadingZero -eq $TRUE) {
        $ESXes = $Range | % {$Prefix + $_ + $Suffix}
        } Else {
            $ESXes = $Range | % {$Prefix + ("{0:D2}" -f $_) + $Suffix}
    }
    Connect-VIServer $ESXes -Credential $HOSTCreds
    Get-VMHost -Name $ESXes | Set-VMHost -State Connected -Confirm:$FALSE -RunAsync
    Disconnect-VIServer $ESXes -Confirm:$FALSE
}

#NOTES -
# Examples:
#  Exit-vmMaintenanceMode -Range 04..10
#    This will make hosts ESXI04.vmware.local through ESXi10.vmware.local exit maintenance mode.
#  Exit-vmMaintenanceMode -Range 1,2,6
#    Hosts ESXi01.vmware.local, ESXi02.vmware.local, and ESXi06.vmware.local will exit maintenance mode.
#  Exit-vmMaintenanceMode -Range 1,2,6 + 09..14
#    This is the format to include a range and individual numbers into the ESXi enumeration.
#  Exit-vmMaintenanceMode -Prefix "tstESXi" -Suffix ".sbx.local"
#    Hosts tstESXi01.sbx.local through tstESXi10.sbx.local will exit maintenance mode.
#  Exit-vmMaintenanceMode -NoLeadingZero
#    Hosts ESXi1.vmware.local through ESXi10.vmware.local will exit maintenance mode,
#    without the leading zeros:  ESXi1 instead of ESXi01.