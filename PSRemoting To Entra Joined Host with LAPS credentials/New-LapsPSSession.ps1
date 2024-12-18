<#pulls LAPS password for specified device and opens a powershell session
requires DeviceLocalCredential.Read.All, Device.Read.All
#>
param($ComputerName,$AdminUser)

#you might also need to change your WSMan Trusted Hosts
if ((get-item WSMan:\localhost\Client\TrustedHosts).value -ne "*") {set-item WSMan:\localhost\Client\TrustedHosts "<placeholder>"}

Connect-MgGraph -TenantID "<placeholder>" -ClientID "<placeholder>" #use your auth method of choice

function Get-EntraDevice {
param($ComputerName)

    $URI = "https://graph.microsoft.com/beta/devices?filter=displayName eq '$ComputerName'"

    $result = Invoke-MgGraphRequest -Uri $URI -Method GET
    if ($result.value){return $result.value}
    Write-Host "Unable to find Entra Device"
    Exit 1
}
 
function Get-EntraDeviceLapsPassword {
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
    Write-Host "Unable to find Entra Device LAPS Credentials"
    Exit 2
}

Function New-EntraDevicePSSession {
param($ComputerName)

    $username = $ComputerName + "\$Adminuser"
    $password = Get-EntraDeviceLapsPassword -ComputerName $ComputerName | ConvertTo-SecureString -AsPlainText -Force -ErrorAction SilentlyContinue

    if ($null -ne $password) {
        [pscredential]$credObject = New-Object System.Management.Automation.PSCredential ($userName, $password)

        return New-PSSession -ComputerName $ComputerName -Credential $credObject
    }
    Write-Host "Unable to create PS Session"
    Exit 3
}

$session = New-EntraDevicePSSession -ComputerName $ComputerName

if ($null -ne $session) {

    Enter-PSSession $session

}

#don't forget to remove the pssession when you are done :)
