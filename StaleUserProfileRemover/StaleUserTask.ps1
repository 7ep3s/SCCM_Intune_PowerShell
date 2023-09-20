$action = New-ScheduledTaskAction -Execute "Powershell.exe" -Argument "-executionpolicy bypass -windowstyle hidden -file c:\programdata\StaleUserProfileRemover\Remove-StaleUserProfiles.ps1"

$delay = New-TimeSpan -Minutes 2

$trigger = New-ScheduledTaskTrigger -AtLogOn -RandomDelay $delay

Register-ScheduledTask -Action $action -Trigger $trigger -TaskName "Stale User Profile Remover" -Description "Stale User Profile Remover" -User "System"
