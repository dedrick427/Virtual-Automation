Function Enable-vmwSSH {
    Get-VMHost | ForEach {           
        $Serv = Get-VMHostService $_ | Where {$_.Key -eq "TSM-SSH"}
        If ($serv.Running -eq $FALSE) {
            Start-VMHostService $serv -confirm:$FALSE
        }
    }
}

Function Disable-vmwSSH {
    Get-VMHost | ForEach {           
        $Serv = Get-VMHostService $_ | Where {$_.Key -eq "TSM-SSH"}
        If ($serv.Running -eq $TRUE) {
            Stop-VMHostService $serv -confirm:$FALSE
        }
    }
}