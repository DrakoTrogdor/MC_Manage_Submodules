#################
# Declare Enums #
#################
enum OutputType {
    Other
    Server
    Script
    Plugin
    VelocityPlugin
    Module
    ServerModule
    ClientModule
    AlternateModule
    DataPack
    ResourcePack
    NodeDependancy
    SubModuleDependency
}

###########################
# Declare Class BuildType #
###########################
class BuildType {
    [string]$Command
    [string]$InitCommand
	[string]$PreCommand
	[string]$PostCommand
	[string]$VersionCommand
    [OutputType]$OutputType
	[string]$Output
    [System.Boolean]$PerformBuild
    [string] hidden $generatedRawVersion = $null
    [string] hidden $generatedCleanVersion = $null
    [void] hidden Init([string]$Command,[string]$InitCommand,[string]$PreCommand,[string]$PostCommand,[string]$VersionCommand,[OutputType]$OutputType,[string]$Output,[System.Boolean]$PerformBuild) {
		$this.Command = $Command
        $this.InitCommand = $InitCommand
		$this.PreCommand = $PreCommand
		$this.PostCommand = $PostCommand
		$this.VersionCommand = $VersionCommand
        $this.OutputType = $OutputType
		$this.Output = $Output
		$this.PerformBuild = $PerformBuild
    }
    BuildType() {
        $this.Init($null, $null, $null, $null, $null, [OutputType]::Other, $null, $true)
    }
	BuildType([string]$Command,[string]$InitCommand,[string]$PreCommand,[string]$PostCommand,[string]$VersionCommand,[OutputType]$OutputType,[string]$Output,[System.Boolean]$PerformBuild){
		$this.Init($Command, $InitCommand, $PreCommand, $PostCommand, $VersionCommand, $OutputType, $Output, $PerformBuild)
    }
    BuildType([Hashtable]$Value){
        if($Value.Contains('Command'))          { $this.Command         = $this.FlattenString($Value.Command)        }
        if($Value.Contains('InitCommand'))      { $this.InitCommand     = $this.FlattenString($Value.InitCommand)    }
        if($Value.Contains('PreCommand'))       { $this.PreCommand      = $this.FlattenString($Value.PreCommand)     }
        if($Value.Contains('PostCommand'))      { $this.PostCommand     = $this.FlattenString($Value.PostCommand)    }
        if($Value.Contains('VersionCommand'))   { $this.VersionCommand  = $this.FlattenString($Value.VersionCommand) }

        # Set the Output Type enum
        [OutputType]$tmpOutputType = [OutputType]::Other
        if ($Value.Contains('OutputType')){
            switch ($Value.OutputType) {
                "Other"               { $tmpOutputType = [OutputType]::Other;               break }
                "Server"              { $tmpOutputType = [OutputType]::Server;              break }
                "Script"              { $tmpOutputType = [OutputType]::Script;              break }
                "Plugin"              { $tmpOutputType = [OutputType]::Plugin;              break }
                "VelocityPlugin"      { $tmpOutputType = [OutputType]::VelocityPlugin;      break }
                "Module"              { $tmpOutputType = [OutputType]::Module;              break }
                "ServerModule"        { $tmpOutputType = [OutputType]::ServerModule;        break }
                "ClientModule"        { $tmpOutputType = [OutputType]::ClientModule;        break }
                "AlternateModule"     { $tmpOutputType = [OutputType]::AlternateModule;     break }
                "DataPack"            { $tmpOutputType = [OutputType]::DataPack;            break }
                "ResourcePack"        { $tmpOutputType = [OutputType]::ResourcePack;        break }
                "NodeDependancy"      { $tmpOutputType = [OutputType]::NodeDependancy;      break }
                "SubModuleDependancy" { $tmpOutputType = [OutputType]::SubModuleDependancy; break }
                default               { $tmpOutputType = [OutputType]::Other                      }
            }
        }
        $this.OutputType = $tmpOutputType

        if($Value.Contains('Output'))           { $this.Output          = [string]$Value.Output                }
        if($Value.Contains('PerformBuild'))     { $this.PerformBuild    = [System.Boolean]$Value.PerformBuild  }
        else { $this.PerformBuild = $true }
    }
    [string]GetOutput()	        		{ [string]$return = ([string]::IsNullOrWhiteSpace($this.Output)         ? $null : $this.Output);                                return $return; }
    [string]GetOutputFileName()			{ [string]$return = ([string]::IsNullOrWhiteSpace($this.Output)         ? $null : (Split-Path -Path $this.Output -Leaf));       return $return; }
    [string]GetOutputFileBase()			{ [string]$return = ([string]::IsNullOrWhiteSpace($this.Output)         ? $null : (Split-Path -Path $this.Output -LeafBase));   return $return; }
    [string]GetOutputExtension()		{ [string]$return = ([string]::IsNullOrWhiteSpace($this.Output)         ? $null : (Split-Path -Path $this.Output -Extension));  return $return; }
    [string]GetCommand()				{ [string]$return = ([string]::IsNullOrWhiteSpace($this.Command)        ? $null : $this.Command);                               return $return; }
    [string]GetInitCommand()			{ [string]$return = ([string]::IsNullOrWhiteSpace($this.InitCommand)    ? $null : $this.InitCommand);                           return $return; }
    [string]GetPreCommand()				{ [string]$return = ([string]::IsNullOrWhiteSpace($this.PreCommand)     ? $null : $this.PreCommand);                            return $return; }
    [string]GetPostCommand()			{ [string]$return = ([string]::IsNullOrWhiteSpace($this.PostCommand)    ? $null : $this.PostCommand);                           return $return; }
    [string]GetVersionCommand()			{ [string]$return = ([string]::IsNullOrWhiteSpace($this.VersionCommand) ? $null : $this.VersionCommand);                        return $return; }

    [string]GetVersion() {
        return $this.GetVersion($false)
    }
    [string]GetVersion([switch]$RawVersion) {
        if([string]::IsNullOrWhiteSpace($this.generatedRawVersion))   {
            if ([string]::IsNullOrWhiteSpace($this.VersionCommand)) {
                $this.generatedRawVersion = ""
            }
            elseif ($this.VersionCommand -match '^(?:\"(.*)\"|\"?(\d+\.\d+\.\d+)\"?)$'){
                $this.generatedRawVersion = $Matches[1]
            }
            else {
                [String]$tempCommand = $this.VersionCommand
                $this.generatedRawVersion  = (Invoke-Expression -Command "$tempCommand")
            }
        }
        if([string]::IsNullOrWhiteSpace($this.generatedCleanVersion)) { $this.generatedCleanVersion = $this.CleanVersion($this.generatedRawVersion) }
        if($RawVersion) { return $this.generatedRawVersion }
        else { return $this.generatedCleanVersion }
    }

    [System.Boolean]HasCommand()        { return -not [string]::IsNullOrWhiteSpace($this.Command)     }
    [System.Boolean]HasInitCommand()    { return -not [string]::IsNullOrWhiteSpace($this.InitCommand)    }
    [System.Boolean]HasPreCommand()     { return -not [string]::IsNullOrWhiteSpace($this.PreCommand)     }
    [System.Boolean]HasPostCommand()    { return -not [string]::IsNullOrWhiteSpace($this.PostCommand)    }
    [System.Boolean]HasVersionCommand() { return -not [string]::IsNullOrWhiteSpace($this.VersionCommand) }
    [System.Boolean]HasOutput()         { return -not [string]::IsNullOrWhiteSpace($this.Output)         }
    [string]FlattenString($Value) {
        [string]$return = $null
        switch (($Value.GetType()).FullName) {
            'System.String'   { $return = $Value;              break  }
            'System.String[]' { $return = $Value -join "`r`n"; break  }
            'System.Object[]' { $return = $Value -join "`r`n"; break  }
            Default           { $return = ($Value.GetType()).FullName }
        }
        return $return
    }
    [string]ReplaceScriptJAVA_HOME([string]$Value) {
        for ($version = 8; $version -le 17; $version++) {
            $Value = $Value.Replace("`$(`$script:JAVA_HOME.$($version))",$global:JAVA_HOME.$version)
        }
        return $Value
    }
    [string]GetInvokeBuildConsoleDescription(){
        return "Basic Task: $($this.Command)"
    }
    InvokeInitBuild(){ $this.InvokeInitBuild($false) }
    InvokePreBuild(){ $this.InvokePreBuild($false) }
    InvokeBuild(){ $this.InvokeBuild($false) }
    InvokePostBuild(){ $this.InvokePostBuild($false) }

    InvokeInitBuild([switch]$WhatIF){
        if ($this.HasInitCommand()) { 
            [string]$thisCommand = $this.ReplaceScriptJAVA_HOME($this.GetInitCommand())
            if ($WhatIF) { Write-Console "$thisCommand" -Title 'WhatIF' }
            else { Invoke-Expression $thisCommand }
        }
    }
    InvokePreBuild([switch]$WhatIF){
        if ($this.HasPreCommand()) { 
            [string]$thisCommand = $this.ReplaceScriptJAVA_HOME($this.GetPreCommand())
            if ($WhatIF) { Write-Console "$thisCommand" -Title 'WhatIF'}
            else { Invoke-Expression $thisCommand }
        }
    }
    InvokeBuild([switch]$WhatIF){
        if ($this.HasCommand()) { 
            [string]$thisCommand = $this.ReplaceScriptJAVA_HOME($this.GetCommand())
            $thisCommandConsole = $this.GetInvokeBuildConsoleDescription()
            if ($WhatIF) { Write-Console "$thisCommandConsole" -Title 'WhatIF'}
            else {
                Write-Console "`"$thisCommandConsole`""  -Title 'Executing'
                $currentProcess = Start-Process -FilePath "$env:ComSpec" -ArgumentList "/c $thisCommand" -NoNewWindow -PassThru
                $currentProcess.WaitForExit()
            }
        }
    }
    InvokePostBuild([switch]$WhatIF){
        if ($this.HasPostCommand()) { 
            [string]$thisCommand = $this.ReplaceScriptJAVA_HOME($this.GetPostCommand())
            if ($WhatIF) { Write-Console "$thisCommand" -Title 'WhatIF' }
            else { Invoke-Expression $thisCommand }
        }
    }

    [string]CleanVersion([string]$Value) {
        if ([string]::IsNullOrWhiteSpace($Value)) { return '' }

        $return = ($Value -replace "[$(-join ([System.Io.Path]::GetInvalidPathChars()| ForEach-Object {"\x$([Convert]::ToString([byte]$_,16).PadLeft(2,'0'))"}))]", '').Trim()

        # Quick check if purely a proper SemVer
        if ($return -imatch "^\s*v?0*(?'major'\d+)\s*$")                                   { return "$($Matches['major']).0.0" }
		if ($return -imatch "^\s*v?0*(?'major'\d+)\.0*(?'minor'\d+)\s*$")                  { return "$($Matches['major']).$($Matches['minor']).0"}
        if ($return -imatch "^\s*v?0*(?'major'\d+)\.0*(?'minor'\d+)\.0*(?'patch'\d+)\s*$") { return "$($Matches['major']).$($Matches['minor']).$($Matches['patch'])"}


        [string]$sep = '[' + [System.Text.RegularExpressions.Regex]::Escape('-+') + ']'
        [string[]]$removables = @(
            'kotlin(?:\.\d+){3}(?:\.local)?',
            '(?:custom|local|snapshot|nightly)',
            '(?:alpha|beta|dev|fabric|pre|rc|arne)(?:[\.\+\-]?(?:\d+|null)(?=[\.\+\-]|$))*',
            '\d{2}w\d{2}[a-z]',
            'v\d{6,}',
            '(?:rev\.)?[0-9a-f]{7,8}',
            'R\d\.\d'
        )
		foreach ($item in $removables) {
            [System.Boolean]$matchFound = $false
            do {
                $matchFound = $false
                if ($return -imatch "^\s*(?:(?'before'.+)$($sep)+)?$($item)(?:$($sep)+(?'after'.+))?\s*`$") {
                    if (-not [string]::IsNullOrWhiteSpace($Matches['before']) -and [string]::IsNullOrWhiteSpace($Matches['after'])) { $return = $Matches['before'] }
                    elseif ([string]::IsNullOrWhiteSpace($Matches['before']) -and -not [string]::IsNullOrWhiteSpace($Matches['after'])) { $return = $Matches['after'] }
                    else { $return = $Matches['before'] + '-' + $Matches['after'] }
                    $matchFound = $true
                }
            } while ($matchFound)
		}

        # Everything was removed by the "removables" foreach loop
        if ($return -like '-') { return '0.0.0' }


        [string]$mcVer  = "(?:mc)?1\.(?:19(?:\.[0-4xX])?|20(?:\.[0-1xX])?)(?!\.\d+)(?:\.?[0-9a-f]{7,8})?" #This matches the versions from 1.19 to 1.20.1 (Optional 7 to 8 digit commit'ish)
        [string]$semVer = "v?(?<![\dxX]\.)(?:\d+\.){0,3}(?:\d+|[xX])(?!\.(\d+|[xX]))" # Version like number (allow extra digit in semver)
    
        # If all that is left is an MC version and a single digit version format it as MCVersion.Version
        if ($return -imatch "^\s*(?'mcVer'$($mcVer))$($sep)v?(?'buildVer'\d+)\s*$") {
            [string]$returnedMCVer = "$($Matches['mcVer'])"
            [string]$returnedBuild = "$($Matches['buildVer'])"
            if ($returnedMCVer -imatch "^\s*v?0*(?'major'\d+)\s*$")                                   { $returnedMCVer = "$($Matches['major']).0.0" }
            if ($returnedMCVer -imatch "^\s*v?0*(?'major'\d+)\.0*(?'minor'\d+)\s*$")                  { $returnedMCVer = "$($Matches['major']).$($Matches['minor']).0" }
            if ($returnedMCVer -imatch "^\s*v?0*(?'major'\d+)\.0*(?'minor'\d+)\.0*(?'patch'\d+)\s*$") { $returnedMCVer = "$($Matches['major']).$($Matches['minor']).$($Matches['patch'])" }
            $return = "$returnedMCVer.$returnedBuild"
        }

        # Remove MC version if both an MC version and submodule version exist
        if ($return -imatch "^\s*$($mcVer)$($sep)(?'match'$($semVer))\s*$") { $return = "$($Matches['match'])" }
        if ($return -imatch "^\s*(?'match'$($semVer))$($sep)$($mcVer)\s*$") { $return = "$($Matches['match'])" }

        # Format as proper semver (allow for an extra build number if it exists)
        if ($return -imatch "^\s*v?0*(?'major'\d+)\s*$")                                                    { $return = "$($Matches['major']).0.0" }
		if ($return -imatch "^\s*v?0*(?'major'\d+)\.0*(?'minor'\d+)\s*$")                                   { $return = "$($Matches['major']).$($Matches['minor']).0" }
        if ($return -imatch "^\s*v?0*(?'major'\d+)\.0*(?'minor'\d+)\.0*(?'patch'\d+)\s*$")                  { $return = "$($Matches['major']).$($Matches['minor']).$($Matches['patch'])" }
        if ($return -imatch "^\s*v?0*(?'major'\d+)\.0*(?'minor'\d+)\.0*(?'patch'\d+)\.0*(?'build'\d+)\s*$") { $return = "$($Matches['major']).$($Matches['minor']).$($Matches['patch']).$($Matches['build'])" }

        return $return
	}
}

###############################
# Declare Class BuildTypeJava #
###############################
class BuildTypeJava : BuildType {
	[System.Boolean]$UseNewJAVA_HOME = $false
	[string]$JAVA_HOME
    [string] hidden $originalJAVA_HOME
    [void] hidden Init($JAVA_HOME) {
		$this.UseNewJAVA_HOME = -not [string]::IsNullOrWhiteSpace($JAVA_HOME)
		$this.JAVA_HOME  = $JAVA_HOME
		$this.originalJAVA_HOME = $env:JAVA_HOME
    }
    BuildTypeJava() : base() {}
	BuildTypeJava([string]$Command,[string]$InitCommand,[string]$PreCommand,[string]$PostCommand,[string]$VersionCommand,[string]$Output,[System.Boolean]$PerformBuild,[string]$JAVA_HOME) : base ($Command,$InitCommand,$PreCommand,$PostCommand,$VersionCommand,$Output,$PerformBuild) {
        $this.Init($JAVA_HOME)
    }
    BuildTypeJava([Hashtable]$Value) : base ($Value) {
        if($Value.Contains('JAVA_HOME')) { $this.Init($Value.JAVA_HOME) }
    }
	[string] hidden GetJAVA_HOME(){
		if ($this.UseNewJAVA_HOME) { return $this.JAVA_HOME }
		else { return $env:JAVA_HOME }
    }

    [string] hidden static $origEnvJAVA_HOME
    [string] hidden static $origEnvPath
    [string] static PushEnvJava($Value){
        if ([string]::IsNullOrWhiteSpace([BuildTypeJava]::origEnvJAVA_HOME)) { [BuildTypeJava]::origEnvJAVA_HOME = $env:JAVA_HOME }
        if ([string]::IsNullOrWhiteSpace([BuildTypeJava]::origEnvPath))      { [BuildTypeJava]::origEnvPath      = $env:Path      }
        $env:JAVA_HOME = $Value
        [string]$javaBin = Join-Path -Path $Value -ChildPath 'bin'
        $env:Path      = $env:Path -replace '([A-Z]:\\[^\;]+\\jdk-\d+\.\d+\.\d+[\.\+]\d+(-hotspot)?\\bin;)+',"$($javaBin);"
        return Join-Path -Path $javaBin -ChildPath 'java.exe'
    }
    [string] static PopEnvJava(){
        if (-not [string]::IsNullOrWhiteSpace([BuildTypeJava]::origEnvJAVA_HOME)) { $env:JAVA_HOME = [BuildTypeJava]::origEnvJAVA_HOME; [BuildTypeJava]::origEnvJAVA_HOME = $null }
        if (-not [string]::IsNullOrWhiteSpace([BuildTypeJava]::origEnvPath))      { $env:Path      = [BuildTypeJava]::origEnvPath;      [BuildTypeJava]::origEnvPath      = $null }
        return Join-Path -Path $env:JAVA_HOME -ChildPath 'bin' -AdditionalChildPath 'java.exe'
    }
	[void]PushJAVA_HOME() { if ($this.UseNewJAVA_HOME) { [BuildTypeJava]::PushEnvJava($this.GetJAVA_HOME()) } }
    [void]PopJAVA_HOME()  { if ($this.UseNewJAVA_HOME) { [BuildTypeJava]::PopEnvJava()                      } }

    [string]GetInvokeBuildConsoleDescription(){
        return "Java: $($this.Command)"
    }

    InvokeInitBuild()               { $this.InvokeInitBuild($false) }
    InvokePreBuild()                { $this.InvokePreBuild($false) }
    InvokeBuild()                   { $this.InvokeBuild($false) }
    InvokePostBuild()               { $this.InvokePostBuild($false) }
    InvokeInitBuild([switch]$WhatIF){
        $this.PushJAVA_HOME()
        ([BuildType]$this).InvokeInitBuild($WhatIF)
        $this.PopJAVA_HOME()
    }
    InvokePreBuild([switch]$WhatIF) {
        $this.PushJAVA_HOME()
        ([BuildType]$this).InvokePreBuild($WhatIF)
        $this.PopJAVA_HOME()
    }
    InvokeBuild([switch]$WhatIF)    {
        $this.PushJAVA_HOME()
        Write-Console "`"$($env:JAVA_HOME)`"" -Title 'JAVA_HOME'
        ([BuildType]$this).InvokeBuild($WhatIF)
        $this.PopJAVA_HOME()
    }
    InvokePostBuild([switch]$WhatIF){
        $this.PushJAVA_HOME()
        ([BuildType]$this).InvokePostBuild($WhatIF)
        $this.PopJAVA_HOME()
    }
}

#################################
# Declare Class BuildTypeGradle #
#################################
class BuildTypeGradle : BuildTypeJava {
    [string]$JAVA_OPTS

    # -DXlint:none to remove Linting warning from showing up at all
    [string[]] static $gradleOptions = @('--no-daemon', '--quiet', '--warning-mode=none', '--console=rich', '-DXdoclint=none', '-DXlint=none')

    # Do not use '.\gradlew.bat' in order to bypass issues with batch file incompatibilities. Added UTF-8 encoding to reduce compilation warnings
    [string] static $gradlew = 'java "-Dfile.encoding=UTF-8" "-Dsun.stdout.encoding=UTF-8" "-Dsun.stderr.encoding=UTF-8" "-Dorg.gradle.appname=gradlew" -classpath ".\gradle\wrapper\gradle-wrapper.jar" org.gradle.wrapper.GradleWrapperMain'

    BuildTypeGradle() : base('build',$null,$null,$null,'properties','build\libs\*.jar',$true,$null) {}
    BuildTypeGradle([string]$Command,[string]$InitCommand,[string]$PreCommand,[string]$PostCommand,[string]$VersionCommand,[string]$Output,[System.Boolean]$PerformBuild,[string]$JAVA_HOME,[string]$JAVA_OPTS) : base($Command,$InitCommand,$PreCommand,$PostCommand,$VersionCommand,$Output,$PerformBuild,$JAVA_HOME) {
        $this.JAVA_OPTS = $JAVA_OPTS
    }
    BuildTypeGradle([Hashtable]$Value) : base ($Value) {
        if(-not $Value.Contains('Command')) { $this.Command = 'build' }
        if(-not $Value.Contains('VersionCommand')) { $this.VersionCommand = 'properties' }
        if(-not $Value.Contains('Output')) { $this.Output = 'build\libs\*.jar' }
        if($Value.Contains('JAVA_OPTS')) { $this.JAVA_OPTS = $Value.JAVA_OPTS }
    }

    [string] hidden GetGradleInvokeString([string]$gradleTask) {
        [string]$gradlewInvokeString = [string]::IsNullOrWhiteSpace($this.JAVA_OPTS) ? $([BuildTypeGradle]::gradlew) : $([BuildTypeGradle]::gradlew) -replace '^java', "java $($this.JAVA_OPTS)"
        return "$gradlewInvokeString $gradleTask $([BuildTypeGradle]::gradleOptions -join ' ')".Trim()
    }

    [string]GetCommand() {
        [string]$buildCommand = [string]::IsNullOrWhiteSpace($this.Command) ? 'build' : $this.Command
        return $this.GetGradleInvokeString($buildCommand)
    }
    [string]GetVersion(){ return $this.GetVersion($false) }
    [string]GetVersion([switch]$RawVersion) {
        if([string]::IsNullOrWhiteSpace($this.generatedRawVersion)) {
            [string]$versionCommand = [string]::IsNullOrWhiteSpace($this.VersionCommand) ? 'properties' : $this.VersionCommand
            [string]$return = ''
            if ($versionCommand -match '^(?:\"(.*)\"|\"?(\d+\.\d+\.\d+)\"?)$'){
                $return = $Matches[1]
            }
            else {
                $this.CheckGradleInstall()
                $this.PushJAVA_HOME()
                [string]$gradlewCommand = $this.GetGradleInvokeString($versionCommand) -replace '--console=rich', '--console=plain'

                # --configure-on-demand used to speed up version info by not configuring projects that are not being used.
                [Object[]]$tempReturn  = (Invoke-Expression -Command "$gradlewCommand --configure-on-demand *>&1")

                #Sometimes gradle needs to be executed once before it will return without an error, also --configure-on-demand might not work properly.
                if(($null -ne $tempReturn) -and (($tempReturn -imatch 'A problem occurred configuring root project') -or $tempReturn -imatch 'A problem occurred evaluating project.*')) {
                    [Object[]]$tempReturn  = (Invoke-Expression -Command "$gradlewCommand *>&1")
                }

                $this.PopJAVA_HOME()
                [string]$tempReturn = $null -eq $tempReturn ? 'ERROR CHECKING VERSION' : [System.String]::Join("`r`n",$tempReturn)
                if ($tempReturn -imatch '(?:^|\r?\n)(full|build|mod_|project|projectBase)[vV]ersion: (?''version''.*)(?:\r?\n|\z|$)') { $return = $Matches['version'] }
                elseif ($tempReturn -imatch '(?:^|\r?\n)[vV]ersion: (?''version''.*)(?:\r?\n|\z|$)') { $return = $Matches['version'] }
                else { $return = '' }
            }
            $this.generatedRawVersion = $return
        }
        if(-not $RawVersion -and [string]::IsNullOrWhiteSpace($this.generatedCleanVersion)) {
            $this.generatedCleanVersion = $this.CleanVersion($this.generatedRawVersion)
        }
        if ($RawVersion) { return $this.generatedRawVersion }
        else { return $this.generatedCleanVersion }
    }
    [string]GetInvokeBuildConsoleDescription() {
        return "Gradle Task: $($this.Command)"
    }

    InvokeInitBuild()               { $this.InvokeInitBuild($false) }
    InvokePreBuild()                { $this.InvokePreBuild($false) }
    InvokeBuild()                   { $this.InvokeBuild($false) }
    InvokePostBuild()               { $this.InvokePostBuild($false) }
    InvokeInitBuild([switch]$WhatIF){ ([BuildTypeJava]$this).InvokeInitBuild($WhatIF) }
    InvokePreBuild([switch]$WhatIF) { ([BuildTypeJava]$this).InvokePreBuild($WhatIF)  }
    InvokeBuild([switch]$WhatIF)    {
        $this.CheckGradleInstall()
        ([BuildTypeJava]$this).InvokeBuild($WhatIF)
    }
    InvokePostBuild([switch]$WhatIF){ ([BuildTypeJava]$this).InvokePostBuild($WhatIF) }

    [void] hidden CheckGradleInstall(){
        if (-not (Test-Path -Path '.\gradlew.bat')) {
            $GradleBuild = '7.6'
            $url = "https://services.gradle.org/distributions/gradle-$($GradleBuild)-bin.zip"
            $file = Split-Path -Path "$url" -Leaf
            Invoke-WebRequest -Uri $url -OutFile $file
            Expand-Archive -Path $file -DestinationPath .
            $this.PushJAVA_HOME()
            Invoke-Expression ".\gradle-$($GradleBuild)\bin\gradle.bat wrapper --no-daemon"
            $this.PopJAVA_HOME()
        }
    }
}
class BuildTypeMaven : BuildTypeJava {
	BuildTypeMaven() : base('install',$null,$null,$null,$null,'target\*.jar',$true,$null) {}
	BuildTypeMaven([string]$Command,[string]$InitCommand,[string]$PreCommand,[string]$PostCommand,[string]$VersionCommand,[string]$Output,[System.Boolean]$PerformBuild,[string]$JAVA_HOME) : base($Command,$InitCommand,$PreCommand,$PostCommand,$VersionCommand,$Output,$PerformBuild,$JAVA_HOME) {}
    BuildTypeMaven([Hashtable]$Value) : base ($Value) {
        if(-not $Value.Contains('Command')) { $this.Command = 'install' }
        if(-not $Value.Contains('VersionCommand')) { $this.VersionCommand = 'project.version' }
        if(-not $Value.Contains('Output')) { $this.Output = 'target\*.jar' }
    }
	[string]GetCommand() {
		[string]$buildCommand = [string]::IsNullOrWhiteSpace($this.Command) ? 'install' : $this.Command
		return "mvn $buildCommand -q -U"
	}
    [string]GetVersion(){ return $this.GetVersion($false) }
	[string]GetVersion([switch]$RawVersion) {
        if([string]::IsNullOrWhiteSpace($this.generatedRawVersion) -or $this.generatedRawVersion -eq 'ERROR CHECKING VERSION') {
            [string]$versionCommand = [string]::IsNullOrWhiteSpace($this.VersionCommand) ? 'project.version' : $this.VersionCommand
            [string]$return = ''
            if ($versionCommand -match '^\"(.*)\"$'){
                $return = $Matches[1]
            }
            else {
                $this.PushJAVA_HOME()
                $return = (mvn help:evaluate -Dexpression="$versionCommand" -q -DforceStdout)
                if ([string]::IsNullOrWhiteSpace($return)) { $return = 'ERROR CHECKING VERSION' }
                $this.PopJAVA_HOME()
            }
            $this.generatedRawVersion = $return
        }
        if(-not $RawVersion -and [string]::IsNullOrWhiteSpace($this.generatedCleanVersion)) {
            $this.generatedCleanVersion = $this.CleanVersion($this.generatedRawVersion)
        }
        if ($RawVersion) { return $this.generatedRawVersion }
        else { return $this.generatedCleanVersion }
    }

    [string]GetInvokeBuildConsoleDescription() {
        return "Maven Task: $($this.Command)"
    }

    InvokeInitBuild()               { $this.InvokeInitBuild($false) }
    InvokePreBuild()                { $this.InvokePreBuild($false) }
    InvokeBuild()                   { $this.InvokeBuild($false) }
    InvokePostBuild()               { $this.InvokePostBuild($false) }
    InvokeInitBuild([switch]$WhatIF){ ([BuildTypeJava]$this).InvokeInitBuild($WhatIF) }
    InvokePreBuild([switch]$WhatIF) { ([BuildTypeJava]$this).InvokePreBuild($WhatIF)  }
    InvokeBuild([switch]$WhatIF)    { ([BuildTypeJava]$this).InvokeBuild($WhatIF)     }
    InvokePostBuild([switch]$WhatIF){ ([BuildTypeJava]$this).InvokePostBuild($WhatIF) }
}
class BuildTypeNPM : BuildType {
    [string]$Name
    [string[]]$Dependancies
    BuildTypeNPM(){}
}