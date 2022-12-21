$ErrorActionPreference = 'Stop'

if (Get-Module -Name @('AWS.Tools.Common', 'AWS.Tools.SecretsManager') -ListAvailable) {
    Import-Module -Name @('AWS.Tools.Common', 'AWS.Tools.SecretsManager')
} elseif (($PSEdition -eq 'Desktop') -and (Get-Module -Name 'AWSPowerShell' -ListAvailable)) {
    Import-Module -Name 'AWSPowerShell'
} elseif (Get-Module -Name 'AWSPowerShell.NetCore' -ListAvailable) {
    Import-Module -Name 'AWSPowerShell.NetCore'
} else {
    throw 'One of the AWS Tools for PowerShell modules must be available for import.'
}

function Get-AWSSecret
{
    param (
        [string] $Name
    )

    if(Test-AWSSecret -Name $Name)
    {
        Get-SECSecretValue -SecretId $Name -ErrorAction Stop
    }
}

function Test-AWSSecret
{
    param (
        [string] $Name
    )

    if(@(Get-SECSecretList -ErrorAction Stop| Where-Object{$_.Name -eq $Name}).Count -eq 1){
        $true
    }else{
        $false
    }
}

function Get-Secret
{
    param (
        [string] $Name,
        [hashtable] $AdditionalParameters
    )

    if ([WildcardPattern]::ContainsWildcardCharacters($Name))
    {
        throw "The Name parameter cannot contain wild card characters."
    }

    $awsSecret = $(Get-AWSSecret -Name $Name)

    if($awsSecret){
        if($awsSecret.SecretBinary){
            $Array = ($awsSecret.SecretBinary).ToArray()

            return @(,$Array)
        }else{
            $json = $awsSecret.SecretString | ConvertFrom-Json
            if($json.PSType -eq "String"){
                return $json.String

            }elseif($json.PSType -eq "SecureString"){
                return ConvertTo-SecureString $json.SecureString -AsPlainText -Force

            }elseif($json.PSType -eq "PSCredential"){
                $clearPassword = ConvertTo-SecureString $json.Password -AsPlainText -Force
                return New-Object System.Management.Automation.PSCredential ($json.UserName, $clearPassword)

            }elseif($json.PSType -eq "HashTable"){
                $returnHT = @{}

                if($PSEdition -eq 'Desktop'){
                    $json.psobject.properties| Foreach-Object {
                        $returnHT.Add($_.Name,$_.Value)
                    }
                }
                else{
                    $returnHT = ConvertFrom-Json $awsSecret.SecretString -AsHashtable
                }

                $returnHT.Remove('PSType')
                return $returnHT

            }
        }
    }
}


function Set-Secret
{
    param (
        [string] $Name,
        [object] $Secret,
        [hashtable] $AdditionalParameters
    )


    if(Get-AWSSecret -Name $Name){
        Write-Error "Secret name, $Name, is already used in this vault."
        return $false
    }

    if ($Secret -is [PSCredential]){
        $returnJson = @{
            'UserName'=$Secret.UserName;
            'Password'=$Secret.GetNetworkCredential().Password
            'PSType'='PSCredential'
        } | ConvertTo-Json

    }elseif($Secret -is [String]){
        $returnJson = @{
            'String'=$Secret;
            'PSType'='String'
        } | ConvertTo-Json

    }elseif($Secret -is [HashTable]){
        $returnJson = $Secret | Add-Member -NotePropertyName PSType -NotePropertyValue 'HashTable' -PassThru | ConvertTo-json

    }elseif($Secret -is [Byte[]]){
        $returnByteArray = $Secret

    }elseif($Secret -is [SecureString]){
        $password = [System.Net.NetworkCredential]::new("", $Secret).Password
        $returnJson = @{
            'SecureString'=$password
            'PSType'='SecureString'
        } | ConvertTo-Json

    }else{
        Write-Error "Unsupported type passed, please use PSCredential,String,HashTable,SecureString or ByteArray."
        return $false
    }

    Try{
        $newECSecretparams= @{
            'Name' = $Name
            'ErrorAction' = 'Stop'
        }

        if($returnJson){
            $newECSecretparams.Add('SecretString', $returnJson)
        }else{
            $newECSecretparams.Add('SecretBinary', $returnByteArray)
        }

        New-SECSecret @newECSecretparams | Out-Null

        return $true
    }
    catch{
        Write-Error $_
        return $false
    }

}

function Remove-Secret
{
    param (
        [string] $Name,
        [hashtable] $AdditionalParameters
    )

    if ([WildcardPattern]::ContainsWildcardCharacters($Name))
    {
        throw "The Name parameter cannot contain wild card characters."
    }

    if(!(Get-AWSSecret -Name $Name)){
        Write-Error "Secret name, $Name, does not exist."
        return $false
    }

    try{
        Remove-SECSecret -SecretId $Name -ErrorAction Stop -Confirm:$false | Out-Null
    }Catch{
        throw $_
        return $false
    }

    return $true
}

function Get-SecretInfo
{
    param(
        [string] $Filter,
        [hashtable] $AdditionalParameters
    )

    if ([string]::IsNullOrEmpty($Filter)) { $Filter = "*" }

    Get-SECSecretList -ErrorAction Stop | Where-Object{$_.Name -like $Filter } | ForEach-Object{
        $name = $_.Name

        $returnObject = [pscustomobject] @{
            Name = $name
        }

        $awsSecret = $(Get-AWSSecret -Name $Name)

        if($awsSecret.SecretBinary){
            $returnObject | Add-Member -NotePropertyName Value -NotePropertyValue 'ByteArray'
        }else{
            $type = ((Get-AWSSecret -Name $Name).SecretString | ConvertFrom-Json).PsType
            $returnObject | Add-Member -NotePropertyName Value -NotePropertyValue $type
        }

        $ReturnObject
    }

}
