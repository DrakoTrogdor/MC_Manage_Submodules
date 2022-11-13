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
        $global:JAVA_HOME = $ConfigurationData.JAVA_HOME

        ## Default JAVA_HOME
        [string]$script:Java_Default = $global:JAVA_HOME.$($ConfigurationData.Java_Default)
        
        ## Show Debugging Information
        [boolean]$script:ShowDebugInfo = ($ConfigurationData.ShowDebugInfo)

        ## Clean and pull repositories before building
        [boolean]$script:CleanAndPullRepo = $ConfigurationData.Contains('CleanAndPullRepo') ? $ConfigurationData.CleanAndPullRepo : $true

        [string[]]$script:ArchiveExceptions = [string[]]@()
        $script:ArchiveExceptions += "????-??-??@??-??-untracked.zip"
        $script:ArchiveExceptions += "Untracked/"
        $script:ArchiveExceptions += "backups/"
        $script:ArchiveExceptions += "worlds/"
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
                if ($item.Builds -is [hashtable]) {
                    # Set the JAVA_HOME property if it exists
                    if ($item.Builds.Contains('JAVA_HOME')){
                        [int]$version = $item.Builds.JAVA_HOME
                        [string]$path = $global:JAVA_HOME.$version
                        $item.Builds.JAVA_HOME = [string]::IsNullOrWhiteSpace($path) ? $([string]::IsNullOrWhiteSpace($script:Java_Default) ? $null : $script:Java_Default) : $path
                    }
                    else {
                        $item.Builds.JAVA_HOME = [string]::IsNullOrWhiteSpace($script:Java_Default) ? $null : $script:Java_Default
                    }
                }
                elseif ($item.Builds -is [array]) {
                    foreach ($build in $item.Builds) {
                        # Set the JAVA_HOME property if it exists
                        if ($build.Contains('JAVA_HOME')){
                            [int]$version = $build.JAVA_HOME
                            [string]$path = $global:JAVA_HOME.$version
                            $build.JAVA_HOME = [string]::IsNullOrWhiteSpace($path) ? $([string]::IsNullOrWhiteSpace($script:Java_Default) ? $null : $script:Java_Default) : $path
                        }
                        else {
                            $build.JAVA_HOME = [string]::IsNullOrWhiteSpace($script:Java_Default) ? $null : $script:Java_Default
                        }
                    }
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
    Write-Host "`tRoot:           $($dir['Root'])" -ForegroundColor Green
    Write-Host "`tSources:        $($dir['Sources'])" -ForegroundColor Green
    Write-Host "`tDependancies:   $($dir['SubModuleDependancy'])" -ForegroundColor Green
    Write-Host "Server Directories:" -ForegroundColor Green
    Write-Host "`tServer:         $($dir['Server'])" -ForegroundColor Green
    Write-Host "`tPlugins:        $($dir['Plugin'])" -ForegroundColor Green
    Write-Host "`tServer Mods:    $($dir['ServerModule'])" -ForegroundColor Green
    Write-Host "`tData Packs:     $($dir['DataPack'])" -ForegroundColor Green
    Write-Host "Client Directories:" -ForegroundColor Green
    Write-Host "`tClient Mods:    $($dir['ClientModule'])" -ForegroundColor Green
    Write-Host "`tResource Packs: $($dir['ResourcePack'])" -ForegroundColor Green
    Write-Host "Configuration:" -ForegroundColor Green
    Write-Host "`tmyGit_URL:      $($script:myGit_URL)" -ForegroundColor Green
    foreach ($item in $global:JAVA_HOME) {
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
$global:ProgressPreference = "SilentlyContinue"

$dir = @{}
## Base directories
$dir['Startup'] = (Get-Location).Path
$dir['Root'] = Split-Path ($MyInvocation.MyCommand.Path)
if ($dir['Root'] -match '^(?<root>.*)[\\/]src[\\/]Manage[\\/]?$') {
    $dir['Root'] = $Matches.root
}
$dir['Sources'] = Join-Path -Path $dir['Root'] -ChildPath src

## Server directories
$dir['Server'] = $dir['Root']
$dir['Plugin'] = Join-Path -Path $dir['Server'] -ChildPath plugins
$dir['VelocityPlugin'] = Join-Path -Path $dir['Server'] -ChildPath velocityplugins
$dir['ServerModule'] = Join-Path -Path $dir['Server'] -ChildPath mods
$dir['SubModuleDependancy'] = Join-Path -Path $dir['Server'] -ChildPath dependencies
$dir['World']= Join-Path -Path $dir['Server'] -ChildPath worlds -AdditionalChildPath world
$dir['DataPack'] = Join-Path -Path $dir['World']-ChildPath datapacks

## Client directories
$dir['ClientModule'] = Join-Path -Path $dir['Root'] -ChildPath .minecraft -AdditionalChildPath mods
$dir['ResourcePack'] = Join-Path -Path $dir['Root'] -ChildPath .minecraft -AdditionalChildPath resourcepacks

## Other Directories:
$dir['NodeDependancy'] = Join-Path -Path $dir['Root'] -ChildPath 'node_modules'

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
LoadManageJSON -JsonContentPath "$($dir['Root'])\manage.json" -JsonSchemaPath "$scriptPath\manage.schema.json"

## Load script configuration values from hashtable
LoadConfiguration -ConfigurationData $script:ManageJSON.configuration

## Load submodules from hashtable
LoadSourceSubModules -SubmodulesData $script:ManageJSON.submodules -SourcesArray ([ref]$sources)

function CleanRootFolder {
    Set-Location -Path $dir['Root']
    Write-Host "Cleaning Root Folder"
    if ($script:WhatIF) { Write-Host 'WhatIF: git clean' }
    [string[]]$cleanArguments = @('clean')
    $cleanArguments += ($script:WhatIF ? '-nxfd' : '-xfd')
    $cleanArguments += @('-e','plugins/')
    $cleanArguments += @('-e','mods/')
    $cleanArguments += @('-e','velocityplugins/')
    $cleanArguments += @('-e','worlds/')
    $cleanArguments += @('-e','worlds/world/datapacks/')
    $cleanArguments += @('-e','.minecraft/mods/')
    $cleanArguments += @('-e','.minecraft/resourcepacks/')
    $cleanArguments += @('-e','????-??-??@??-??-untracked.zip')
    $cleanArguments += @('-e','Untracked/')
    $cleanArguments += @('-e','backups/')

    foreach ($item in $script:CleanExceptions) {
        $cleanArguments += @('-e',[string]$item)
    }
    git @cleanArguments
    foreach ($item in $this.CleanAdditions) {
        Remove-Item $item -Force -Recurse -WhatIf:$($script:WhatIF)
    }
}

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
        'Repositories - Commit',
        'Build - Get Versions',
        'Build - Compile One',
        'Build - Compile All',
        'Configuration - Reload Generic',
        'Configuration - Reload Submodules',
        'Configuration - Toggle WhatIF',
        'Configuration - Toggle ForcePull'
    )
	$choice = Show-Choices -Title 'Select an action' -List $menuItems -NoSort -ExitPath $dir['Startup'] -ExitScript $exitScript
	switch ($choice) {
        'Compile, Clean, Reset, Repair, and Commit' {
            # Compile
            Push-Location -Path $dir['Sources'] -StackName 'MainLoop'
            [string[]]$updatedFiles = @()
            foreach ( $currentSource in $sources ) {
                [string[]]$buildReturn = $currentSource.InvokeBuild($dir, $script:CleanAndPullRepo, $WhatIF)
                if (-not ($null -eq $buildReturn) -and ($buildReturn -is [string[]])) { $updatedFiles += $buildReturn }
            }

            # Clean Root Folder
            CleanRootFolder

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
                $dirCurrent = Join-Path -Path $dir['Sources'] -ChildPath $currentSource.Name
                Set-Location -Path $dirCurrent


                # Display current Source/Repo Header
                $currentSource.DisplayHeader($dir['Root'])
                $currentSource.Repo.Display()

                # Clean Individual Source
                $currentSource.Repo.InvokeClean($true)

                # Reset Individual Source
                $currentSource.Repo.InvokeReset($true)

                # Repair/Prune Individual Source
                $currentSource.Repo.InvokeRepair($true)

            }

            Set-Location -Path $dir['Root']
            Write-Console -Value "Commiting all changes...." -Title "Info"
            git add -A
            [string]$commitTime = Get-Date -Format "dddd, MMMM dd, yyyy 'at' HH:mm K"
            git commit -m "Auto-update: $commitTime"
            git push

            # List all updated files
            if ($updatedFiles.Count -gt 0) {
                Write-Host "Updated Files...`r`n$('=' * 120)" -ForegroundColor Green
                foreach ($item in $updatedFiles) {
                    if ($item -like "ERROR:*") {
                        Write-Host "`t$item" -ForegroundColor Red
                    }
                    else {
                        Write-Host "`t$item" -ForegroundColor Green
                    }
                }
            }
            PressAnyKey
           break
        }
        'Repositories - Initialize'{
            Push-Location -Path $dir['Sources'] -StackName 'MainLoop'
            Write-Host "Displaying Repository Details"
            foreach ($currentSource in $sources) {
                $dirCurrent = Join-Path -Path $dir['Sources'] -ChildPath $currentSource.Name
                Set-Location -Path $dirCurrent
                $currentSource.DisplayHeader($dir['Root'])
                $currentSource.Repo.InvokeInitialize()
            }
            PressAnyKey
            break
        }
        'Repositories - Display Details'{
            Push-Location -Path $dir['Sources'] -StackName 'MainLoop'
            Write-Host "Displaying Repository Details"
            foreach ($currentSource in $sources) {
                $dirCurrent = Join-Path -Path $dir['Sources'] -ChildPath $currentSource.Name
                Set-Location -Path $dirCurrent
                $currentSource.DisplayHeader($dir['Root'])
                $currentSource.Repo.Display()
            }
            PressAnyKey
            break
        }
		'Repositories - Archive Untracked'{
            Push-Location -Path $dir['Root'] -StackName 'MainLoop'
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
                foreach ($item in $currentSource.Repo.ArchiveAdditions) { $additions += Join-Path -Path $dir['Sources'] -ChildPath $currentSource.Name -AdditionalChildPath $item }
            }

            $filesRoot = (git ls-files . --other @exceptions)
            foreach ($file in $filesRoot) { $files += Resolve-Path -Path "$($dir['Root'])\$file" }

            foreach ($file in $additions) {
                if (Test-Path -Path $file){ $files += Resolve-Path -Path "$file" }
            }

            $archiveFile = $(Join-Path -Path $dir['Root'] -ChildPath "$(Get-Date -Format 'yyyy-MM-dd@HH-mm')-untracked.zip")
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
            Push-Location -Path $dir['Root'] -StackName 'MainLoop'

            # Clean Root Folder
            CleanRootFolder

            # Clean Individual Source
            foreach ($currentSource in $sources) {
                $currentSource.InvokeClean($dir['Sources'])
            }

            PressAnyKey
            break
        }
        'Repositories - Reset' {
            Push-Location -Path $dir['Sources'] -StackName 'MainLoop'
            Write-Host "Resetting Repositories"
            foreach ($currentSource in $sources) {
                $dirCurrent = Join-Path -Path $dir['Sources'] -ChildPath $currentSource.Name
                Set-Location -Path $dirCurrent
                $currentSource.DisplayHeader($dir['Root'])
                $currentSource.Repo.InvokeReset()
            }
            PressAnyKey
            break
        }
        'Repositories - Repair' {
            Push-Location -Path $dir['Root'] -StackName 'MainLoop'
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
            Set-Location -Path $dir['Sources']
            Write-Host "Repair Repositories"
            foreach ($currentSource in $sources) {
                $dirCurrent = Join-Path -Path $dir['Sources'] -ChildPath $currentSource.Name
                Set-Location -Path $dirCurrent
                $currentSource.DisplayHeader($dir['Root'])
                $currentSource.Repo.InvokeRepair()
            }
            PressAnyKey
            break
        }
        'Repositories - Commit' {
            Set-Location -Path $dir['Root']
            Write-Console -Value "Commiting all changes...." -Title "Info"
            git add -A
            [string]$commitTime = Get-Date -Format "dddd, MMMM dd, yyyy 'at' HH:mm K"
            git commit -m "Auto-update: $commitTime"
            git push
        }
        'Repositories - Compare All'{
            Push-Location -Path $dir['Sources'] -StackName 'MainLoop'
            Write-Host "Comparing Branches on all Repositories"
            foreach ( $currentSource in $sources ) {
                Set-Location -Path $(Join-Path -Path $dir['Sources'] -ChildPath $($currentSource.Name))
                $currentSource.DisplayHeader($dir['Root'])
                $currentSource.Repo.CompareAheadBehind()
            }
            PressAnyKey
            break
        }
        'Repositories - Compare One'{
            Push-Location -Path $dir['Sources'] -StackName 'MainLoop'
            $currentSource = Show-Choices -Title 'Select an action' -List $sources -ExitPath $dir['Startup']
            Set-Location -Path $(Join-Path -Path $dir['Sources'] -ChildPath $($currentSource.Name))
            $currentSource.DisplayHeader($dir['Root'])
            $currentSource.Repo.CompareAheadBehind()
            PressAnyKey
            break
        }
		'Build - Compile All'{
            Push-Location -Path $dir['Sources'] -StackName 'MainLoop'
            [string[]]$updatedFiles = @()
            foreach ( $currentSource in $sources ) {
                [string[]]$buildReturn = $currentSource.InvokeBuild($dir, $script:CleanAndPullRepo, $WhatIF)
                if (-not ($null -eq $buildReturn) -and ($buildReturn -is [string[]])) { $updatedFiles += $buildReturn }
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
            Push-Location -Path $dir['Sources'] -StackName 'MainLoop'
            [string[]]$updatedFiles = @()
            $currentSource = Show-Choices -Title 'Select an action' -List $sources -ExitPath $dir['Startup']
            [string[]]$buildReturn = $currentSource.InvokeBuild($dir, $script:CleanAndPullRepo, $WhatIF)
            if (-not ($null -eq $buildReturn) -and ($buildReturn -is [string[]])) { $updatedFiles += $buildReturn }
            if ($updatedFiles.Count -gt 0) {
                Write-Host "Updated Files...`r`n$('=' * 120)" -ForegroundColor Green
                foreach ($item in $updatedFiles) {
                    Write-Host "`t$item" -ForegroundColor Green
                }
            }
            PressAnyKey
            break
        }
        'Build - Get Versions'{
            Push-Location -Path $dir['Sources'] -StackName 'MainLoop'
            foreach ( $currentSource in $sources ) {
                $dirCurrent = Join-Path -Path $dir['Sources'] -ChildPath $currentSource.Name
                Set-Location -Path $dirCurrent
                Write-Host $currentSource.GetFinalName()
                foreach ($build in $currentSource.Builds) {
                    $build.InvokeInitBuild()
                    Write-Host "`tRaw Version  : $($build.GetVersion($true))"
                    Write-Host "`tClean Version: $($build.GetVersion())"
                }
            }
            PressAnyKey
            break
        }
        'Repositories - Checkout' {
            Push-Location -Path $dir['Sources'] -StackName 'MainLoop'
            foreach ( $currentSource in $sources ) {
                $dirCurrent = Join-Path -Path $dir['Sources'] -ChildPath $currentSource.Name
                Set-Location -Path $dirCurrent
                Write-Host $currentSource.GetFinalName()
                $currentSource.Repo.InvokeCheckout()
            }
            PressAnyKey
            break
        }
        'Configuration - Reload Generic' {
            LoadManageJSON -JsonContentPath "$($dir['Root'])\manage.json" -JsonSchemaPath "$($dir['Root'])\manage.schema.json"
            LoadConfiguration -ConfigurationData $script:ManageJSON.configuration
            break
        }
        'Configuration - Reload Submodules' {
            LoadManageJSON -JsonContentPath "$($dir['Root'])\manage.json" -JsonSchemaPath "$($dir['Root'])\manage.schema.json"
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
