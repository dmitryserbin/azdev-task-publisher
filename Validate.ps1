[CmdletBinding()]
Param
(
	[Parameter(Mandatory=$True)]
	[String]$Path,

	[Parameter(Mandatory=$False)]
	[String]$TaskSdkVersion = "0.11.0",

	[Parameter(Mandatory=$False)]
	[String]$AnalyzerVersion = "1.18.0",

	[Parameter(Mandatory=$False)]
	[String]$PesterVersion = "4.8.0"
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

$Results = Invoke-Pester `
	-Script $Path `
	-OutputFormat NUnitXml `
	-OutputFile TestResults.xml `
	-PassThru

if ($Results.FailedCount -gt 0)
{
	Write-Output $Results

	throw "Tests failed"
}
