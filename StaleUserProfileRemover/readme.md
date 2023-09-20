this script package can be deployed as an sccm application or an intune win32 application

the purpose of this package is to register a scheduled task, that will trigger on user logon and remove any user profiles that haven't logged on for the number of Days specified by the $CUTOFF variable in Remove-StaleUserProfiles.ps1 
