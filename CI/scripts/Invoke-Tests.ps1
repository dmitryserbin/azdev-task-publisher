[CmdletBinding()]
Param
(
	[Parameter(Mandatory=$True)]
	[String]$Path,

	[Parameter(Mandatory=$False)]
	[String]$TaskSdkVersion = "0.11.0",

	[Parameter(Mandatory=$False)]
	[String]$PesterVersion = "5.3.3"
)

$TaskSdkInstalled = Get-InstalledModule `
	-Name VstsTaskSdk `
	-MinimumVersion $TaskSdkVersion `
	-ErrorAction SilentlyContinue

$PesterInstalled = Get-InstalledModule `
	-Name Pester `
	-MinimumVersion $PesterVersion `
	-ErrorAction SilentlyContinue

if (-not $TaskSdkInstalled)
{
	Install-Module `
		-Name VstsTaskSdk `
		-Repository PSGallery `
		-MinimumVersion $TaskSdkVersion `
		-AllowClobber `
		-Force `
		-ErrorAction Stop `
		-WarningAction SilentlyContinue
}

if (-not $PesterInstalled)
{
	Install-Module `
		-Name Pester `
		-Repository PSGallery `
		-MinimumVersion $PesterVersion `
		-AllowClobber `
		-Force `
		-ErrorAction Stop `
		-WarningAction SilentlyContinue
}

$Configuration = New-PesterConfiguration
$Configuration.Run.Path = $Path
$Configuration.Run.Exit = $True
$Configuration.TestResult.Enabled = $True
$Configuration.TestResult.OutputPath = "results.xml"
$Configuration.TestDrive.Enabled = $False
$Configuration.TestRegistry.Enabled = $False
$Configuration.Output.Verbosity = "Detailed"
$Configuration.Output.StackTraceVerbosity = "Full"
$Configuration.Output.CIFormat = "AzureDevops"
$Configuration.Should.ErrorAction = "Stop"

$Results = Invoke-Pester -Configuration $Configuration

if ($Results.FailedCount -gt 0)
{
	Write-Output $Results

	throw "Tests failed"
}
