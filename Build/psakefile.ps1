$OutputFolder = Join-Path $PSScriptRoot "Output"
$ModuleName = "Plogger"
$ModuleFolder = Join-Path $OutputFolder $ModuleName
$OutputRepository = "$ModuleName-OutputRepository"

Task Default -Depends Build, Test

Task Build -Description "Executes sequence of tasks to build module for testing" -Depends Cleanup, StageFiles, RegRepo, Publish, InstallModule, ImportModule

Task Cleanup -Description "Cleanup environment to prepare for updated version testing" {
    Remove-Module -Name $ModuleName -ErrorAction SilentlyContinue
    Remove-Item $OutputFolder -Force -Recurse -ErrorAction SilentlyContinue
    Unregister-PSRepository $OutputRepository -ErrorAction SilentlyContinue
    Uninstall-Module -Name $ModuleName -ErrorAction SilentlyContinue
}

Task StageFiles -Description "Copy module files from src to ouptut-repository folder" {
    if (-Not (Test-Path $ModuleFolder)) {
        $null = New-Item -ItemType Directory $ModuleFolder
    }
    Copy-Item -Path "..\src\*" -Destination $ModuleFolder -Force
}

Task RegRepo -Description "Register local PS repository for module testing" {
    if (-not (Test-Path $OutputFolder)) {
        $null = New-Item -ItemType Directory $OutputFolder
    }
    if ($null -eq (Get-PSRepository | Where-Object {$_.Name -eq $OutputRepository})) {
        $null = Register-PSRepository -Name $OutputRepository -SourceLocation $OutputFolder -PublishLocation $OutputFolder -InstallationPolicy Trusted
    }
}

Task Publish -Depends RegRepo, StageFiles -Description "Publish module to output-repository" {
    Publish-Module -Path $ModuleFolder -Repository $OutputRepository
}

Task InstallModule -Description "Install compiled module from output-repository" {
    Install-Module -Name $ModuleName -Repository $OutputRepository
}

Task ImportModule -Description "Import compiled module" {
        Import-Module -Name $ModuleName -Global
}

Task Lint -Description "Run PS Script Analyzer to check against agreed style" {
    Write-Host "PSScriptAnalyzer task not implemented"
}

Task Test -Description "Run unit tests" {
    invoke-pester ..\test
}

Task NewRepo -Depends TestProps -Description "Create bitbucket repo" {
    write-host $RepositoryName NewRepo task not implemented
}

Task TestProps -Description "Verify that properties are passed" {
    Assert -conditionToCheck ($null -ne $RepositoryName) -failureMessage "RepositoryName should not be null"
}