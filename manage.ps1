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

#####################
# Declare Functions #
#####################
Function Write-Color
{
<#
.SYNOPSIS
    Enables support to write multiple color text on a single line
.DESCRIPTION
    Uses color codes to enable support to write multiple color text on a single line
    ################################################
    # Write-Color Color Codes
    ################################################
    # ^f + Color Code = Foreground Color
    # ^b + Color Code = Background Color
    # ^f?^b? = Foreground and Background Color
    ################################################
    # Color Codes
    ################################################
    # k = Black
    # b = Blue
    # c = Cyan
    # e = Gray
    # g = Green
    # m = Magenta
    # r = Red
    # w = White
    # y = Yellow
    # B = DarkBlue
    # C = DarkCyan
    # E = DarkGray
    # G = DarkGreen
    # M = DarkMagenta
    # R = DarkRed
    # Y = DarkYellow [Unsupported in Powershell]
    # z = <Default Color>
    ################################################
.PARAMETER Value
    The line or lines of of text to write

.INPUTS
[string]$Value
.OUTPUTS
None
.PARAMETER NoNewLine
Writes the text without any lines in between.
.NOTES
Version:          2.0
Author:           Casey J Sullivan
Update Date:      11/09/2020
Original Author:  Brian Clark
Original Date:    01/21/2017
Initially found at:  https://www.reddit.com/r/PowerShell/comments/5pdepn/writecolor_multiple_colors_on_a_single_line/
.EXAMPLE
A normal usage example:
    Write-Color "Hey look ^crThis is red ^cgAnd this is green!"
An example using a piped array:
    @('^fmMagenta text,^fB^bE Blue on Dark Gray ^fr Red','This is a^fM Test ^fzof ^fgGreen and ^fG^bYGreen on Dark Yellow')|Write-Color
#>
 
    [CmdletBinding(

    )]
    Param (
        [Parameter(Mandatory=$true,ValueFromPipeline=$true)][string]$Value,
        [Parameter(Mandatory=$false)][switch]$NoNewLine
    )
    Begin {
        $colors = new-object System.Collections.Hashtable
        $colors.b = 'Blue'
        $colors.B = 'DarkBlue'
        $colors.c = 'Cyan'
        $colors.C = 'DarkCyan'
        $colors.e = 'Gray'
        $colors.E = 'DarkGray'
        $colors.g = 'Green'
        $colors.G = 'DarkGreen'
        $colors.k = 'Black'
        $colors.m = 'Magenta'
        $colors.M = 'DarkMagenta'
        $colors.r = 'Red'
        $colors.R = 'DarkRed'
        $colors.w = 'White'
        $colors.y = 'Yellow'
        $colors.Y = 'DarkYellow'
        $colors.z = ''
    }
    Process {
        $Value |
            Select-String -Pattern '(?ms)(((?''fg''^?\^f[bBcCeEgGkmMrRwyYz])(?''bg''^?\^b[bBcCeEgGkmMrRwyYz])|(?''bg''^?\^b[bBcCeEgGkmMrRwyYz])(?''fg''^?\^f[bBcCeEgGkmMrRwyYz])|(?''fg''^?\^f[bBcCeEgGkmMrRwyYz])|(?''bg''^?\^b[bBcCeEgGkmMrRwyYz])|^)(?''text''.*?))(?=\^[fb][bBcCeEgGkmMrRwyYz]|\Z)' -AllMatches | 
            ForEach-Object { $_.Matches } |
            ForEach-Object {
                $fg = ($_.Groups | Where-Object {$_.Name -eq 'fg'}).Value -replace '^\^f',''
                $bg = ($_.Groups | Where-Object {$_.Name -eq 'bg'}).Value -replace '^\^b',''
                $text = ($_.Groups | Where-Object {$_.Name -eq 'text'}).Value
                $fgColor = [string]::IsNullOrWhiteSpace($fg) -or $fg -eq 'z' ? $Host.UI.RawUI.ForegroundColor : $colors.$fg
                $bgColor = [string]::IsNullOrWhiteSpace($bg) -or $bg -eq 'z' ? $Host.UI.RawUI.BackgroundColor : $colors.$bg
                Write-Host -Object $text -ForegroundColor $fgColor -BackgroundColor $bgColor -NoNewline
            }
        if (-not $NoNewLine) { Write-Host }
    }
    End {
    }
}
function Write-Log {
    Param (
        [Parameter(Mandatory=$true,ValueFromPipeline=$true)][string]$Value,
        [Parameter(Mandatory=$false)][string]$Title = 'Info',
        [Parameter(Mandatory=$false)][int]$Align = 12,
        [Parameter(Mandatory=$false)][int]$Indent = 1,
        [Parameter(Mandatory=$false)][switch]$NoNewLine
    )
    Begin {
        [string]$spaces = "$(' ' * (($Align) - $Title.Length -1))"
    }
    Process {
        Write-Color "$("`t" * $Indent)^fy$Title^fz:$spaces$Value"
    }
}
function Write-Console {
    # This function exists to make upgrading from terminal/console to an application easier.
	param (
		[Parameter(Mandatory=$true, Position = 0)][System.Object]$Object,
		[Parameter(Mandatory=$false)][ConsoleColor]$ForegroundColor = (Get-Host).UI.RawUI.ForegroundColor,
		[Parameter(Mandatory=$false)][ConsoleColor]$BackgroundColor = (Get-Host).UI.RawUI.BackgroundColor,
		[Parameter(Mandatory=$false)]$Seperator = ' ',
		[switch]$NoNewLine
	)
	Write-Host $Object -ForegroundColor $ForegroundColor -BackgroundColor $BackgroundColor -NoNewline:$NoNewLine -Separator $Seperator
}
function Write-DebugInfo {
	param (
		[Parameter(Mandatory=$true, Position = 0)][string[]]$String,
		[switch]$NoHeader,
		[switch]$NoFooter
	)
	if ($script:ShowDebugInfo) {
		[int]$dividerLength = 0
		$String | ForEach-Object { if (($_.Length + 8) -gt $dividerLength) { $dividerLength = $_.Length + 8 }}
		if (!$NoHeader) {
			Write-Console ('-' * $dividerLength) -ForegroundColor DarkGray
			Write-Console 'Debugging Information:' -ForegroundColor DarkGray
		}
		$String | ForEach-Object {Write-Console ("`t{0}" -f $_) -ForegroundColor DarkGray }
		if (!$NoFooter) {
			Write-Console ("-" * $dividerLength) -ForegroundColor DarkGray
		}
	}
}
Function ExitScript {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$false)][string]$Path = $null
    )
	Write-Console "Exiting Script..."
	#PressAnyKey
    If (!($script:ShowDebugInfo)) { Clear-Host ; Clear-History}
    if (-not [string]::IsNullOrWhiteSpace($Path)) { Set-Location -Path $Path }
	Exit
}
Function PressAnyKey {
    Write-Console "Press any key to continue ..."
    [System.Boolean]$anyKey = $false
    do {
        [System.Management.Automation.Host.KeyInfo]$x = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown,AllowCtrlC")
        switch ($x.VirtualKeyCode) {
            {$_ -in 16,17,18} { $anyKey = $false; break; } # Shift, Control, Alt
            {$_ -in 45, 46} {
                # Shift Insert (45)  or Delete (46) - Paste or Cut
                if ($x.ControlKeyState -eq [System.Management.Automation.Host.ControlKeyStates]::ShiftPressed) { $anyKey = $false}
                # CTRL Insert (45) - Copy
                elseif ($x.ControlKeyState -eq [System.Management.Automation.Host.ControlKeyStates]::LeftCtrlPressed -or $x.ControlKeyState -eq [System.Management.Automation.Host.ControlKeyStates]::RightCtrlPressed) { $anyKey = $false}
                else { $anyKey = $true}
                break
            }
            {$_ -in 65,67,86,88} {
                # CTRL A (65), C (67), V (86), or X(88) - Select all, Copy, Paste, or Cut
                if ($x.ControlKeyState -eq [System.Management.Automation.Host.ControlKeyStates]::LeftCtrlPressed -or $x.ControlKeyState -eq [System.Management.Automation.Host.ControlKeyStates]::RightCtrlPressed) { $anyKey = $false}
                # CTRL A (65), C (67), V (86), or X(88) - Select all, Copy, Paste, or Cut
                elseif ($x.ControlKeyState -eq [System.Management.Automation.Host.ControlKeyStates]::LeftAltPressed -or $x.ControlKeyState -eq [System.Management.Automation.Host.ControlKeyStates]::RightAltPressed) { $anyKey = $false}
                else { $anyKey = $true}
                break
            }
            Default { $anyKey = $true }
        }
    } while (-not $anyKey)
}
function YesOrNo {
	param (
		[Parameter(Mandatory=$false)][string]$Prompt = "Is the above information correct? [y|n]"
	)
	[string]$response = ""
	while ($response -notmatch "[y|n]"){
		$response = Read-Host $Prompt
	}
	if ($response -match "y") { Return $true }
	else { Return $false }
}
function Show-Choices {
	param (
		[Parameter(Mandatory=$false)][string]$Title = 'Select one of the following:',
		[Parameter(Mandatory=$false)][string]$Prompt = '',
		[Parameter(Mandatory=$true)]$List,
		[Parameter(Mandatory=$false)][string]$ObjectKey = '',
		[Parameter(Mandatory=$false)][boolean]$ClearScreen = $false,
		[Parameter(Mandatory=$false)][boolean]$ShowBack = $false,
        [Parameter(Mandatory=$false)][boolean]$ShowExit = $true,
        [Parameter(Mandatory=$false)][string]$ExitPath = $null,
        [Parameter()][switch]$NoSort
	)
	if ([string]::IsNullOrWhiteSpace($ObjectKey)) { $ObjectKey = "Name"}
	if ($List.Count -eq 1) {
		Write-DebugInfo -String 'List Count is 1'
		Return $List[0]
	} elseif ($List.Count -le 0) {
		Write-DebugInfo -String 'List Count is less than 1'
		Return $null
	} else {
		if ($ClearScreen -and !($script:ShowDebugInfo)) { Clear-Host }
		Write-Console $Title
		[string]$listType = $List.GetType().Fullname
		Write-DebugInfo -String "List Type: $listType","List Count: $($List.Count)"
		[string[]]$MenuItems = @()
		switch ($listType) {
			'System.Collections.Hashtable' {
                if($NoSort){ $MenuItems = ($List.Keys | ForEach-Object ToString) }
				else { $MenuItems = ($List.Keys | ForEach-Object ToString) | Sort-Object }
				break
			}
			'System.Object[]' {
				if($NoSort){
                    $List | ForEach-Object {
                        $MenuItem = $_
                        if ($MenuItem.GetType().FullName -eq 'System.Management.Automation.PSCustomObject') { $MenuItems += $MenuItem.$ObjectKey }
                        else { $MenuItems += $MenuItem }
                    }
                }
                else {
                    $List | Sort-Object | ForEach-Object {
                        $MenuItem = $_
                        if ($MenuItem.GetType().FullName -eq 'System.Management.Automation.PSCustomObject') { $MenuItems += $MenuItem.$ObjectKey }
                        else { $MenuItems += $MenuItem }
                    }
                }
                break
            }
            'SourceSubModule[]' {
                if($NoSort) { foreach ($listItem in $List) { $MenuItems += $listItem.GetFinalName() } }
                else { foreach ($listItem in ($List | Sort-Object -Property @{Expression = {$_.GetFinalName()};Descending = $false})) { $MenuItems += $listItem.GetFinalName() } }
                break
            }
            {$_ -in 'GitRepo[]','GitRepoForked[]'} {
                if($NoSort) { foreach ($listItem in $List) { $MenuItems += $listItem.Name } }
                else { foreach ($listItem in ($List | Sort-Object -Property Name)) { $MenuItems += $listItem.Name } }
                break
            }
            {$_ -in 'BuildType[]','BuildTypeJava[]','BuildTypeGradle[]','BuildTypeMaven[]'} {
                if($NoSort) { foreach ($listItem in $List) { $MenuItems += $listItem.Origin } }
                else { foreach ($listItem in ($List | Sort-Object -Property Origin)) { $MenuItems += $listItem.Origin } }
                break
            }
			Default {
                if($NoSort) { $MenuItems = $List }
                else { $MenuItems = $List | Sort-Object }
				break
			}
		}
		[int]$counter = 1
		$MenuItems | ForEach-Object {
			Write-Console("`t{0}.  {1}" -f $counter,$_)
			$counter += 1
		}
		[int]$lowerBound = 1
		[int]$upperBound = $MenuItems.Count
		if ($ShowBack) { [string]$showBackString = '|(B)ack' } else { [string]$showBackString = '' }
		if ($ShowExit) { [string]$showExitString = '"|(Q)uit' } else { [string]$showExitString = '' }
		Write-DebugInfo "Lower Bound: $lowerBound","Upper Bound: $upperBound"
		[string]$selectionString = "[{0}-{1}{2}{3}]" -f $lowerBound,$upperBound,$showBackString,$showExitString
		if (([string]::IsNullOrWhiteSpace($Prompt))) { $Prompt = "Enter {0}" -f $selectionString }
		else { $Prompt += " {0}" -f $selectionString }
		[boolean]$exitLoop = $false
		do {
			[string]$response = Read-Host $Prompt
			$response = $response.Trim()
            Write-DebugInfo -String "Response: $response" -NoFooter
			switch -regex ( $response ) {
				'[b|back]' {
					$return = $null
					$exitLoop = $true
					break
				}
				'[q|quit|e|exit]' {
					ExitScript -Path $ExitPath
					break
				}
				Default {
					try {
						[int]$choice = $null
						if ([int32]::TryParse($response, [ref]$choice)) {
							Write-DebugInfo -String "Choice: $choice" -NoHeader
						}
						else {
							$choice = -1
							Write-DebugInfo -String "Choice could not parse: $choice" -NoHeader
						}
					}
					catch { [int]$choice = -1 }
					if (($null -ne $choice) -and ($choice -ge $lowerBound) -and ($choice -le $upperBound)) {
						[int]$choice = $choice - 1
						if ($ClearScreen -and !($script:ShowDebugInfo)) { Clear-Host }
						switch ($listType) {
							'System.Collections.Hashtable' {
								$return = $List.Get_Item($MenuItems[$choice])
								break
							}
							'System.Object[]' {
								$List | ForEach-Object {
									if ($_.GetType().FullName -eq 'System.Management.Automation.PSCustomObject') {
										$return = ($List | Where-Object {$_.$ObjectKey -eq $MenuItems[$choice]} | Select-Object -First 1)
                                    }
                                    else {
										$return = ($List | Where-Object {$_ -eq $MenuItems[$choice]} | Select-Object -First 1)
									}
								}
								break
                            }
                            'SourceSubModule[]' {
                                $return = $List | Where-Object { $_.GetFinalName() -eq $MenuItems[$choice] } | Select-Object -First 1
								break
                            }
                            {$_ -in 'GitRepo[]','GitRepoForked[]'} {
                                $return = $List | Where-Object { $_.Name -eq $MenuItems[$choice] } | Select-Object -First 1
								break
                            }
                            {$_ -in 'BuildType[]','BuildTypeJava[]','BuildTypeGradle[]','BuildTypeMaven[]'} {
                                $return = $List | Where-Object { $_.Origin -eq $MenuItems[$choice] } | Select-Object -First 1
                                break
                            }
                            Default {
								$return = $MenuItems[$choice]
								break
							}
						}
						Write-Console("Selected:  {0}" -f $MenuItems[$choice])
						$exitLoop = $true
					} else {
						$exitLoop = $false
					}
					break
				}
			}
		} while (!$exitLoop)
		Return $return
	}
}
function Show-Menu {
	param (
		[Parameter(Mandatory=$true)][System.Collections.Hashtable]$HashTable,
		[Parameter(Mandatory=$false)][boolean]$ShowBack = $false
	)
	[boolean]$exitLoop = $false
	do {
		$choice = Show-Choices -Title 'Select menu item.' -List $HashTable -ClearScreen $true -ShowBack $ShowBack
		if ([string]::IsNullOrWhiteSpace($choice)) {
			$exitLoop = $true
		} else {
			if ($choice.GetType().FullName -eq 'System.Collections.HashTable') {
				Show-Menu -HashTable $choice -ShowBack $true
			} else {
				&($choice)
				if ($script:ShowPause) { PressAnyKey }
			}
		}
	} while (-not $exitLoop)
}
function ConvertTo-Hashtable {
    [CmdletBinding()]
    [OutputType('hashtable')]
    param (
        [Parameter(ValueFromPipeline)]
        $InputObject
    )

    process {
        ## Return null if the input is null. This can happen when calling the function
        ## recursively and a property is null
        if ($null -eq $InputObject) {
            return $null
        }

        ## Check if the input is an array or collection. If so, we also need to convert
        ## those types into hash tables as well. This function will convert all child
        ## objects into hash tables (if applicable)
        if ($InputObject -is [System.Collections.IEnumerable] -and $InputObject -isnot [string]) {
            $collection = @(
                foreach ($object in $InputObject) {
                    ConvertTo-Hashtable -InputObject $object
                }
            )

            ## Return the array but don't enumerate it because the object may be pretty complex
            Write-Output -NoEnumerate $collection
        } elseif ($InputObject -is [psobject]) { ## If the object has properties that need enumeration
            ## Convert it to its own hash table and return it
            $hash = @{}
            foreach ($property in $InputObject.PSObject.Properties) {
                $hash[$property.Name] = ConvertTo-Hashtable -InputObject $property.Value
            }
            $hash
        } else {
            ## If the object isn't an array, collection, or other object, it's already a hash table
            ## So just return it.
            $InputObject
        }
    }
}
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
Function Invoke-CommandLine ($command, $workingDirectory, $timeout) {
    $pinfo = New-Object System.Diagnostics.ProcessStartInfo
    $pinfo.FileName = $env:ComSpec
    $pinfo.RedirectStandardError = $true
    $pinfo.RedirectStandardOutput = $true
    $pinfo.UseShellExecute = $false
    if ($null -eq $workingDirectory) { $pinfo.WorkingDirectory = (Get-Location).Path }
    else { $pinfo.WorkingDirectory = $workingDirectory }
    $pinfo.Arguments = "/c $command"
    $p = New-Object System.Diagnostics.Process
    $p.StartInfo = $pinfo
    $p.Start() | Out-Null
    if ($null -eq $timeout) { $timeout = 5 }
	Wait-Process $p.Id -Timeout $timeout -EA:0
	$stdOutput = $p.StandardOutput.ReadToEnd()
	$stdError  = $p.StandardError.ReadToEnd()
	$exitCode  = $p.ExitCode
    [pscustomobject]@{
        StandardOutput = $stdOutput
        StandardError = $stdError
        ExitCode = $exitCode
    }
}
function BuildSpigot {
    param (
        [string]$Version,
        [string]$ToolPath,
        [string]$JDKPath
    )
    $file = Join-Path -Path "$ToolPath" -ChildPath "spigot-$Version.jar"
    if (($null -ne (mvn dependency:get -Dartifact="org.spigotmc:spigot:$Version-R0.1-SNAPSHOT" -o -q)) -or ($null -ne (mvn dependency:get -Dartifact="org.spigotmc:spigot-api:$Version-R0.1-SNAPSHOT" -o -q))) {
        if (-not (Test-Path -Path $file)) {
            Push-Location -Path "$ToolPath" -StackName 'SpigotBuild'
            $javaCommand = [BuildTypeJava]::PushEnvJava($JDKPath)
            Write-Host "Building Craftbukkit and Spigot versions $Version"
            $javaProcess = Start-Process -FilePath "$javaCommand" -ArgumentList "-jar $ToolPath\\BuildTools.jar --rev $Version --compile CRAFTBUKKIT,SPIGOT" -NoNewWindow -PassThru
            $javaProcess.WaitForExit()
            [BuildTypeJava]::PopEnvJava()
            Pop-Location -StackName 'SpigotBuild'
        }
        Write-Host "Installing spigot $Version-R0.1-SNAPSHOT to maven local repository"
        mvn install:install-file -DgroupId='org.spigotmc' -DartifactId=spigot -Dversion="$Version-R0.1-SNAPSHOT" -Dpackaging=jar -Dfile="$file"
        Write-Host "Installing spigot-API $Version-R0.1-SNAPSHOT to maven local repository"
        mvn install:install-file -DgroupId='org.spigotmc' -DartifactId=spigot-api -Dversion="$Version-R0.1-SNAPSHOT" -Dpackaging=jar -Dfile="$file"
    }
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

## Load configuration and submodule hashtables from manage.json
LoadManageJSON -JsonContentPath "$dirRoot\manage.json" -JsonSchemaPath "$dirRoot\manage.schema.json"

## Load script configuration values from hashtable
LoadConfiguration -ConfigurationData $script:ManageJSON.configuration

## Load submodules from hashtable
LoadSourceSubModules -SubmodulesData $script:ManageJSON.submodules -SourcesArray ([ref]$sources)

do { # Main loop
    Clear-Host
    Show-WhatIfInfo
    Show-DirectoryInfo
    $menuItems =  @(
        'Build - Compile All',
        'Build - Compile One',
        'Build - Get Versions',
        'Repositories - Display Details',
        'Repositories - Archive Untracked',
        'Repositories - Checkout',
        'Repositories - Clean',
        'Repositories - Reset',
        'Configuration - Reload Generic',
        'Configuration - Reload Submodules',
        'Configuration - Toggle WhatIF',
        'Configuration - Toggle ForcePull'
    )
	$choice = Show-Choices -Title 'Select an action' -List $menuItems -NoSort -ExitPath $dirStartup
	switch ($choice) {
        'Repositories - Display Details'{
            Push-Location -Path $dirSources -StackName 'MainLoop'
            Write-Host "Displaying Repository Details"
            foreach ($currentSource in $sources) {
                $dirCurrent = Join-Path -Path $dirSources -ChildPath $currentSource.Name
                Set-Location -Path $dirCurrent
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
                $currentSource.Repo.InvokeReset()
            }
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