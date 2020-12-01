<#
.SYNOPSIS
Short description

.DESCRIPTION
Long description

.PARAMETER Object
Parameter description

.PARAMETER ForegroundColor
Parameter description

.PARAMETER BackgroundColor
Parameter description

.PARAMETER Seperator
Parameter description

.PARAMETER NoNewLine
Parameter description

.EXAMPLE
An example

.NOTES
General notes
#>
#############################
# Declare Script Parameters #
#############################
[CmdletBinding()]
param (
	[Parameter()]
	[switch]
	$WhatIF,
	[Parameter()]
	[switch]
	$ForcePull
)

# Dynamically load the class modules with the true path of this script in case it was loaded through a symbolic link
$scriptFile = Get-ChildItem -Path $MyInvocation.MyCommand.Path
[string]$scriptPath = if($scriptFile.LinkType -eq 'SymbolicLink') { Split-Path -Path (Resolve-Path $scriptFile.Target) } else { ($scriptFile.Directory).FullName }
$dynamicUsingBlock = @"
using module "$scriptPath\Functions\Function.common.psm1"
using module "$scriptPath\Classes\Class.BuildType.psm1"
using module "$scriptPath\Classes\Class.Repo.psm1"
using module "$scriptPath\Classes\Class.SourceSubModule.psm1"
"@
$dynamicUsing = [ScriptBlock]::Create($dynamicUsingBlock)
. $dynamicUsing
Import-Module (Join-Path -Path $scriptPath -ChildPath 'SullTec.Common.PowerShell' -AdditionalChildPath 'SullTec.Common.psd1') -Force

#####################
# Declare Functions #
#####################
function LoadManageJSON {
    param (
        [string]$JsonContentPath,
        [string]$JsonSchemaPath
    )
    
    # Load JSON and JSON schema into strings
    $stringJsonContent = Get-Content -Path $JsonContentPath -Raw
    $stringJsonSchema  = Get-Content -Path $JsonSchemaPath  -Raw

    # Test the JSON based on the schema and return an empty SourceSubModule array if there are any error
    if (Test-Json -Json $stringJsonContent -Schema $stringJsonSchema){
        # Convert the JSON content string into a JSON object
        [Hashtable]$script:ManageJSON = ConvertFrom-Json -InputObject $stringJsonContent -AsHashtable
    }
    else {
        [Hashtable]$script:ManageJSON = $null
    }


}
function LoadConfiguration {
    param (
        [Hashtable]$ConfigurationData
    )
    if ($null -ne $ConfigurationData) {
        ## URL for forked GIT Repositories
        [string]$script:myGit_URL = $ConfigurationData.myGit_URL

        ## JAVA_HOME alternatives
        $script:JAVA_HOME = $ConfigurationData.JAVA_HOME

        ## Show Debugging Information
        [boolean]$script:ShowDebugInfo = ($ConfigurationData.ShowDebugInfo)

        ## Clean and pull repositories before building
        [boolean]$script:CleanAndPullRepo = $ConfigurationData.Contains('CleanAndPullRepo') ? $ConfigurationData.CleanAndPullRepo : $true

        [string[]]$script:ArchiveExceptions = [string[]]@()
        if ($ConfigurationData.Contains('ArchiveExceptions')) {
            foreach ($item in $ConfigurationData.ArchiveExceptions) {
                $script:ArchiveExceptions += [string]$item
            }
        }

        [string[]]$script:ArchiveAdditions = [string[]]@()
        if ($ConfigurationData.Contains('ArchiveAdditions')) {
            foreach ($item in $ConfigurationData.ArchiveAdditions) {
                $script:ArchiveAdditions += [string]$item
            }
        }

        [string[]]$script:CleanExceptions = [string[]]@()
        if ($ConfigurationData.Contains('CleanExceptions')) {
            foreach ($item in $ConfigurationData.CleanExceptions) {
                $script:CleanExceptions += [string]$item
            }
        }

        [string[]]$script:CleanAdditions = [string[]]@()
        if ($ConfigurationData.Contains('CleanAdditions')) {
            foreach ($item in $ConfigurationData.CleanAdditions) {
                $script:CleanAdditions += [string]$item
            }
        }

    }
}
function LoadSourceSubModules {
    param (
        [Hashtable[]]$SubmodulesData,
        [ref]$SourcesArray
    )

    # Sets the initial return value as a blank array of [SourceSubModule]
    [SourceSubModule[]]$ReturnSources = [SourceSubModule[]]@()

    # If the SubmodulesData is not null proceed to iteratation
    if ($null -ne $SubmodulesData ) {
        # Iterate through the submodules
        foreach($item in $SubmodulesData){
            if (-not ($item.Contains('Ignore') -and $item.Ignore)) {
                # Set the JAVA_HOME property if it exists
                if ($item.Build.Contains('JAVA_HOME')){
                    [int]$version = $item.Build.JAVA_HOME
                    [string]$path = $script:JAVA_HOME.$version
                    $item.Build.JAVA_HOME = [string]::IsNullOrWhiteSpace($path) ? $null : $path
                }
                $ReturnSources += [SourceSubModule]::new($item)
            }
        }
    }
    #return $ReturnSources
    $SourcesArray.Value = $ReturnSources
}
function Show-WhatIfInfo() {
    if ($WhatIF) {
        if ($ForcePull) {
            Write-Host 'In WhatIF mode with Force Pull. Only a git pull will occur.' -ForegroundColor Black -BackgroundColor Yellow -NoNewline;Write-Host ' '
        }
        else {
            Write-Host 'In WhatIF mode. No changes will occur.' -ForegroundColor Black -BackgroundColor Yellow -NoNewline;Write-Host ' '
        }
    }
}
function Show-DirectoryInfo() {
    Write-Host "$('=' * 120)" -ForegroundColor Green
    Write-Host "Base Directories:" -ForegroundColor Green
    Write-Host "`tRoot:           $dirRoot" -ForegroundColor Green
    Write-Host "`tSources:        $dirSources" -ForegroundColor Green
    Write-Host "Server Directories:" -ForegroundColor Green
    Write-Host "`tServer:         $dirServer" -ForegroundColor Green
    Write-Host "`tPlugins:        $dirPlugins" -ForegroundColor Green
    Write-Host "`tData Packs:     $dirDataPacks" -ForegroundColor Green
    Write-Host "Client Directories:" -ForegroundColor Green
    Write-Host "`tClient Mods:    $dirModules" -ForegroundColor Green
    Write-Host "`tResource Packs: $dirResourcePacks" -ForegroundColor Green
    Write-Host "Configuration:" -ForegroundColor Green
    Write-Host "`tmyGit_URL:      $($script:myGit_URL)" -ForegroundColor Green
    foreach ($item in $script:JAVA_HOME) {
        [int]$spaces = 4 - ([string]($item.Keys[0])).Length
        $spaces = $spaces -gt 0 ? $spaces : 0
        Write-Host "`tJAVA_HOME($($item.Keys[0])):$(' ' * $spaces)$($item.Values[0])" -ForegroundColor Green
    }
    Write-Host "`tSubmodules:     $($sources.Count)" -ForegroundColor Green
    Write-Host "$('=' * 120)" -ForegroundColor Green
}


#####################
# Declare Variables #
#####################
## Base directories
$dirStartup = (Get-Location).Path
$dirRoot = Split-Path ($MyInvocation.MyCommand.Path)
if ($dirRoot -match '^(?<root>.*)[\\/]src[\\/]Manage[\\/]?$') {
    $dirRoot = $Matches.root
}
$dirSources = Join-Path -Path $dirRoot -ChildPath src

## Server directories
$dirServer = $dirRoot
$dirPlugins = Join-Path -Path $dirServer -ChildPath plugins
$dirWorlds = Join-Path -Path $dirServer -ChildPath worlds -AdditionalChildPath world
$dirDataPacks = Join-Path -Path $dirWorlds -ChildPath datapacks

## Client directories
$dirModules = Join-Path -Path $dirRoot -ChildPath .minecraft -AdditionalChildPath mods
$dirResourcePacks = Join-Path -Path $dirRoot -ChildPath .minecraft -AdditionalChildPath resourcepacks

## Blank [SourceSubModule] array
[SourceSubModule[]]$sources = @()

## ExitScript for Show-Choices
$exitScript = [ScriptBlock]::Create(@"
    Write-Host "Removing unused Modules..."
    Remove-Module Class.BuildType -Force
    Remove-Module Class.Repo -Force
    Remove-Module Class.SourceSubModule -Force
    Remove-Module Function.common -Force
    Remove-Module SullTec.Common -Force
"@)


## Load configuration and submodule hashtables from manage.json
LoadManageJSON -JsonContentPath "$dirRoot\manage.json" -JsonSchemaPath "$scriptPath\manage.schema.json"

## Load script configuration values from hashtable
LoadConfiguration -ConfigurationData $script:ManageJSON.configuration

## Load submodules from hashtable
LoadSourceSubModules -SubmodulesData $script:ManageJSON.submodules -SourcesArray ([ref]$sources)


do { # Main loop
    Clear-Host
    Show-WhatIfInfo
    Show-DirectoryInfo
    $menuItems =  @(
        'Compile, Clean, Reset, Repair, and Commit',
        'Repositories - Initialize',
        'Repositories - Display Details',
        'Repositories - Compare One',
        'Repositories - Compare All',
        'Repositories - Archive Untracked',
        'Repositories - Checkout',
        'Repositories - Clean',
        'Repositories - Reset',
        'Repositories - Repair',
        'Build - Get Versions',
        'Build - Compile One',
        'Build - Compile All',
        'Configuration - Reload Generic',
        'Configuration - Reload Submodules',
        'Configuration - Toggle WhatIF',
        'Configuration - Toggle ForcePull'
    )
	$choice = Show-Choices -Title 'Select an action' -List $menuItems -NoSort -ExitPath $dirStartup -ExitScript $exitScript
	switch ($choice) {
        'Compile, Clean, Reset, Repair, and Commit' {
            # Compile
            Push-Location -Path $dirSources -StackName 'MainLoop'
            [string[]]$updatedFiles = @()
            foreach ( $currentSource in $sources ) {
                [string]$buildReturn = $currentSource.InvokeBuild($dirSources,$dirServer,$dirServer,$dirPlugins,$dirModules,$dirDataPacks,$dirResourcePacks,'',$script:CleanAndPullRepo,$WhatIF)
                if (-not [string]::IsNullOrWhiteSpace($buildReturn)) { $updatedFiles += $buildReturn }
            }

            # Clean Root Folder
            Set-Location -Path $dirRoot
            Write-Host "Cleaning Root Folder"
            if ($script:WhatIF) { Write-Host 'WhatIF: git clean' }
            [string[]]$cleanArguments = @('clean')
            $cleanArguments += ($script:WhatIF ? '-nxfd' : '-xfd')
            $cleanArguments += @('-e','plugins/')
            $cleanArguments += @('-e','worlds/')
            $cleanArguments += @('-e','worlds/world/datapacks/')
            $cleanArguments += @('-e','.minecraft/mods/')
            $cleanArguments += @('-e','.minecraft/resourcepacks/')

            foreach ($item in $script:CleanExceptions) {
                $cleanArguments += @('-e',[string]$item)
            }
            git @cleanArguments
            foreach ($item in $this.CleanAdditions) {
                Remove-Item $item -Force -Recurse -WhatIf:$($script:WhatIF)
            }

            # Repair/Prune Root Folder
            Write-Host "Repairing Root Folder"
            if ($script:WhatIF) {
                Write-Console "git fsck --full --strict" -Title 'WhatIF'
                Write-Console "git prune" -Title 'WhatIF'
                Write-Console "git reflog expire --expire=now --all" -Title 'WhatIF'
                Write-Console "git repack -ad" -Title 'WhatIF'
                Write-Console "git prune" -Title 'WhatIF'
            }
            else {
                git fsck --full --strict
                git prune
                git reflog expire --expire=now --all
                git repack -ad
                git prune
            }


            foreach ($currentSource in $sources) {
                $dirCurrent = Join-Path -Path $dirSources -ChildPath $currentSource.Name
                Set-Location -Path $dirCurrent


                # Display current Source/Repo Header
                $currentSource.DisplayHeader()
                $currentSource.Repo.Display()

                # Clean Individual Source
                $currentSource.Repo.InvokeClean($true)

                # Reset Individual Source
                $currentSource.Repo.InvokeReset($true)

                # Repair/Prune Individual Source
                $currentSource.Repo.InvokeRepair($true)

            }

            Set-Location -Path $dirRoot
            Write-Console -Value "Commiting all changes...." -Title "Info"
            git add -A
            [string]$commitTime = Get-Date -Format "dddd, MMMM dd, yyyy 'at' HH:mm K"
            git commit -m "Auto-update: $commitTime"
            git push

            # List all updated files
            if ($updatedFiles.Count -gt 0) {
               Write-Host "Updated Files...`r`n$('=' * 120)" -ForegroundColor Green
               foreach ($item in $updatedFiles) {
                   Write-Host "`t$item" -ForegroundColor Green
               }
            }
            PressAnyKey
           break
        }
        'Repositories - Initialize'{
            Push-Location -Path $dirSources -StackName 'MainLoop'
            Write-Host "Displaying Repository Details"
            foreach ($currentSource in $sources) {
                $dirCurrent = Join-Path -Path $dirSources -ChildPath $currentSource.Name
                Set-Location -Path $dirCurrent
                $currentSource.DisplayHeader()
                $currentSource.Repo.InvokeInitialize()
            }
            PressAnyKey
            break
        }
        'Repositories - Display Details'{
            Push-Location -Path $dirSources -StackName 'MainLoop'
            Write-Host "Displaying Repository Details"
            foreach ($currentSource in $sources) {
                $dirCurrent = Join-Path -Path $dirSources -ChildPath $currentSource.Name
                Set-Location -Path $dirCurrent
                $currentSource.DisplayHeader()
                $currentSource.Repo.Display()
            }
            PressAnyKey
            break
        }
		'Repositories - Archive Untracked'{
            Push-Location -Path $dirRoot -StackName 'MainLoop'
            $files = @()

            #Setup untracked exceptions to exclude from the archive
            [string[]]$exceptions = @()
            # Retrieve untracked exceptions that will be excluded from the archive for the base repo
            foreach ($item in $script:ArchiveExceptions) { $exceptions += @('-x',$([string]$item)) }
            # Retrieve untracked exceptions that will be excluded from the archive for each submodule
            foreach ($currentSource in $sources) {
                foreach ($item in $currentSource.Repo.ArchiveExceptions) { $exceptions += @('-x',$([string]$item)) }
            }

            #Setup untracked additions to add to the archive
            [string[]]$additions = @()
            # Retrieve untracked additions to add to the archive for the base repo
            foreach ($item in $script:ArchiveAdditions) { $additions += [string]$item }
            # Retrieve untracked additions to add to the archive for each submodule
            foreach ($currentSource in $sources) {
                foreach ($item in $currentSource.Repo.ArchiveAdditions) { $additions += Join-Path -Path $dirSources -ChildPath $currentSource.Name -AdditionalChildPath $item }
            }

            $filesRoot = (git ls-files . --other @exceptions)
            foreach ($file in $filesRoot) { $files += Resolve-Path -Path "$dirRoot\$file" }
            
            foreach ($file in $additions) {
                if (Test-Path -Path $file){ $files += Resolve-Path -Path "$file" }
            }
            
            $archiveFile = $(Join-Path -Path $dirRoot -ChildPath "$(Get-Date -Format 'yyyy-MM-dd@HH-mm')-untracked.zip")
            $archive = [System.IO.Compression.ZipFile]::Open($archiveFile,[System.IO.Compression.ZipArchiveMode]::Create)
            foreach ($file in $files) {
                [string]$fullName = $file
                [string]$partName = $(Resolve-Path -Path $fullName -Relative) -replace '\.\\',''
                Write-Host "Adding $fullName as $partName"
                try {
                    $zipEntry = $archive.CreateEntry($partName)
                    $zipEntryWriter = New-Object -TypeName System.IO.BinaryWriter $zipEntry.Open()
                    $zipEntryWriter.Write([System.IO.File]::ReadAllBytes($fullName))
                    $zipEntryWriter.Flush()
                    $zipEntryWriter.Close()
                }
                catch {
                    Write-Host $_.Exception.Message
                }
            }
            $archive.Dispose()
            PressAnyKey
			break
		}
		'Repositories - Clean'{
            Push-Location -Path $dirRoot -StackName 'MainLoop'
            Write-Host "Cleaning Root Folder"
            if ($script:WhatIF) { Write-Host 'WhatIF: git clean' }
            [string[]]$cleanArguments = @('clean')
            $cleanArguments += ($script:WhatIF ? '-nxfd' : '-xfd')
            $cleanArguments += @('-e','plugins/')
            $cleanArguments += @('-e','worlds/')
            $cleanArguments += @('-e','worlds/world/datapacks/')
            $cleanArguments += @('-e','.minecraft/mods/')
            $cleanArguments += @('-e','.minecraft/resourcepacks/')

            foreach ($item in $script:CleanExceptions) {
                $cleanArguments += @('-e',[string]$item)
            }
            git @cleanArguments
            foreach ($item in $this.CleanAdditions) {
                Remove-Item $item -Force -Recurse -WhatIf:$($script:WhatIF)
            }
            foreach ($currentSource in $sources) {
                $currentSource.InvokeClean($dirSources)
            }
            PressAnyKey
            break
        }
        'Repositories - Reset' {
            Push-Location -Path $dirSources -StackName 'MainLoop'
            Write-Host "Resetting Repositories"
            foreach ($currentSource in $sources) {
                $dirCurrent = Join-Path -Path $dirSources -ChildPath $currentSource.Name
                Set-Location -Path $dirCurrent
                $currentSource.DisplayHeader()
                $currentSource.Repo.InvokeReset()
            }
            PressAnyKey
            break
        }
        'Repositories - Repair' {
            Push-Location -Path $dirRoot -StackName 'MainLoop'
            Write-Host "Repairing Root Folder"
            if ($script:WhatIF) {
                Write-Console "git fsck --full --strict" -Title 'WhatIF'
                Write-Console "git prune" -Title 'WhatIF'
                Write-Console "git reflog expire --expire=now --all" -Title 'WhatIF'
                Write-Console "git repack -ad" -Title 'WhatIF'
                Write-Console "git prune" -Title 'WhatIF'
            }
            else {
                git fsck --full --strict
                git prune
                git reflog expire --expire=now --all
                git repack -ad
                git prune
            }
            Set-Location -Path $dirSources
            Write-Host "Repair Repositories"
            foreach ($currentSource in $sources) {
                $dirCurrent = Join-Path -Path $dirSources -ChildPath $currentSource.Name
                Set-Location -Path $dirCurrent
                $currentSource.DisplayHeader()
                $currentSource.Repo.InvokeRepair()
            }
            PressAnyKey
            break
        }
        'Repositories - Compare All'{
            Push-Location -Path $dirSources -StackName 'MainLoop'
            Write-Host "Comparing Branches on all Repositories"
            foreach ( $currentSource in $sources ) {
                Set-Location -Path $(Join-Path -Path $dirSources -ChildPath $($currentSource.Name))
                $currentSource.DisplayHeader()
                $currentSource.Repo.CompareAheadBehind()
            }
            PressAnyKey
            break
        }
        'Repositories - Compare One'{
            Push-Location -Path $dirSources -StackName 'MainLoop'
            $currentSource = Show-Choices -Title 'Select an action' -List $sources -ExitPath $dirStartup
            Set-Location -Path $(Join-Path -Path $dirSources -ChildPath $($currentSource.Name))
            $currentSource.DisplayHeader()
            $currentSource.Repo.CompareAheadBehind()
            PressAnyKey
            break
        }
		'Build - Compile All'{
            Push-Location -Path $dirSources -StackName 'MainLoop'
            [string[]]$updatedFiles = @()
            foreach ( $currentSource in $sources ) {
                [string]$buildReturn = $currentSource.InvokeBuild($dirSources,$dirServer,$dirServer,$dirPlugins,$dirModules,$dirDataPacks,$dirResourcePacks,'',$script:CleanAndPullRepo,$WhatIF)
                if (-not [string]::IsNullOrWhiteSpace($buildReturn)) { $updatedFiles += $buildReturn }
            }
            if ($updatedFiles.Count -gt 0) {
               Write-Host "Updated Files...`r`n$('=' * 120)" -ForegroundColor Green
               foreach ($item in $updatedFiles) {
                   Write-Host "`t$item" -ForegroundColor Green
               }
            }
            PressAnyKey
           break
        }
        'Build - Compile One'{
            Push-Location -Path $dirSources -StackName 'MainLoop'
            $currentSource = Show-Choices -Title 'Select an action' -List $sources -ExitPath $dirStartup
            [string]$buildReturn = $currentSource.InvokeBuild($dirSources,$dirServer,$dirServer,$dirPlugins,$dirModules,$dirDataPacks,$dirResourcePacks,'',$script:CleanAndPullRepo,$WhatIF)
            if (-not [string]::IsNullOrWhiteSpace($buildReturn)) { Write-Host "Updated Files...`r`n$('=' * 120)`r`n`t$buildReturn" -ForegroundColor Green }
            PressAnyKey
            break
        }
        'Build - Get Versions'{
            Push-Location -Path $dirSources -StackName 'MainLoop'
            foreach ( $currentSource in $sources ) {
                $dirCurrent = Join-Path -Path $dirSources -ChildPath $currentSource.Name
                Set-Location -Path $dirCurrent
                Write-Host $currentSource.GetFinalName()
                Write-Host "`tRaw Version  : $($currentSource.Build.GetVersion($true))"
                Write-Host "`tClean Version: $($currentSource.Build.GetVersion())"
            }
            PressAnyKey
            break
        }
        'Repositories - Checkout' {
            Push-Location -Path $dirSources -StackName 'MainLoop'
            foreach ( $currentSource in $sources ) {
                $dirCurrent = Join-Path -Path $dirSources -ChildPath $currentSource.Name
                Set-Location -Path $dirCurrent
                Write-Host $currentSource.GetFinalName()
                $currentSource.Repo.InvokeCheckout()
            }
            PressAnyKey
            break
        }
        'Configuration - Reload Generic' {
            LoadManageJSON -JsonContentPath "$dirRoot\manage.json" -JsonSchemaPath "$dirRoot\manage.schema.json"
            LoadConfiguration -ConfigurationData $script:ManageJSON.configuration
            break
        }
        'Configuration - Reload Submodules' {
            LoadManageJSON -JsonContentPath "$dirRoot\manage.json" -JsonSchemaPath "$dirRoot\manage.schema.json"
            LoadSourceSubModules -SubmodulesData $script:ManageJSON.submodules -SourcesArray ([ref]$sources)
            break
        }
        'Configuration - Toggle WhatIF' { $WhatIF = -not $WhatIF; break; }
        'Configuration - Toggle ForcePull' { $ForcePull = -not $ForcePull; break; }
		Default {
            Write-Host $choice
            PressAnyKey
		}
	}
    Pop-Location -StackName 'MainLoop' -ErrorAction Ignore
} while($true)
if ($WhatIF) {
	Write-Host 'In WhatIF mode. No changes have occured.' -ForegroundColor Black -BackgroundColor Yellow -NoNewline
	Write-Host ' '
}
