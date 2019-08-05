# Task Publisher

- [Overview](##Overview)
- [Features](##Features)
- [Prerequisites](##Prerequisites)
- [How To Use](##How-To-Use)
- [Support](##Support)

## Overview

The **Task Publisher** [extension](https://marketplace.visualstudio.com/items?itemName=dmitryserbin.task-publisher) adds a task to Azure DevOps which helps you to publish custom tasks using service endpoint.

Extension | Build | Code
:-------|:-------|:-------
[![Extension](https://vsmarketplacebadge.apphb.com/version/dmitryserbin.task-publisher.svg)](https://marketplace.visualstudio.com/items?itemName=dmitryserbin.task-publisher) | [![Build](https://dev.azure.com/dmitryserbin/Publisher/_apis/build/status/Publisher-master)](https://dev.azure.com/dmitryserbin/Publisher/_build/latest?definitionId=1) | [![CodeFactor](https://www.codefactor.io/repository/github/dmitryserbin/azdev-task-publisher/badge)](https://www.codefactor.io/repository/github/dmitryserbin/azdev-task-publisher)

## Features

Using **Task Publisher** extension you can publish any custom pipeline task directly into your Azure DevOps account without a need to create an extension. This extension also helps to control version of your task and manage custom dependencies.

- Publish new or update existing task
- Replace existing task entirely
- Update task patch version number
- Update task preview version settings
- Automatically update task dependencies
- Use service endpoint for authentication

## Prerequisites

This is a [PowerShell](https://github.com/powershell/powershell) based extension, which means your build agent must be capable of running `PowerShell` tasks as well as have [Node.js](https://nodejs.org/en/) pre-installed to run [TFX-CLI](https://www.npmjs.com/package/tfx-cli) (installed automatically) commands.

## How To Use

The extension uses **user-defined** personal access token (PAT) Azure DevOps service endpoint to work.

> You may need to create a new Azure Pipelines [service connection](https://docs.microsoft.com/en-us/azure/devops/pipelines/library/service-endpoints) using [PAT](https://docs.microsoft.com/en-us/azure/devops/organizations/accounts/use-personal-access-tokens-to-authenticate) token with `Agent Pools: read & manage` scope access.

Using **Task Publisher** extension is simple:

1. Add **Task Publisher** task to your pipeline
2. Select service endpoint with Azure DevOps account access
3. Specify or select full path to task directory
4. Choose task versioning options (optionally)

#### Update task version

When `Update patch version` selected the publisher will automatically update target task `patch` version to current release ID from `RELEASE_RELEASEID` [pipeline variable](https://docs.microsoft.com/en-us/azure/devops/pipelines/release/variables).

```json
{
  "version": {
    "Major": 1,
    "Minor": 0,
    "Patch": 123
  }
}
```

Selecting `Upload preview version` will automatically enable `preview` flag in the task definition. After this, the published task version will be visible as `Preview` in the pipeline.

```json
{
  "preview": true
}
```

Please refer to the [task.json schema](https://github.com/microsoft/azure-pipelines-task-lib/blob/master/tasks.schema.json) definition for reference.

#### Update task dependencies

You can make **Task Publisher** to automatically update external dependencies of the task before publishing. There are two types of dependencies supported:

Type | Source | Target | Description
:-------|:-------|:------- |:-------
Modules | `/Modules` | `{task}/ps_modules` | PowerShell modules or `*.ps1` scripts
Resources | `/Resources` | `{task}/resources` | Any artifacts, folders or executables

You can configure dependencies deployment by adding the following configuration to your `task.json` definition and configuring path to artifacts source directory in the settings.

```json
{
  "modules": [
    "MyModule",
    "MyScript.ps1"
  ],
  "resources": [
    "MyResource-1.0"
  ]
}
```

When configuration in preset, the publisher will automatically locate required artifacts and modules and copy them to the destination task directory before publishing. This makes the modules and resource be available for the task to consume on runtime.

## Support

For aditional information and support please refer to [project repository](https://github.com/dmitryserbin/azdev-task-publisher).