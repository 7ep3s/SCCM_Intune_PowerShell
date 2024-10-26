$action = New-ScheduledTaskAction -Execute "C:\Windows\System32\WindowsPowerShell\v1.0\Powershell.exe" -Argument '-executionpolicy bypass -windowstyle hidden -file "c:\programdata\IntuneExpeditedOnBoardingTask\WaitForOnBoarding.ps1"'

$Trigger = New-ScheduledTaskTrigger -AtLogOn
$Principal = New-ScheduledTaskPrincipal -UserID "$env:username" -LogonType Interactive -RunLevel Highest
$Task = New-ScheduledTask -Action $Action -Trigger $Trigger -Principal $Principal
Register-ScheduledTask -TaskName "Expedite Intune Onboarding" -InputObject $Task