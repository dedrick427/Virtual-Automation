

$tmpBaseDSC = "Winterfell-Base-A01"
$prefix = "7X"
$BaseDSC = "W:\iSCSIDeployments\" + $tmpBaseDSC + ".vhdx"
$ChildDSC = "W:\iSCSIDeployments\" + $prefix + "-" + $tmpBaseDSC + ".vhdx"

$DestHost = "LV-SEC-ESXi13.secave.local"
$tmpRMHost = "LV-SEC-ESXi14.secave.local"
$tmpRNTarget = "esxi13"
$Target = "ESXiXX"

#Remove-IscsiVirtualDiskTargetMapping -TargetName $tmpRNTarget -Path $BaseDSC

#New-IscsiVirtualDisk -Path $ChildDSC -ParentPath $BaseDSC
#Add-IscsiVirtualDiskTargetMapping -Path $ChildDSC -TargetName $Target

#Get-VMHostStorage -VMHost (Get-VMHost $tmpRMHost) -RescanAllHba -RescanVmfs
#Get-VMHostStorage -VMHost (Get-VMHost $DestHost) -RescanAllHba
#$vmfs = Get-ScsiLun -VmHost LV-SEC-ESXi14.secave.local | where {$_.CanonicalName -like "*8c99ed0*"}


Function New-IGTSnap {

    $OHSNAP = "Winterfell-A01"
    $USRENV = "snap_A7X"

    $basePath = "W:\iSCSIDeployments\" + $OHSNAP + ".vhdx"
    $prefix = @((get-date -UFormat "%s").Split("."))[1] + ("{0:X2}" -f (Get-Random -Minimum 0 -Maximum 255))
    $newPath = "W:\iSCSIDeployments\" + $prefix + $OHSNAP + ".vhdx"

    New-IscsiVirtualDisk -ParentPath $basePath -Path $newPath
    Add-IscsiVirtualDiskTargetMapping -TargetName "esxi13" -DevicePath $newPath
    Get-VMHost -name "LV-SEC-ESXi13.secave.local" | Get-VMHostStorage -RescanAllHba

}

Function Mount-Datastore {
	[CmdletBinding()]
	Param (
		[Parameter(ValueFromPipeline=$true)]
		$Datastore
	)
	Process {
		if (-not $Datastore) {
			Write-Host "No Datastore defined as input"
			Exit
		}
		Foreach ($ds in $Datastore) {
			$hostviewDSDiskName = $ds.ExtensionData.Info.vmfs.extent[0].Diskname
			if ($ds.ExtensionData.Host) {
				$attachedHosts = $ds.ExtensionData.Host
				Foreach ($VMHost in $attachedHosts) {
					$hostview = Get-View $VMHost.Key
					$StorageSys = Get-View $HostView.ConfigManager.StorageSystem
					Write-Host "Mounting VMFS Datastore $($DS.Name) on host $($hostview.Name)..."
					$StorageSys.MountVmfsVolume($DS.ExtensionData.Info.vmfs.uuid);
				}
			}
		}
	}
}

Function Register-VMX {
	param(
        $entityName = $null,
        $dsNames = $null,
        $template = $false,
        $ignore = $null,
        $checkNFS = $false,
        $whatif=$false
    )
	If(($entityName -ne $null -and $dsNames -ne $null) -or ($entityName -eq $null -and $dsNames -eq $null)){
		Get-Usage
		break
	}
	If($dsNames -eq $null){
		switch((Get-Inventory -Name $entityName).GetType().Name.Replace("Wrapper","")){
			"Cluster"{
				$dsNames = Get-Cluster -Name $entityName | Get-VMHost | Get-Datastore | where {$_.Type -eq "VMFS" -or $checkNFS} | % {$_.Name}
			}
			"Datacenter"{
				$dsNames = Get-Datacenter -Name $entityName | Get-Datastore | where {$_.Type -eq "VMFS" -or $checkNFS} | % {$_.Name}
			}
			"VMHost"{
				$dsNames = Get-VMHost -Name $entityName | Get-Datastore | where {$_.Type -eq "VMFS" -or $checkNFS} | % {$_.Name}
			}
			Default{
				Get-Usage
				exit
			}
		}
	    } else{
		    $dsNames = Get-Datastore -Name $dsNames | where {$_.Type -eq "VMFS" -or $checkNFS} | Select -Unique | % {$_.Name}
	}

	$dsNames = $dsNames | Sort-Object
	$pattern = "*.vmx"
	if($template){
		$pattern = "*.vmtx"
	}

	foreach($dsName in $dsNames){
		$ds = Get-Datastore $dsName | Select -Unique | Get-View
		$dsBrowser = Get-View $ds.Browser
		$dc = Get-View $ds.Parent
		while($dc.MoRef.Type -ne "Datacenter"){
			$dc = Get-View $dc.Parent
		}
		$tgtfolder = Get-View $dc.VmFolder
		$esx = Get-View $ds.Host[0].Key
		$pool = Get-View (Get-View $esx.Parent).ResourcePool

		$vms = @()
		foreach($vmImpl in $ds.Vm){
			$vm = Get-View $vmImpl
			$vms += $vm.Config.Files.VmPathName
		}
		$datastorepath = "[" + $ds.Name + "]"

		$searchspec = New-Object VMware.Vim.HostDatastoreBrowserSearchSpec
		$searchspec.MatchPattern = $pattern

		$OMGdoSTuff = $dsBrowser.SearchDatastoreSubFolders_Task($datastorePath, $searchSpec)

		$task = Get-View $OMGdoSTuff
		while ("running","queued" -contains $task.Info.State) {
			$task.UpdateViewData("Info.State")
		}
		$task.UpdateViewData("Info.Result")
		foreach ($folder in $task.Info.Result){
			if(!($ignore -and (&{$res = $false; $folder.FolderPath.Split("]")[1].Trim(" /").Split("/") | %{$res = $res -or ($ignore -contains $_)}; $res}))){
				$found = $FALSE
				if($folder.file -ne $null){
					foreach($vmx in $vms){
						if(($folder.FolderPath + $folder.File[0].Path) -eq $vmx) {
							$found = $TRUE
						}
					}
					if (-not $found){
						if($folder.FolderPath[-1] -ne "/"){$folder.FolderPath += "/"}
						$vmx = $folder.FolderPath + $folder.File[0].Path
						if($template){
							$params = @($vmx,$null,$true,$null,$esx.MoRef)
						}
						else{
							$params = @($vmx,$null,$false,$pool.MoRef,$null)
						}
						if(!$whatif){
							$OMGdoSTuff = $tgtfolder.GetType().GetMethod("RegisterVM_Task").Invoke($tgtfolder, $params)
							Write-Host "`t" $vmx "registered"
						}
						else{
							Write-Host "`t" $vmx "registered" -NoNewline; Write-Host -ForegroundColor blue -BackgroundColor white " ==> What If"
						}
					}
				}
			}
		}
		Write-Host "Done"
	}
}