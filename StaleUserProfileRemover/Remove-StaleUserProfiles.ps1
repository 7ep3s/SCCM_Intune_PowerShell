#EXCLUSION LIST
$excluded=("c:\users\administrator","C:\Users\defaultuser1")

#cutoff time to select target profiles for deletion
$CUTOFF = 60

#get profile load times from registry - this is not affected by ntuser.dat metadata changes
$LOAD = Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList\*" |
Select-Object -Property ProfileImagePath,
    @{Name = 'SID';Expression={$_.PSChildName}},
    @{Name = 'LastLogonTime'; Expression={
        if ($_.LocalProfileLoadTimeHigh -and $_.LocalProfileLoadTimeLow) {
            [uint64]$filetime = "0X{0:X8}{1:X8}" -f $_.LocalProfileLoadTimeHigh, $_.LocalProfileLoadTimelow
            [Datetime]::FromFileTime($filetime)
        }
    }}

#get list of logged on users
$QUSER = $null
$ErrorActionPreference = "SilentlyContinue"
try{
    $QUSER = (quser) -replace '\s{2,21}', ',' -replace '>',''
    #to resolve potential issues with non-english locale. thanks microsoft.
    if($QUSER){
        $newheaders = "USERNAME,SESSIONNAME,ID,STATE,IDLETIME,LOGONTIME"
        $QUSER[0] = $newheaders
        }
    $QUSER = $quser | ConvertFrom-Csv
    $QUSER | foreach {
        $_ | Add-Member -MemberType NoteProperty -Name "ProfileImagePath" -Value $("C:\Users\" + $_.USERNAME) -Force
    }
}catch{$quser = $error[0]}
$ErrorActionPreference = "Continue"

$today = get-date

#identify targets
$targets = $LOAD | where {$_.lastlogontime -and $_.lastlogontime -lt $today.AddDays($CUTOFF*-1)`
     -and $_.profileimagepath -notin $QUSER.profileimagepath`
     -and $_.profileimagepath -notin $excluded`
     -and $_.profileimagepath -notlike "C:\windows\*"`
     -and $_.profileimagepath -notlike "C:\users\.NET*"}

#$targets

#uncomment last line to delete target profiles
get-ciminstance win32_userprofile | where {$_.sid -in $targets.sid} | Remove-CimInstance
