param($ComputerName,$AdminUser)

if ((Get-Item WSMan:\localhost\Client\TrustedHosts).value -ne "<placeholder1>") {Set-Item WSMan:\localhost\Client\TrustedHosts "<placeholder1>"}

Try {
    Connect-MgGraph -TenantId "<placeholder2>" #authentication method of your choice
} Catch {
    Write-Host "Unable to connect to Microsoft Graph"
    Exit 1
}


function Get-EntraDevice{
param($ComputerName)

    $URI = "https://graph.microsoft.com/beta/devices?filter=displayName eq '$ComputerName'"

    $result = Invoke-MgGraphRequest -Uri $URI -Method GET
    if ($result.value){Return $result.value}
    Remove-Variable result
    Disconnect-MgGraph | Out-Null
    Write-Host "Unable to find Entra Device"
    Exit 2
}
 
function Get-EntraDeviceLapsPassword{
param($ComputerName)

    $device = Get-EntraDevice -ComputerName $ComputerName

    if ($null -ne $device){
        $URI = "https://graph.microsoft.com/beta/directory/deviceLocalCredentials/"+$device.deviceID+"?`$select=credentials"
        $result = Invoke-MgGraphRequest -Uri $URI -Method GET
        if ($result.credentials){
            $decoded = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($result.credentials[0]['passwordBase64']))
            Remove-Variable result
            Return $decoded
        }
    }
    Disconnect-MgGraph | Out-Null
    Write-Host "Unable to find Entra Device LAPS Credentials"
    Exit 3
}

function New-EntraDevicePSSession{
param($ComputerName)

    Try {
        $username = $Computername + "\$Adminuser"
        [pscredential]$credObject = New-Object System.Management.Automation.PSCredential ($userName,
                                                                                          $(Get-EntraDeviceLapsPassword -ComputerName $ComputerName `
                                                                                          | ConvertTo-SecureString -AsPlainText -Force -ErrorAction SilentlyContinue))
    
        $session =  new-pssession -ComputerName $ComputerName -Credential $credObject -SessionOption (New-PSSessionOption -IdleTimeout 60000)
        Remove-Variable credObject
        Return $session
    } Catch {
        Disconnect-MgGraph | Out-Null
        Write-Host "Unable to create PS Session"
        Exit 4
    }
}

$session = New-EntraDevicePSSession -ComputerName $ComputerName
Disconnect-MgGraph | Out-Null
if ($null -ne $session) { 
    Enter-PSSession $session
}

#don't forget to remove the pssession $session when you are done :)
