start-transcript c:\temp\waitforonboarding.txt -Verbose
$logfilepath="C:\Windows\CCM\Logs\CoManagementOnBoardingScript.log"

function WriteToLogFile ($message)
{
    $message +" - "+ (Get-Date).ToString() >> $logfilepath
}
function Get-CoManagementConfigurations {
    $instances = Get-WmiObject -Namespace root\ccm\dcm -Query "Select * from SMS_DesiredConfiguration WHERE DisplayName like 'CoMgmtSettings%'"
    if (!$instances) {return $null}
    return $instances
}

function Invoke-SCCMClientActions {
    WriteToLogFile "Trigger SCCM Client Actions"
    Invoke-WmiMethod -Namespace root\ccm -Class sms_client -Name TriggerSchedule "{00000000-0000-0000-0000-000000000021}"
    Invoke-WmiMethod -Namespace root\ccm -Class sms_client -Name TriggerSchedule "{00000000-0000-0000-0000-000000000022}"
    Invoke-WmiMethod -Namespace root\ccm -Class sms_client -Name TriggerSchedule "{00000000-0000-0000-0000-000000000001}"
    Invoke-WmiMethod -Namespace root\ccm -Class sms_client -Name TriggerSchedule "{00000000-0000-0000-0000-000000000003}"
    Start-Sleep -Seconds 60
    WriteToLogFile "Triggered SCCM Client Actions"
}
 
WriteToLogFile "Script started" 
WriteToLogFile "Waiting for Hybrid Join"
do {
    $AADInfo = Get-Item "HKLM:/SYSTEM/CurrentControlSet/Control/CloudDomainJoin/JoinInfo"
 
    $guids = $AADInfo.GetSubKeyNames()
    foreach ($guid in $guids) {
        $guidSubKey = $AADinfo.OpenSubKey($guid);
        $DeviceDisplayName = ($Null -ne $guidSubKey.GetValue("DeviceDisplayName"))
        Start-Sleep -Seconds 1
    }
} while ($DeviceDisplayName -ne "True")
    WriteToLogFile "Hybrid Joined"

Invoke-SCCMClientActions
 
WriteToLogFile "Retrigger Co-Management task"

$coManagementConfigurations = Get-CoManagementConfigurations
while (!$coManagementConfigurations -or $coManagementConfigurations.displayname.count -eq 1) {
    WriteToLogFile "Awaiting Co-Management Configurations..."
    Invoke-SCCMClientActions
    $coManagementConfigurations = Get-CoManagementConfigurations
}
WriteToLogFile "Co-Management Configurations Available, invoking evaluation..."

foreach ($instance in $coManagementConfigurations) {
    $instanceLog = $instance.Name + ", " + $instance.Version + ", " + $instance.PolicyType
    WriteToLogFile $instanceLog
    Invoke-CimMethod -Namespace root\ccm\dcm -ClassName SMS_DesiredConfiguration -MethodName TriggerEvaluation -Arguments @{"Name" = $instance.Name; "Version" = $instance.Version; "PolicyType" = $instance.PolicyType}
}
WriteToLogFile "Done invoking evaluation of Co-Management Configurations"
 
WriteToLogFile "Waiting for Intune enrollment"
do {
    $MDMEnrollment = $Null -ne (Get-ItemProperty HKLM:\SOFTWARE\Microsoft\Provisioning\OMADM\MDMDeviceID).DeviceClientID
    Start-Sleep -Seconds 1
} while ($MDMEnrollment -ne "True")
    WriteToLogFile "Enrolled in MDM"

Unregister-ScheduledTask -TaskName "Expedite Intune Onboarding" -Confirm:$false
Stop-Transcript