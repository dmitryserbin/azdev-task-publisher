[CmdletBinding()]
Param
(
    [Parameter(Mandatory=$True)]
    [String]$Path,

    [Parameter(Mandatory=$True)]
    [String]$Output
)

<#.SYNOPSIS
Save PowerShell module
#>
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

<#.SYNOPSIS
Publish extension package
#>
function Publish-Extension
{
    [CmdletBinding()]
	Param
	(
		[Parameter(Mandatory=$True)]
        [String]$Path,

        [Parameter(Mandatory=$True)]
        [String]$Output,

        [Parameter(Mandatory=$False)]
        [Array]$Exclude = @()
    )
    
    if (-not (Test-Path -Path $Path -PathType Container))
    {
        throw "Directory <$Path> does not exist"
    }

    # Format source path is required
    # To address compatibility issues
    $Path = Resolve-Path -Path $Path | Select-Object `
        -ExpandProperty Path

    if (Test-Path -Path $Output -PathType Container)
    {
        Remove-Item `
            -Path $Output `
            -Recurse `
            -Force `
            -ErrorAction Stop | Out-Null
    }

    if (-not (Test-Path -Path $Output))
    {
        New-Item `
            -Path $Output `
            -ItemType Directory `
            -Force `
            -ErrorAction Stop | Out-Null
    }

    ForEach ($Item in Get-ChildItem -Path $Path -Exclude $Exclude -Recurse)
    {
        $TargetPath = Join-Path `
            -Path $Output `
            -ChildPath ($Item.FullName -replace [Regex]::Escape($Path))

        Copy-Item `
            -Path $Item `
            -Destination $TargetPath `
            -Container:$Item.PSIsContainer `
            -Force `
            -ErrorAction Stop
    }
}

try
{
    Save-ModuleVersion `
        -Name VstsTaskSdk `
        -Version 0.11.0 `
        -Path (Join-Path -Path $Output -ChildPath Modules)

    Copy-Item `
        -Path (Join-Path -Path $Output -ChildPath Modules\VstsTaskSdk) `
        -Destination (Join-Path -Path $Output -ChildPath Extension\PublisherV1\ps_modules) `
        -Container `
        -Force `
        -ErrorAction Stop

    Publish-Extension `
        -Path $Path `
        -Output (Join-Path -Path $Output -ChildPath Extension) `
        -Exclude @(".git*", "*.yaml", "*test*", "Validate.ps1", "Package.ps1")
}
catch
{
    throw
}
