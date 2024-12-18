<#pulls LAPS password for specified device and opens a powershell session
requires DeviceLocalCredential.Read.All, Device.Read.All
#>
param($ComputerName,$AdminUser)

Connect-MgGraph -TenantID "<placeholder>" -ClientID "<placeholder>" #use your auth method of choice

$errorReason = ""

function Get-EntraDevice{
param($ComputerName)

    $URI = "https://graph.microsoft.com/beta/devices?filter=displayName eq '$ComputerName'"

    $result = Invoke-MgGraphRequest -Uri $URI -Method GET
    if ($result.value){return $result.value}
    $errorReason = "Unable to find Entra Device"
    return $null
}
 
function Get-EntraDeviceLapsPassword{
param($ComputerName)

    $device = Get-EntraDevice -ComputerName $ComputerName

    if ($null -ne $device){
        $id = $device.deviceID
        $URI = "https://graph.microsoft.com/beta/directory/deviceLocalCredentials/"+"$id"+"?`$select=credentials"
        $result = Invoke-MgGraphRequest -Uri $URI -Method GET
        if ($result.credentials){
            $decoded = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($result.credentials[0]['passwordBase64']))
            return $decoded
        }
    }
    $errorReason = "Unable to find Entra Device LAPS Credentials"
    return $null
}

Function New-EntraDevicePSSession{
param($ComputerName)

    $username = $Computername + "\$Adminuser"
    $password = Get-EntraDeviceLapsPassword -ComputerName $ComputerName | ConvertTo-SecureString -AsPlainText -Force

    if ($null -ne $password) {
        [pscredential]$credObject = New-Object System.Management.Automation.PSCredential ($userName, $password)

        return new-pssession -ComputerName $ComputerName -Credential $credObject
    }
    $errorReason = "Unable to create PS Session"
    return $null
}

$session = New-EntraDevicePSSession -ComputerName $ComputerName

if ($null -ne $session) {

    enter-pssession $session

} else {Write-Output $errorReason}

#don't forget to remove the pssession $session when you are done :)
