# This script (fairly unfinished) applies licenses to Windows (2008R2 tested) from a text file.



Function Get-FileName($initialDirectory) {  
    [System.Reflection.Assembly]::LoadWithPartialName("System.windows.forms") | Out-Null
    $OpenFileDialog = New-Object System.Windows.Forms.OpenFileDialog
    $OpenFileDialog.initialDirectory = $initialDirectory
    $OpenFileDialog.filter = "All files (*.*)| *.*"
    $OpenFileDialog.ShowDialog() | Out-Null
    $OpenFileDialog.filename
}

#$keys = New-Object System.Collections.ArrayList
$tscr = Get-Credential
$adc = Get-Credential
$Computers = Get-Content (Get-FileName -initialDirectory "c:\")
#$temp = Get-Content (Get-FileName -initialDirectory "c:\")
#$outfile = Get-FileName -initialDirectory "c:\"

ForEach ($i in $temp) {[void]$keys.add($i);[void]$keys.add($i)}

Function Start-Activations {
   $i = 0
   ForEach ($Computer in $Computers) {
        $key = $keys[$i]
        If ($Computer -like "sbx*") {
            $tmp = gwmi -query "select * from SoftwareLicensingProduct" -computername $Computer -credential $tscr
            If ($tmp[8].LicenseStatus -eq 0) {
                $Service = gwmi -query "select * from SoftwareLicensingService" -computername $Computer -credential $tscr
                $Service.InstallProductKey($key)
                $Service.RefreshLicenseStatus()
            }
        } Else {
            $tmp = gwmi -query "select * from SoftwareLicensingProduct" -computername $Computer -credential $adc
            If ($tmp[8].LicenseStatus -eq 0) {
                $Service = gwmi -query "select * from SoftwareLicensingService" -computername $Computer -credential $adc
                $Service.InstallProductKey($key)
                $Service.RefreshLicenseStatus()
            }
        }
        $i = $i + 1
        #$out = $computer + "`t" + $key
        #$out | Out-File -FilePath $outfile -Append
    }

    ForEach ($Computer in $Computers) {
        If ($computer -like "sbx*") {
            $Activate = gwmi -query "select * from SoftwareLicensingProduct" -computername $Computer -credential $tscr
        } Else {
            $Activate = gwmi -query "select * from SoftwareLicensingProduct" -computername $Computer -credential $adc
        }
        $Activate[8].Activate()
        $out = $Activate[8].LicenseStatus
        write-output $computer + "`t" + $out
    }
}
Function Check-LStatus {
    ForEach ($Computer in $Computers) {
        If ($computer -like "sbx*") {
            $Activate = gwmi -query "select * from SoftwareLicensingProduct" -computername $Computer -credential $tscr
        } Else {
            $Activate = gwmi -query "select * from SoftwareLicensingProduct" -computername $Computer -credential $adc
        }
        $out = $Computer + "`t" + $Activate[8].LicenseStatus
        write-output $out
    }
}