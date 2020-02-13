properties {
    # Disable "compiling" module into monolithinc PSM1.
    # This modifies the default behavior from the "Build" task
    # in the PowerShellBuild shared psake task module
    $PSBPreference.Build.CompileModule = $false
}

task default -depends PesterModule

task BuildModule -depends Clean{
    Copy-Item $env:BHPSModulePath $env:BHBuildOutput -Recurse
}

task PesterModule -depends BuildModule {
    Remove-Module $env:BHProjectName -ErrorAction SilentlyContinue -Verbose:$false

    $testResultsXml = Join-Path -Path $env:BHBuildOutput -ChildPath 'testResults.xml'
    $testDir = Join-Path -Path $ENV:BHProjectPath -ChildPath 'tests'
    #$testResults = Invoke-Pester -Path $testDir -OutputFile $testResultsXml -OutputFormat NUnitXml
    $testResults = Invoke-Pester -Path $testDir

    if ($testResults.FailedCount -gt 0) {
        $testResults | Format-List
        Write-Error -Message 'One or more Pester tests failed. Build cannot continue!'
    }
} -description 'Run Pester tests'

task Test -FromModule PowerShellBuild -Version '0.4.0'
