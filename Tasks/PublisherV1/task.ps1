[CmdletBinding()]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingWriteHost", "", Justification = "Required by design")]
Param
(

)

try
{
	$EndpointType = Get-VstsInput -Name EndpointType -Require

	switch ($EndpointType)
	{
		integrated
		{
			$ConnectedService = "SYSTEMVSSCONNECTION"
			$TokenParameterName = "AccessToken"
		}
		service
		{
			$ConnectedService = Get-VstsInput -Name ConnectedService -Require
			$TokenParameterName = "ApiToken"
		}
	}

	$ServiceEndpoint = Get-VstsEndpoint -Name $ConnectedService
	$PublishPath = Join-Path -Path $PSScriptRoot -ChildPath Publish.ps1
	$TaskPath = Get-VstsInput -Name TaskPath -Require
	$ArtifactsPath = Get-VstsInput -Name ArtifactsPath -Require
	$Patch = Get-VstsInput -Name Patch -AsBool
	$Preview = Get-VstsInput -Name Preview -AsBool
	$Replace = Get-VstsInput -Name Replace -AsBool

	if (-not $ServiceEndpoint.Url)
	{
		throw "Endpoint <$ConnectedService> missing connection URL"
	}

	if (-not $ServiceEndpoint.Auth.Parameters.$TokenParameterName)
	{
		throw "Endpoint <$ConnectedService> missing token"
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
		Account = ([URI]$ServiceEndpoint.Url).Segments[1]
		Token = $ServiceEndpoint.Auth.Parameters.$TokenParameterName
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
