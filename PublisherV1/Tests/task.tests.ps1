$ScriptPath = Join-Path `
    -Path PublisherV1 `
    -ChildPath task.ps1

Import-Module `
    -Name VstsTaskSdk `
    -Prefix Vsts `
    -ArgumentList @{ NonInteractive = $True } `
    -ErrorAction Stop

Describe "Task" {

    $ServiceName = "ConnectedService"
    $EndpointName = "MyEndpoint"
    $ServiceEndpoint = @{
        Auth = @{
            parameters = @{
                username = "MyUser"
                password = "MyPassword"
            }
        }
    }

    $TaskPath = "MyTaskPath"
    $ArtifactsPath = "MyArtifactsPath"
    $Patch = $False
    $Preview = $False
    $Replace = $False

    Context "Run task" {

        it "Runs with parameters" {

            Mock Get-VstsInput `
                -ParameterFilter { $Name -eq $ServiceName } `
                -MockWith { $EndpointName } `
                -Verifiable

            Mock Get-VstsEndpoint `
                -ParameterFilter { $Name -eq $EndpointName } `
                -MockWith { $ServiceEndpoint } `
                -Verifiable

            Mock Get-VstsInput `
                -ParameterFilter { $Name -eq "TaskPath" } `
                -MockWith { $TaskPath } `
                -Verifiable

            Mock Get-VstsInput `
                -ParameterFilter { $Name -eq "ArtifactsPath" } `
                -MockWith { $ArtifactsPath } `
                -Verifiable

            Mock Get-VstsInput `
                -ParameterFilter { $Name -eq "Patch" } `
                -MockWith { $Patch } `
                -Verifiable

            Mock Get-VstsInput `
                -ParameterFilter { $Name -eq "Preview" } `
                -MockWith { $Preview } `
                -Verifiable

            Mock Get-VstsInput `
                -ParameterFilter { $Name -eq "Replace" } `
                -MockWith { $Replace } `
                -Verifiable

            Mock Test-Path `
                -ParameterFilter { $Path -eq $TaskPath } `
                -MockWith { $True } `
                -Verifiable

            Mock Get-Command `
                -ParameterFilter { $Name -eq "tfx" } `
                -MockWith { $True } `
                -Verifiable

            Mock Invoke-Command `
                -Verifiable

            { & $ScriptPath } | Should -Not -Throw

            Assert-MockCalled Get-VstsInput `
                -ParameterFilter { $Name -eq $ServiceName } `
                -Times 1

            Assert-MockCalled Get-VstsEndpoint `
                -ParameterFilter { $Name -eq $EndpointName } `
                -Times 1

            Assert-MockCalled Get-VstsInput `
                -ParameterFilter { $Name -eq "TaskPath" } `
                -Times 1

            Assert-MockCalled Get-VstsInput `
                -ParameterFilter { $Name -eq "ArtifactsPath" } `
                -Times 1

            Assert-MockCalled Get-VstsInput `
                -ParameterFilter { $Name -eq "Patch" } `
                -Times 1

            Assert-MockCalled Get-VstsInput `
                -ParameterFilter { $Name -eq "Preview" } `
                -Times 1

            Assert-MockCalled Get-VstsInput `
                -ParameterFilter { $Name -eq "Replace" } `
                -Times 1
            
            Assert-MockCalled Test-Path `
                -ParameterFilter { $Path -eq $TaskPath } `
                -Times 1

            Assert-MockCalled Get-Command `
                -ParameterFilter { $Name -eq "tfx" } `
                -Times 1

            Assert-MockCalled Invoke-Command `
                -Times 1

        }

    }

}