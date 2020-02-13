$manifest           = Import-PowerShellDataFile -Path $env:BHPSModuleManifest
$outputDir          = Join-Path -Path $ENV:BHProjectPath -ChildPath 'Output'
$outputModDir       = Join-Path -Path $outputDir -ChildPath $env:BHProjectName
$outputModVerDir    = Join-Path -Path $outputModDir -ChildPath $manifest.ModuleVersion
$outputManifestPath = Join-Path -Path $outputModVerDir -Child "\SecretsManagementExtension\SecretsManagementExtension.psd1"

Describe 'SecretsManagementExtension manifest' {
    Context 'Validation' {

        $script:manifest = $null

        It 'has a valid manifest' {
            {
                $script:manifest = Test-ModuleManifest -Path $outputManifestPath -Verbose:$false -ErrorAction Stop -WarningAction SilentlyContinue
            } | Should Not Throw
        }

        It 'has a  name set to SecretsManagementExtension in the manifest' {
            $script:manifest.Name | Should Be 'ImplementiSecretsManagementExtensiongModule'
        }


        It 'has a valid version in the manifest' {
            $script:manifest.Version -as [Version] | Should Not BeNullOrEmpty
        }


        It 'has a valid guid' {
            {
                [guid]::Parse($script:manifest.Guid)
            } | Should Not throw
        }
    }
}
