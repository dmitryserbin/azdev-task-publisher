$TaskPath = Join-Path `
    -Path PublisherV1 `
    -ChildPath task.ps1

Import-Module `
    -Name VstsTaskSdk `
    -Prefix Vsts `
    -ArgumentList @{ NonInteractive = $True } `
    -ErrorAction Stop

Describe "Task" {

    BeforeEach {

        $EndpointType = "service"
        $ServiceName = "ConnectedService"
        $EndpointName = "MyEndpoint"
        $ServiceEndpoint = @{
            Url = "http://dev.azure.com/MyAccount"
            Auth = @{
                Parameters = @{
                    ApiToken = "MyPassword"
                }
            }
        }
    
        $TaskPath = "MyTaskPath"
        $ArtifactsPath = "MyArtifactsPath"
        $Patch = $False
        $Preview = $False
        $Replace = $False

    }

    it "Runs with parameters" {

        Mock `
            -CommandName Get-VstsInput `
            -MockWith { $EndpointType } `
            -Verifiable
            
        Mock `
            -CommandName Get-VstsInput `
            -ParameterFilter { $Name -eq $ServiceName } `
            -MockWith { $EndpointName } `
            -Verifiable

        Mock `
            -CommandName Get-VstsEndpoint `
            -ParameterFilter { $Name -eq $EndpointName } `
            -MockWith { $ServiceEndpoint } `
            -Verifiable

        Mock `
            -CommandName Get-VstsInput `
            -ParameterFilter { $Name -eq "TaskPath" } `
            -MockWith { $TaskPath } `
            -Verifiable

        Mock `
            -CommandName Get-VstsInput `
            -ParameterFilter { $Name -eq "ArtifactsPath" } `
            -MockWith { $ArtifactsPath } `
            -Verifiable

        Mock `
            -CommandName Get-VstsInput `
            -ParameterFilter { $Name -eq "Patch" } `
            -MockWith { $Patch } `
            -Verifiable

        Mock `
            -CommandName Get-VstsInput `
            -ParameterFilter { $Name -eq "Preview" } `
            -MockWith { $Preview } `
            -Verifiable

        Mock `
            -CommandName Get-VstsInput `
            -ParameterFilter { $Name -eq "Replace" } `
            -MockWith { $Replace } `
            -Verifiable

        Mock `
            -CommandName Test-Path `
            -ParameterFilter { $Path -eq $TaskPath } `
            -MockWith { $True } `
            -Verifiable

        Mock `
            -CommandName Get-Command `
            -ParameterFilter { $Name -eq "tfx" } `
            -MockWith { $True } `
            -Verifiable

        Mock `
            -CommandName Invoke-Command `
            -Verifiable

        { & /Users/dmitryserbin/Development/github/azdev-task-publisher/PublisherV1/task.ps1 } | Should -Not -Throw

        Assert-MockCalled `
            -CommandName Get-VstsInput `
            -ParameterFilter { $Name -eq "EndpointType" } `
            -Times 1

        Assert-MockCalled `
            -CommandName Get-VstsInput `
            -ParameterFilter { $Name -eq $ServiceName } `
            -Times 1

        Assert-MockCalled `
            -CommandName Get-VstsEndpoint `
            -ParameterFilter { $Name -eq $EndpointName } `
            -Times 1

        Assert-MockCalled `
            -CommandName Get-VstsInput `
            -ParameterFilter { $Name -eq "TaskPath" } `
            -Times 1

        Assert-MockCalled `
            -CommandName Get-VstsInput `
            -ParameterFilter { $Name -eq "ArtifactsPath" } `
            -Times 1

        Assert-MockCalled `
            -CommandName Get-VstsInput `
            -ParameterFilter { $Name -eq "Patch" } `
            -Times 1

        Assert-MockCalled `
            -CommandName Get-VstsInput `
            -ParameterFilter { $Name -eq "Preview" } `
            -Times 1

        Assert-MockCalled `
            -CommandName Get-VstsInput `
            -ParameterFilter { $Name -eq "Replace" } `
            -Times 1
        
        Assert-MockCalled `
            -CommandName Test-Path `
            -ParameterFilter { $Path -eq $TaskPath } `
            -Times 1

        Assert-MockCalled `
            -CommandName Get-Command `
            -ParameterFilter { $Name -eq "tfx" } `
            -Times 1

        Assert-MockCalled `
            -CommandName Invoke-Command `
            -Times 1
    }
}