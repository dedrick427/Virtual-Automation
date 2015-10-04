$Data = gwmi win32_volume -Filter "Label = 'Data'"
$Logs = gwmi win32_volume -Filter "Label = 'Logs'"
$Backups = gwmi win32_volume -Filter "Label = 'Backups'"
$TempDB = gwmi win32_volume -Filter "Label = 'TempDB'"
$Count = 0

If (!($Data.DriveLetter -eq "D:")) {
   $Temp = $NULL
   $Temp = gwmi win32_volume -Filter "DriveLetter = 'D:'"
   If ($Temp) {
      $Temp.DriveLetter = "P:"
      $Temp.put()
   }
   $Data.DriveLetter = "D:"
   $Data.put()   
}
If (!($Logs.DriveLetter -eq "L:")) {
   $Logs.DriveLetter = "L:"
   $Logs.put()
}
If (!($Backups.DriveLetter -eq "Z:")) {
   $Backups.DriveLetter = "Z:"
   $Backups.put()
}
If (!($TempDB.DriveLetter -eq "T:")) {
   $TempDB.DriveLetter = "T:"
   $TempDB.put()
}
Write-Host "Completed"

