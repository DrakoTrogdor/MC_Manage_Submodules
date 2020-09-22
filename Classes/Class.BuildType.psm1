###########################
# Declare Class BuildType #
###########################
class BuildType {
    [string]$Command
    [string]$InitCommand
	[string]$PreCommand
	[string]$PostCommand
	[string]$VersionCommand
	[string]$Output
    [System.Boolean]$PerformBuild
    [string] hidden $generatedRawVersion = $null
    [string] hidden $generatedCleanVersion = $null
    [void] hidden Init([string]$Command,[string]$InitCommand,[string]$PreCommand,[string]$PostCommand,[string]$VersionCommand,[string]$Output,[System.Boolean]$PerformBuild) {
		$this.Command = $Command
		$this.InitCommand = $InitCommand
		$this.PreCommand = $PreCommand
		$this.PostCommand = $PostCommand
		$this.VersionCommand = $VersionCommand
		$this.Output = $Output
		$this.PerformBuild = $PerformBuild
    }
    BuildType() {
        $this.Init($null, $null, $null, $null, $null, $null, $true)
    }
	BuildType([string]$Command,[string]$InitCommand,[string]$PreCommand,[string]$PostCommand,[string]$VersionCommand,[string]$Output,[System.Boolean]$PerformBuild){
		$this.Init($Command, $InitCommand, $PreCommand, $PostCommand, $VersionCommand, $Output, $PerformBuild)
    }
    BuildType([Hashtable]$Value){
        if($Value.Contains('Command'))          { $this.Command         = $this.FlattenString($Value.Command)        }
        if($Value.Contains('InitCommand'))      { $this.InitCommand     = $this.FlattenString($Value.InitCommand)    }
        if($Value.Contains('PreCommand'))       { $this.PreCommand      = $this.FlattenString($Value.PreCommand)     }
        if($Value.Contains('PostCommand'))      { $this.PostCommand     = $this.FlattenString($Value.PostCommand)    }
        if($Value.Contains('VersionCommand'))   { $this.VersionCommand  = $this.FlattenString($Value.VersionCommand) }
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
        if([string]::IsNullOrWhiteSpace($this.generatedRawVersion))   { $this.generatedRawVersion   = $this.VersionCommand }
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

    InvokeInitBuild(){ $this.InvokeInitBuild($false) }
    InvokePreBuild(){ $this.InvokePreBuild($false) }
    InvokeBuild(){ $this.InvokeBuild($false) }
    InvokePostBuild(){ $this.InvokePostBuild($false) }

    InvokeInitBuild([switch]$WhatIF){
        if ($this.HasInitCommand()) { 
            if ($WhatIF) { Write-Console "$($this.GetInitCommand())" -Title 'WhatIF' }
            else { Invoke-Expression $($this.GetInitCommand()) }
        }
    }
    InvokePreBuild([switch]$WhatIF){
        if ($this.HasPreCommand()) { 
            if ($WhatIF) { Write-Console "$($this.GetPreCommand())" -Title 'WhatIF'}
            else { Invoke-Expression $($this.GetPreCommand()) }
        }
    }
    InvokeBuild([switch]$WhatIF){
        if ($this.HasCommand()) { 
            if ($WhatIF) { Write-Console "$($this.GetCommand())" -Title 'WhatIF'}
            else {
                [string]$buildCommand = $this.GetCommand()
                Write-Console "`"$buildCommand`""  -Title 'Executing'
                $currentProcess = Start-Process -FilePath "$env:ComSpec" -ArgumentList "/c $buildCommand" -NoNewWindow -PassThru
                $currentProcess.WaitForExit()
            }
        }
    }
    InvokePostBuild([switch]$WhatIF){
        if ($this.HasPostCommand()) { 
            if ($WhatIF) { Write-Console "$($this.GetPostCommand())" -Title 'WhatIF' }
            else { Invoke-Expression $($this.GetPostCommand()) }
        }
    }

    [string]CleanVersion([string]$Value) {
        if ([string]::IsNullOrWhiteSpace($Value)) { return '' }

        [string]$ver = "1\.16(?:\.[0-3])?"
        $return = ($Value -replace "[$(-join ([System.Io.Path]::GetInvalidPathChars()| ForEach-Object {"\x$([Convert]::ToString([byte]$_,16).PadLeft(2,'0'))"}))]", '').Trim()

        if ($return -match "^[1-9]\d*\.\d+.\d+$") { return $return }
        if ($return -match "^1\.16$")             { return '1.16.0' }

        [string]$sep = '[' + [System.Text.RegularExpressions.Regex]::Escape('-+') + ']'
        [string[]]$removables = @('custom','local','snapshot','(alpha|beta|dev|fabric|pre|rc|arne)(\.?\d+)*','\d{2}w\d{2}[a-z]',"v\d{6,}","$ver")
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
		if ($return -imatch "^\s*v?(?'match'\d+)\s*$") { $return = "$($Matches['match']).0.0"}
		if ($return -imatch "^\s*v?(?'match'\d+\.\d+)\s*$") { $return = "$($Matches['match']).0"}
        if ($return -imatch "^\s*v?0*(?'match'\d+\.\d+\.\d+)\s*$") { $return = "$($Matches['match'])"}
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
    [string] static $gradlew = 'java "-Dfile.encoding=UTF-8" "-Dsun.stdout.encoding=UTF-8" "-Dsun.stderr.encoding=UTF-8" "-Dorg.gradle.appname=gradlew" -classpath ".\gradle\wrapper\gradle-wrapper.jar" org.gradle.wrapper.GradleWrapperMain' # -Xmx64m -Xms64m 
    # Changed the following line to above in order to bypass error issues with batch file incompatibilities. Added UTF-8 encoding to reduce compilation warnings
    # [string] static $gradlew = '.\gradlew.bat'
    BuildTypeGradle() : base('build',$null,$null,$null,'properties','build\libs\*.jar',$true,$null) {}
    BuildTypeGradle([string]$Command,[string]$InitCommand,[string]$PreCommand,[string]$PostCommand,[string]$VersionCommand,[string]$Output,[System.Boolean]$PerformBuild,[string]$JAVA_HOME) : base($Command,$InitCommand,$PreCommand,$PostCommand,$VersionCommand,$Output,$PerformBuild,$JAVA_HOME) {}
    BuildTypeGradle([Hashtable]$Value) : base ($Value) {
        if(-not $Value.Contains('Command')) { $this.Command = 'build' }
        if(-not $Value.Contains('VersionCommand')) { $this.VersionCommand = 'properties' }
        if(-not $Value.Contains('Output')) { $this.Output = 'build\libs\*.jar' }
    }
    [string]GetCommand() {
        [string]$buildCommand = [string]::IsNullOrWhiteSpace($this.Command) ? 'build' : $this.Command
        return "$([BuildTypeGradle]::gradlew) $buildCommand --no-daemon --quiet --warning-mode=none --console=rich" #-`"Dorg.gradle.logging.level`"=`"quiet`" -`"Dorg.gradle.warning.mode`"=`"none`" -`"Dorg.gradle.console`"=`"rich`"
    }
    [string]GetVersion(){ return $this.GetVersion($false) }
    [string]GetVersion([switch]$RawVersion) {
        if([string]::IsNullOrWhiteSpace($this.generatedRawVersion)) {
            [string]$versionCommand = [string]::IsNullOrWhiteSpace($this.VersionCommand) ? 'properties' : $this.VersionCommand
            [string]$return = ''
            if ($versionCommand -match '^\"(.*)\"$'){
                $return = $Matches[1]
            }
            else {
                $this.CheckGradleInstall()
                [Object[]]$tempReturn = $tempReturn = Invoke-Expression -Command "$([BuildTypeGradle]::gradlew) $versionCommand --no-daemon --quiet --warning-mode=none --console=rich"
                #.\gradlew.bat $versionCommand --no-daemon --quiet --warning-mode=none --console=rich)
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
            $url = 'https://services.gradle.org/distributions/gradle-6.6-bin.zip'
            $file = Split-Path -Path "$url" -Leaf
            Invoke-WebRequest -Uri $url -OutFile $file
            Expand-Archive -Path $file -DestinationPath .
            .\gradle-6.6\bin\gradle.bat wrapper --no-daemon
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