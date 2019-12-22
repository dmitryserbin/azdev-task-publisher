[CmdletBinding()]
Param
(
	[Parameter(Mandatory=$True)]
	[String]$Path,

	[Parameter(Mandatory=$True)]
	[String]$Account,

	[Parameter(Mandatory=$True)]
	[String]$Token,

	[Parameter(Mandatory=$False)]
	[Switch]$Remove,

	[Parameter(Mandatory=$False)]
	[Switch]$Replace,

	[Parameter(Mandatory=$False)]
	[Int]$Patch,

	[Parameter(Mandatory=$False)]
	[Switch]$Preview,

	[Parameter(Mandatory=$False)]
	[String]$Proxy,

	[Parameter(Mandatory=$False)]
	[String]$Artifacts = $PSScriptRoot
)

<#.SYNOPSIS
Connect to Azure DevOps account
#>
function Connect-AzDevAccount
{
	[CmdletBinding()]
	Param
	(
		[Parameter(Mandatory=$True)]
		[String]$Account,

		[Parameter(Mandatory=$True)]
		[String]$Token,

		[Parameter(Mandatory=$False)]
		[String]$Uri = ("https://dev.azure.com/{0}" -f $Account),

		[Parameter(Mandatory=$False)]
		[String]$Proxy
	)

	try
	{
		Write-Host "Connecting to <$($Account.toUpper())> Azure DevOps account"

		# Validate NPM
		if (-not (Get-Command -Name npm -ErrorAction SilentlyContinue))
		{
			throw "NPM is not installed"
		}

		# Validate TFX-CLI
		if (-not (Get-Command -Name tfx -ErrorAction SilentlyContinue))
		{
			throw "TFX-CLI is not installed"
		}

		$Output = tfx login --auth-type pat --service-url $Uri --token $Token --proxy $Proxy

		if ($LastExitCode -ne 0)
		{
			throw "TFX error occured. $Output"
		}
	}
	catch
	{
		throw "Unable to connect to Azure DevOps account. $_"
	}
}

<#.SYNOPSIS
Get Azure DevOps task by Id
#>
function Get-AzDevTask
{
	[CmdletBinding()]
	Param
	(
		[Parameter(Mandatory=$True)]
		[String]$Id
	)

	try
	{
		$Output = @()

		$TasksList = tfx build tasks list | Out-String

		if ($LastExitCode -ne 0)
		{
			throw "TFX error while retrieving tasks list"
		}

		ForEach ($Task in $TasksList -Split "(?=id\s+:)")
		{
			# Get name
			$Task -match "[^ ]name\s+:\W(?<Name>\w+)" | Out-Null
			$TaskName = $Matches.Name

			# Get ID
			$Task -match "id\s+:\W(?<ID>[\w-]+)" | Out-Null
			$TaskId = $Matches.Id
		
			# Get version
			$Task -match "version\s+:\D(?<Version>[\d\.]+)" | Out-Null
			$TaskVersion = $Matches.Version

			$Output += [PSCustomObject]@{
				Id = $TaskId
				Name = $TaskName
				Version = $TaskVersion
			}
		}

		return `
			($Output | Where-Object { $_.Id -eq $Id } | Select-Object -First 1)
	}
	catch
	{
		throw "Unable to get task details. $_"
	}
}

<#.SYNOPSIS
Publish Azure DevOps task
#>
function Publish-AzDevTask
{
	[CmdletBinding()]
	Param
	(
		[Parameter(Mandatory=$True)]
		[String]$Path,

		[Parameter(Mandatory=$False)]
		[Switch]$Replace
	)

	try
	{
		# Get task details
		$Task = Get-TaskDetails `
			-Path $Path

		if ((Get-AzDevTask -Id $Task.Id) -and $Replace)
		{
			Remove-AzDevTask `
				-Name $Task.Name `
				-Id $Task.Id
		}

		Write-Host "Publishing <$($Task.Name)> ($($Task.Id)) version <$($Task.Version)> task"

		$Output = tfx build tasks upload --task-path $Task.Path

		if ($LastExitCode -ne 0)
		{
			throw "TFX error while publishing task. $Output"
		}
	}
	catch
	{
		throw "Unable to publish task. $_"
	}
}

<#.SYNOPSIS
Remove Azure DevOps task
#>
function Remove-AzDevTask
{
	[CmdletBinding()]
	Param
	(
		[Parameter(Mandatory=$True)]
		[String]$Name,

		[Parameter(Mandatory=$True)]
		[String]$Id
	)

	try
	{
		$TargetTask = Get-AzDevTask `
			-Id $Id

		if (-not $TargetTask)
		{
			Write-Host "Task <$Name> ID <$Id> not found"

			return
		}

		Write-Host "Removing <$($TargetTask.Name)> ($($TargetTask.Id)) version <$($TargetTask.Version)> task"

		$Output = tfx build tasks delete --task-id $TargetTask.Id

		if ($LastExitCode -ne 0)
		{
			throw "TFX error while removing task. $Output"
		}
	}
	catch
	{
		throw "Unable to remove task. $_"
	}
}

<#.SYNOPSIS
Get task details
#>
function Get-TaskDetails
{
	[CmdletBinding()]
	Param
	(
		[Parameter(Mandatory=$True)]
		[String]$Path
	)

	try
	{
		if (-not (Test-Path -Path $Path))
		{
			throw "Task folder <$Path> not found"
		}

		$Path = Convert-Path `
			-Path $Path `
			-ErrorAction Stop

		$JsonPath = Join-Path `
			-Path $Path `
			-ChildPath Task.json

		if (-not (Test-Path -Path $JsonPath))
		{
			throw "Task JSON <$JsonPath> not found"
		}

		$Task = Get-Content `
			-Path $JsonPath `
			-ErrorAction Stop | ConvertFrom-Json -ErrorAction Stop

		if (-not $Task.id)
		{
			throw "Invalid task <$JsonPath> definition"
		}

		return [PSCUstomObject]@{
			Path = $Path
			Name = $Task.name
			Id = $Task.id
			Version = ("{0}.{1}.{2}" -f $Task.Version.Major, $Task.Version.Minor, $Task.Version.Patch)
			Modules = $Task.modules
			Resources = $Task.resources
			Preview = $Task.preview
		}
	}
	catch
	{
		throw "Unable to get task details. $_"
	}
}

<#.SYNOPSIS
Update task patch version
#>
function Update-TaskVersion
{
	[CmdletBinding()]
	Param
	(
		[Parameter(Mandatory=$True)]
		[String]$Path,

		[Parameter(Mandatory=$False)]
		[Int]$Patch,

		[Parameter(Mandatory=$False)]
		[Switch]$Preview
	)

	try
	{
		if (-not (Test-Path -Path $Path))
		{
			throw "Unable to find <$Path> file"
		}

		$Content = Get-Content `
			-Path $Path `
			-Encoding utf8 `
			-ErrorAction Stop

		# Get current version
		$CurrentVersion = ($Content | ConvertFrom-Json -ErrorAction Stop).Version

		# Set preview flag
		$Content = $Content | ForEach-Object `
		{
			$_ -replace '"preview":\s*["]*\w+["]*',('"preview": {0}' -f $Preview.ToString().toLower())
		}

		# Detect patch version
		if (-not $Patch)
		{
			$Patch = ($CurrentVersion.Patch -as [Int]) + 1
		}

		# Set patch version
		$Content = $Content | ForEach-Object `
		{
			$_ -replace '"Patch":.\d*', ('"Patch": {0}' -f $Patch)
		}

		$Content | Out-File `
			-FilePath $Path `
			-Encoding utf8 `
			-Force `
			-ErrorAction Stop
	}
	catch
	{
		throw "Unable to update task version. $_"
	}
}

<#.SYNOPSIS
Update task dependencies
#>
function Update-TaskDependencies
{
	[CmdletBinding()]
	Param
	(
		[Parameter(Mandatory=$True)]
		[String]$Name,

		[Parameter(Mandatory=$True)]
		[String]$Path,

		[Parameter(Mandatory=$False)]
		[Array]$Modules,

		[Parameter(Mandatory=$False)]
		[Array]$Resources,

		[Parameter(Mandatory=$False)]
		[String]$ArtifactsDirectory = $PSScriptRoot
	)

	try
	{
		Write-Host "Updating <$Path> task dependencies"

		$ModulesPath = Join-Path -Path $ArtifactsDirectory -ChildPath Modules
		$ResourcesPath = Join-Path -Path $ArtifactsDirectory -ChildPath Resources

		$TaskModules = Join-Path -Path $Path -ChildPath ps_modules
		$TaskResources = Join-Path -Path $Path -ChildPath resources

		# Modules
		if ($Modules)
		{
			if (Test-Path -Path $TaskModules)
			{
				Remove-Item `
					-Path $TaskModules `
					-Force `
					-Recurse | Out-Null
			}

			New-Item `
				-Path $TaskModules `
				-Type Directory `
				-Force | Out-Null

			ForEach ($Module in $Modules)
			{
				$ModulePath = Join-Path `
					-Path $ModulesPath `
					-ChildPath $Module

				if (-not (Test-Path -Path $ModulePath))
				{
					throw "Module <$ModulePath> not found"
				}

				switch (Test-Path -Path $ModulePath -PathType Container)
				{
					$True
					{
						Copy-Item `
							-Path $ModulePath `
							-Destination $TaskModules `
							-Recurse `
							-Force `
							-ErrorAction Stop
					}
					$False
					{
						Copy-Item `
							-Path $ModulePath `
							-Destination $TaskModules `
							-Force `
							-ErrorAction Stop
					}
				}
			}
		}

		# Resources
		if ($Resources)
		{
			if (Test-Path -Path $TaskResources)
			{
				Remove-Item `
					-Path $TaskResources `
					-Force `
					-Recurse | Out-Null
			}

			New-Item `
				-Path $TaskResources `
				-Type Directory `
				-Force | Out-Null

			ForEach ($Resource in $Resources)
			{
				$ResourcePath = Join-Path `
					-Path $ResourcesPath `
					-ChildPath $Resource

				if (-not (Test-Path -Path $ResourcePath))
				{
					throw "Resource <$ResourcePath> not found"
				}

				Copy-Item `
					-Path $ResourcePath `
					-Destination $TaskResources `
					-Force `
					-Recurse `
					-ErrorAction Stop
			}
		}
	}
	catch
	{
		throw "Unable to update task dependencies. $_"
	}
}

try
{
	Connect-AzDevAccount `
		-Account $Account `
		-Token $Token `
		-Proxy $Proxy

	$Task = Get-TaskDetails `
		-Path $Path

	if ($Remove)
	{
		Remove-AzDevTask `
			-Name $Task.Name `
			-Id $Task.Id

		return
	}

	if ($Task.Modules -or $Task.Resources)
	{
		Update-TaskDependencies `
			-Name $Task.Name `
			-Path $Task.Path `
			-Modules $Task.Modules `
			-Resources $Task.Resources `
			-ArtifactsDirectory $Artifacts
	}

	Update-TaskVersion `
		-Path (Join-Path -Path $Task.Path -ChildPath task.json) `
		-Patch $Patch `
		-Preview:$Preview

	Publish-AzDevTask `
		-Path $Task.Path `
		-Replace:$Replace
}
catch
{
	throw
}
