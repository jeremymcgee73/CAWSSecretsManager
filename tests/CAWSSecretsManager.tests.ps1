$manifest           = Import-PowerShellDataFile -Path $env:BHPSModuleManifest
$outputDir          = Join-Path -Path $ENV:BHProjectPath -ChildPath 'Output'
$outputModDir       = Join-Path -Path $outputDir -ChildPath $env:BHProjectName
$outputModVerDir    = Join-Path -Path $outputModDir -ChildPath $manifest.ModuleVersion
$outputManifestPath = Join-Path -Path $outputModVerDir -ChildPath "$($ENV:BHProjectName).psd1"
$vaultName = "AWSPesterTest"

Describe 'AWS Secret Extension' {
    BeforeAll {
        Import-Module -Name Microsoft.PowerShell.SecretsManagement
        Get-SecretsVault $vaultName  | Unregister-SecretsVault
        Register-SecretsVault -Name $vaultName -ModuleName $outputManifestPath
    }

    AfterAll {
        Unregister-SecretsVault -Name BinaryTestVault -ErrorAction Ignore
    }

    Context 'Testing Strings' {
        $RandomString = "Blah" + (New-Guid).ToString()
        $secretName = "PesterSecretString" + (New-Guid).ToString()

        It "verifes String write to AWS" {
            Add-Secret -Name $secretName -Secret $RandomString -Vault $vaultName -ErrorVariable err
            $err.Count | Should -Be 0

            $secretString = Get-Secret -Name $secretName -Vault $vaultName -ErrorAction Stop -AsPlainText
            $secretString | Should -BeOfType String

            $secretString | Should -MatchExactly $RandomString
        }

        It "should be listed in Get-SecretInfo" {
            $secretInfoCount = @(Get-SecretInfo -Vault $vaultName | Where-Object{$_.Name -eq $secretName}).Count
            $secretInfoCount | Should -BeExactly 1
        }

        It "should throw error because the secret should already exist." {
            {Add-Secret -Name $secretName -Secret $RandomString -Vault $vaultName -ErrorVariable er -ErrorAction stop} | Should -Throw
        }

        It "verifes String was removed from AWS" {
            Remove-Secret -Name $secretName -Vault $vaultName -ErrorVariable err
            $err.Count | Should -Be 0

            {Get-Secret -Name $secretName -Vault $vaultName -ErrorAction Stop} | Should -Throw -ErrorId 'GetSecretNotFound,Microsoft.PowerShell.SecretsManagement.GetSecretCommand'
        }
    }

    Context 'Testing SecureStrings' {
        $RandomString = "Blah" + (New-Guid).ToString()
        $secretName = "PesterSecretSecureString" + (New-Guid).ToString()

        It "verifes SecureString write to AWS" {

            $pass = ConvertTo-SecureString "P@ssW0rD!" -AsPlainText -Force

            Add-Secret -Name $secretName -Secret $RandomString -Vault $vaultName -ErrorVariable err
            $err.Count | Should -Be 0

            $secretString = Get-Secret -Name $secretName -Vault $vaultName -ErrorAction Stop -AsPlainText
            $secretString | Should -BeOfType String

            $secretString | Should -MatchExactly $RandomString
        }

        It "should be listed in Get-SecretInfo" {
            $secretInfoCount = @(Get-SecretInfo -Vault $vaultName | Where-Object{$_.Name -eq $secretName}).Count
            $secretInfoCount | Should -BeExactly 1
        }

        It "should throw error because the secret should already exist." {
            {Add-Secret -Name $secretName -Secret $RandomString -Vault $vaultName -ErrorVariable er -ErrorAction stop} | Should -Throw
        }

        It "verifes SecureString was removed from AWS" {
            Remove-Secret -Name $secretName -Vault $vaultName -ErrorVariable err
            $err.Count | Should -Be 0

            {Get-Secret -Name $secretName -Vault $vaultName -ErrorAction Stop} | Should -Throw -ErrorId 'GetSecretNotFound,Microsoft.PowerShell.SecretsManagement.GetSecretCommand'
        }
    }

    Context 'Testing Byte Arrays' {
        $secretName = "PesterSecretByteArray" + (New-Guid).ToString()

        It "verifes Byte Arrays write to AWS" {

            $enc = [system.Text.Encoding]::UTF8
            $string = "Byte array yo"
            $byteArray = $enc.GetBytes($string)

            Add-Secret -Name $secretName -Secret $byteArray -Vault $vaultName -ErrorVariable err
            $err.Count | Should -Be 0

            $secretString = Get-Secret -Name $secretName -Vault $vaultName -ErrorAction Stop
            $enc.GetString($secretString)| Should -MatchExactly $string
        }

        It "should be listed in Get-SecretInfo" {
            $secretInfoCount = @(Get-SecretInfo -Vault $vaultName | Where-Object{$_.Name -eq $secretName}).Count
            $secretInfoCount | Should -BeExactly 1
        }

        It "should throw error because the secret should already exist." {
            {Add-Secret -Name $secretName -Secret $RandomString -Vault $vaultName -ErrorVariable er -ErrorAction stop} | Should -Throw
        }

        It "verifes Byte Arrays was removed from AWS" {
            Remove-Secret -Name $secretName -Vault $vaultName -ErrorVariable err
            $err.Count | Should -Be 0

            {Get-Secret -Name $secretName -Vault $vaultName -ErrorAction Stop} | Should -Throw -ErrorId 'GetSecretNotFound,Microsoft.PowerShell.SecretsManagement.GetSecretCommand'
        }
    }

    Context 'Testing Hashtables' {
        $secretName = "PesterSecretHashTable" + (New-Guid).ToString()

        It "verifes Hashtables write to AWS" {

            $hash = @{
                'param1'='secret';
                'param2'='secret2'
            }

            Add-Secret -Name $secretName -Secret $hash -Vault $vaultName -ErrorVariable err
            $err.Count | Should -Be 0

            $secret = Get-Secret -Name $secretName -Vault $vaultName -ErrorAction Stop

            $secret | Should -BeOfType [Hashtable]

            $secret.param1 | Should -MatchExactly $hash.param1
            $secret.param2 | Should -MatchExactly $hash.param2

        }

        It "should be listed in Get-SecretInfo" {
            $secretInfoCount = @(Get-SecretInfo -Vault $vaultName | Where-Object{$_.Name -eq $secretName}).Count
            $secretInfoCount | Should -BeExactly 1
        }

        It "should throw error because the secret should already exist." {
            {Add-Secret -Name $secretName -Secret $RandomString -Vault $vaultName -ErrorVariable er -ErrorAction stop} | Should -Throw
        }

        It "verifes Hashtables was removed from AWS" {
            Remove-Secret -Name $secretName -Vault $vaultName -ErrorVariable err
            $err.Count | Should -Be 0

            {Get-Secret -Name $secretName -Vault $vaultName -ErrorAction Stop} | Should -Throw -ErrorId 'GetSecretNotFound,Microsoft.PowerShell.SecretsManagement.GetSecretCommand'
        }
    }

    Context 'Testing PSCredential' {
        $secretName = "PesterSecretPSCred" + (New-Guid).ToString()
        $RandomUsername = "Username" + (New-Guid).ToString()
        $RandomPassword = "Password" + (New-Guid).ToString()

        It "verifes PScredential was written to AWS" {

            $clearPassword = ConvertTo-SecureString $RandomPassword -AsPlainText -Force
            $pScreds = New-Object System.Management.Automation.PSCredential ($RandomUsername, $clearPassword)

            Add-Secret -Name $secretName -Secret $pScreds -Vault $vaultName -ErrorVariable err
            $err.Count | Should -Be 0

            $secret = Get-Secret -Name $secretName -Vault $vaultName -ErrorAction Stop

            $secret | Should -BeOfType [PSCredential]

            $secret.UserName | Should -MatchExactly $RandomUsername
            $secret.GetNetworkCredential().Password | Should -MatchExactly $RandomPassword

        }

        It "should be listed in Get-SecretInfo" {
            $secretInfoCount = @(Get-SecretInfo -Vault $vaultName | Where-Object{$_.Name -eq $secretName}).Count
            $secretInfoCount | Should -BeExactly 1
        }

        It "should throw error because the secret should already exist." {
            {Add-Secret -Name $secretName -Secret $RandomString -Vault $vaultName -ErrorVariable er -ErrorAction stop} | Should -Throw
        }

        It "verifes PScredential was removed from AWS" {
            Remove-Secret -Name $secretName -Vault $vaultName -ErrorVariable err
            $err.Count | Should -Be 0

            {Get-Secret -Name $secretName -Vault $vaultName -ErrorAction Stop} | Should -Throw -ErrorId 'GetSecretNotFound,Microsoft.PowerShell.SecretsManagement.GetSecretCommand'
        }
    }
}
