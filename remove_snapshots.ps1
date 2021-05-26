$sender = "vcenter-automation@self.com"
$recipient  = "my@self.com"
$smtp = "mail.myself.com"
$snapAge = -2
$scriptName = $MyInvocation.MyCommand.Name
$vcenter  = "vcenter1"

#Start Transcipt
Start-Transcript -Path ".\Transcripts\$scriptName-Log-$(get-date -Format yyyyddmm_hhmmtt).log" -NoClobber

#LOAD POWERCLI AND CONNECT TO VCENTER
Connect-VIServer $vcenter

# BUILD A LIST OF ALL WEBPROD* WEBDEV* SERVERS
$serverlist = @(Get-VM webdev*)
$serverlist += @(Get-VM webprod*)

foreach ($vm in $serverlist){
    #Get all Snapshots older than 2 days with a name containing 'Scheduled'
    $snaps = Get-VM $vm| Get-Snapshot | Where { $_.Created -lt (Get-Date).AddDays($snapAge) -AND $_.Name -like "*Scheduled*"}
    if($snaps){
        Get-VM $vm| Get-Snapshot | Where { $_.Created -lt (Get-Date).AddDays($snapAge) -and $_.Name -like "*scheduled*"}| Remove-Snapshot -Confirm:$false
        $emailBody ="The following snapshots for $VM have been removed: " + "`n`n $snaps created on " + $snaps.created
        Send-Mailmessage -To $recipient -From $sender -smtpserver $smtp -Subject "$VM Snapshot Removal" -Body $emailBody
    }
    else{
        Send-Mailmessage -To $recipient -From $sender -smtpserver $smtp -Subject "$VM - Found no snapshots" -Body "No Scheduled Snapshots found older than $snapAge days"
    }
}

Stop-Transcript

