[CmdletBinding()]
Param
(

)

try
{
	$PublishPath = Join-Path -Path $PSScriptRoot -ChildPath Publish.ps1
	$ConnectedService = Get-VstsInput -Name ConnectedService -Require
	$ServiceEndpoint = Get-VstsEndpoint -Name $ConnectedService
	$TaskPath = Get-VstsInput -Name TaskPath -Require
	$ArtifactsPath = Get-VstsInput -Name ArtifactsPath -Require
	
	$Patch = Get-VstsInput -Name Patch -AsBool
	$Preview = Get-VstsInput -Name Preview -AsBool
	$Replace = Get-VstsInput -Name Replace -AsBool

	if (-not $ServiceEndpoint.Auth.parameters.username)
	{
		throw "Endpoint <$ConnectedService> missing username"
	}

	if (-not $ServiceEndpoint.Auth.parameters.password)
	{
		throw "Endpoint <$ConnectedService> missing password"
	}

	if (-not (Test-Path -Path $TaskPath))
	{
		throw "Directory <$TaskPath> does not exist"
	}

	# Install TFX-CLI
	if (-not (Get-Command -Name tfx -ErrorAction SilentlyContinue))
	{
		Write-Host "##[section] Installing <TFX-CLI> pre-requisites"

		npm install tfx-cli --global --quiet

		if ($LASTEXITCODE -ne 0)
		{
			throw "Error installing NFX-CLI pre-requisites"
		}
	}

	$Parameters = @{
		Path = $TaskPath
		Account = $ServiceEndpoint.Auth.parameters.username
		Token = $ServiceEndpoint.Auth.parameters.password
		Artifacts = $ArtifactsPath
		Replace = $Replace
		Preview = $Preview
	}

	if ($Patch)
	{
		if ($Env:RELEASE_RELEASEID)
		{
			$PatchVersion = $Env:RELEASE_RELEASEID
		}
		elseif ($Env:BUILD_BUILDID)
		{
			$PatchVersion = $Env:BUILD_BUILDID
		}
		else
		{
			throw "Unable to detect patch version variable"
		}

		$Parameters.Add("Patch", $PatchVersion)
	}

	Invoke-Command -ScriptBlock {

		Param
		(
			[Parameter(Mandatory=$True)]
			[String]$Path,

			[Parameter(Mandatory=$True)]
			[Object]$Parameters
		)

		& $Path @Parameters

	} -ArgumentList $PublishPath, $Parameters
}
catch
{
	throw
}
