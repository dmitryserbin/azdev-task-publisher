[CmdletBinding()]
Param
(
	[Parameter(Mandatory=$True)]
	[String]$Path
)

function Save-ModuleVersion
{
	[CmdletBinding()]
	Param
	(
		[Parameter(Mandatory=$True)]
		[String]$Name,

		[Parameter(Mandatory=$True)]
		[String]$Version,

		[Parameter(Mandatory=$True)]
		[String]$Path,
		
		[Parameter(Mandatory=$False)]
		[String]$TempPath = (Join-Path `
			-Path ([IO.Path]::GetTempPath()) `
			-ChildPath (New-Guid).Guid)
	)
	
	$TargetModulePath = Join-Path `
		-Path $Path `
		-ChildPath $Name

	Save-Module `
		-Name $Name `
		-MinimumVersion $ModuleVersion `
		-Repository PSGallery `
		-Path $TempPath `
		-Force `
		-ErrorAction Stop
		
	$ModuleVersionPath = Get-ChildItem `
		-Path (Join-Path -Path $TempPath -ChildPath $Name) `
		-Directory | Select-Object -First 1 -ExpandProperty FullName

	if (-not $ModuleVersionPath)
	{
		throw "Unable to detect <$Name> module source version path"
	}

	if (Test-Path -Path $TargetModulePath)
	{
		Remove-Item `
			-Path $TargetModulePath `
			-Recurse `
			-Force `
			-ErrorAction Stop
	}

	if (-not (Test-Path -Path $TargetModulePath))
	{
		New-Item `
			-Path $TargetModulePath `
			-ItemType Directory `
			-Force `
			-ErrorAction Stop | Out-Null
	}

	Move-Item `
		-Path $ModuleVersionPath\* `
		-Destination $TargetModulePath `
		-Force `
		-ErrorAction Stop

	Remove-Item `
		-Path $TempPath `
		-Recurse `
		-Force `
		-ErrorAction SilentlyContinue
}

Save-ModuleVersion `
	-Name VstsTaskSdk `
	-Version 0.11.0 `
	-Path (Join-Path -Path $Path -ChildPath ps_modules)