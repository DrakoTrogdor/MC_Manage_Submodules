using module .\Class.BuildType.psm1
using module .\Class.Repo.psm1

#################
# Declare Enums #
#################
enum SubModuleType {
    Other
    Server
    Script
    Plugin
    VelocityPlugin
    Module
    ServerModule
    ClientModule
    DataPack
    ResourcePack
    NodeDependancy
}

###################
# Declare Classes #
###################
class SourceSubModule {
    [string]$Name
    [SubModuleType]$SubModuleType
    [GitRepo]$Repo
    [BuildType]$Build
    [string]$FinalName
    Init([string]$Name, [SubModuleType]$SubModuleType, [GitRepo]$Repo, [BuildType]$Build, [string]$FinalName) {
        $this.Name = $Name
        $this.SubModuleType = $SubModuleType
        $this.Repo = $Repo
        $this.Build = $Build
        $this.FinalName = $FinalName
    }
    SourceSubModule() {
       $this.Init('', [SubModuleType]::Other, [GitRepo]::new(), [BuildType]::new(), $null)
    }
    SourceSubModule ([string]$Name, [SubModuleType]$SubModuleType, [GitRepo]$Repo, [BuildType]$Build, [string]$FinalName) {
        $this.Init($Name, $SubModuleType, $Repo, $Build, $FinalName)
    }
    SourceSubModule([Hashtable]$Value) {
        # Set the Name string
        [string]$tmpName = $Value.Contains('Name') ? [string]$Value.Name : $null

        # Set the Submodule Type enum
        [SubModuleType]$tmpSubModuleType = [SubModuleType]::Other
        if ($Value.Contains('SubmoduleType')){
            switch ($Value.SubmoduleType) {
                "Other"          { $tmpSubModuleType = [SubModuleType]::Other;          break }
                "Server"         { $tmpSubModuleType = [SubModuleType]::Server;         break }
                "Script"         { $tmpSubModuleType = [SubModuleType]::Script;         break }
                "Plugin"         { $tmpSubModuleType = [SubModuleType]::Plugin;         break }
                "VelocityPlugin" { $tmpSubModuleType = [SubModuleType]::VelocityPlugin; break }
                "Module"         { $tmpSubModuleType = [SubModuleType]::Module;         break }
                "ServerModule"   { $tmpSubModuleType = [SubModuleType]::ServerModule;   break }
                "ClientModule"   { $tmpSubModuleType = [SubModuleType]::ClientModule;   break }
                "DataPack"       { $tmpSubModuleType = [SubModuleType]::DataPack;       break }
                "ResourcePack"   { $tmpSubModuleType = [SubModuleType]::ResourcePack;   break }
                "NodeDependancy" { $tmpSubModuleType = [SubModuleType]::NodeDependancy; break }
                default          { $tmpSubModuleType = [SubModuleType]::Other                 }
            }
        }

        # Create a GitRepo class
        [GitRepo]$tmpRepo = $Value.Contains('Repo') ? [GitRepo]::new($Value.Repo) : [GitRepo]::new()

        # Create a Build Type class or derived class
        [BuildType]$tmpBuild = $null
        if ($Value.Build.Contains('Type')) {
            switch ($Value.Build.Type) {
                "Base"   { $tmpBuild = [BuildType]::new($Value.Build);       break }
                "Java"   { $tmpBuild = [BuildTypeJava]::new($Value.Build);   break }
                "Gradle" { $tmpBuild = [BuildTypeGradle]::new($Value.Build); break }
                "Maven"  { $tmpBuild = [BuildTypeMaven]::new($Value.Build);  break }
                "NPM"    { $tmpBuild = [BuildTypeNPM]::new($Value.Build);    break }
                Default  { $tmpBuild = [BuildType]::new($Value.Build)              }
            }
        }
        else {
            $tmpBuild = [BuildType]::new($Value.Build)
        }

        # Retrieve Final Name string
        [string]$tmpFinalName =  $Value.Contains('FinalName')       ? [string]$Value.FinalName          : $null

        # Complete constructor by executing the Init function
        $this.Init($tmpName, $tmpSubModuleType, $tmpRepo, $tmpBuild, $tmpFinalName)
    }
    [string]GetFinalName() {
        if ([string]::IsNullOrWhiteSpace($this.FinalName)){ return $this.Name }
        else { return $this.FinalName }
    }
    [string] hidden RelativePath([string]$Parent,[string]$Child){
        if([string]::IsNullOrWhiteSpace($Parent) -or [string]::IsNullOrWhiteSpace($Child)) { return ''}
        else {
            [string]$return = '.' + ($Child -replace [RegEx]::Escape($Parent),'')
            return $return
        }
    }
    [System.Boolean] hidden SafeCopy([string]$Source,[string]$Destination,[string]$Root,[switch]$WhatIF,[switch]$Compare){
        if ([string]::IsNullOrWhiteSpace($Source)){
            Write-Console "Source file is empty."
            return $false
        }
        if ([string]::IsNullOrWhiteSpace($Destination)) {
            Write-Console "Destination file is empty."
            return $false
        }
        [string]$relativeSource = $this.RelativePath($Root, $Source)
        [string]$relativeDestination = $this.RelativePath($Root, $Destination)
        if ($Compare -and ($null -eq (Compare-Object -ReferenceObject (Get-Content -Path $Source) -DifferenceObject (Get-Content -Path $Destination)))) {
            Write-Console "`"^fG$relativeSource^fz`" and `"^fG$relativeDestination^fz`" are identical."
            return $false
        }
        else {
            Write-Console "`"$relativeSource`" to `"$relativeDestination`"..." -Title 'Copying'
            try {
                if ($WhatIF) { Write-Console "Copy-Item -Path $relativeSource -Destination $relativeDestination -Force" -Title 'WhatIF'}
                else { Copy-Item -Path $Source -Destination $Destination -Force }
                Write-Console "`"^fg$relativeSource^fz`" to `"^fg$relativeDestination^fz`"." -Title "Copied"
                return $true
            }
            catch {
                Write-Console "^frCopying file `"$relativeSource`" to `"$relativeDestination`".^fz" -Title 'Error'
                return $false
            }
        }
    }
    DisplayHeader(
        [string]$DirectoryRoot #$script:dirRoot
    ){
        Write-Host "$('=' * 120)`r`nName:      $($this.Name)`r`nDirectory: $($this.RelativePath($DirectoryRoot,(Get-Location)))`r`n$('=' * 120)" -ForegroundColor red
    }
    InvokeClean(
        [string]$PathSource
    ){
        $dirCurrentSource = Join-Path -Path $PathSource -ChildPath $this.Name
        Write-Host "Cleaning $($this.GetFinalName())"
        Set-Location -Path $dirCurrentSource
        $this.Repo.InvokeClean()
    }
    [string]InvokeBuild (
            [string]$PathRoot,
            [string]$PathSource,
            [string]$PathServer,
            [string]$PathScript,
            [string]$PathPlugin,
            [string]$PathVelocityPlugin,
            [string]$PathModule,
            [string]$PathServerModule,
            [string]$PathClientModule,
            [string]$PathDataPack,
            [string]$PathResourcePack,
            [string]$PathNodeDependancy,
            [switch]$PerformCleanAndPull,
            [switch]$WhatIF
    ){
        [string]$updatedFile = $null
        $dirCurrentSource = Join-Path -Path $PathSource -ChildPath $this.Name

        Set-Location -Path $dirCurrentSource
        $this.DisplayHeader($PathRoot)

        if ($PerformCleanAndPull) {
            $this.Repo.InvokeClean($true)
            $this.Repo.InvokePull($true)
        }

        $this.Build.InvokeInitBuild($WhatIF)

        $commit = ($this.Repo.GetCommit())
        $version = ($this.Build.GetVersion())

        # Determine the copy to output file directory
        [string]$copyToFilePath = ''
        switch ($this.SubModuleType) {
            Other           { $copyToFilePath = $dirCurrentSource;      break; }
            Server          { $copyToFilePath = $PathServer;            break; }
            Script          { $copyToFilePath = $PathScript;            break; }
            Plugin          { $copyToFilePath = $PathPlugin;            break; }
            VelocityPlugin  { $copyToFilePath = $PathVelocityPlugin;    break; }
            Module          { $copyToFilePath = $PathModule;            break; }
            ServerModule    { $copyToFilePath = $PathServerModule;      break; }
            ClientModule    { $copyToFilePath = $PathClientModule;      break; }
            DataPack        { $copyToFilePath = $PathDataPack;          break; }
            ResourcePack    { $copyToFilePath = $PathResourcePack;      break; }
            NodeDependancy  { $copyToFilePath = $PathNodeDependancy;    break; }
        }

        # Determine the copy to output file name
        [string]$copyToFileName = ''
        if ( $this.SubModuleType -eq [SubModuleType]::Script ) {
            $copyToFileName = $this.Build.GetOutputFileName()
        }
        else {
            $copyToFileName =  "$($this.GetFinalName())-$version-CUSTOM+$commit$($this.Build.GetOutputExtension())"
        }

        # Determine the copy to full file name
        [string]$copyToFileFullName = Join-Path -Path $copyToFilePath -ChildPath $copyToFileName

        # Show current values before checking if a build is required
        $this.Repo.Display()
        Write-Console "$version" -Title 'Version'
        Write-Console "`"$($this.RelativePath($PathServer, $(Join-Path -Path $dirCurrentSource -ChildPath $($this.Build.GetOutput()))))`"" -Title 'Copy From'
        Write-Console "`"$($this.RelativePath($PathServer, $copyToFileFullName))`"" -Title 'Copy To'

        if ($this.Build.PerformBuild) {
            [string]$copyToExistingFilter = '^' + [System.Text.RegularExpressions.Regex]::Escape($copyToFileName) + '(\.disabled|\.backup)*$'
            $copyToExistingFiles = Get-ChildItem -File -Path $copyToFilePath | Where-Object { $_.Name -match $copyToExistingFilter }

            switch ($this.SubModuleType) {
                Script {
                    [string]$copyFromFileName = Join-Path -Path $dirCurrentSource -ChildPath ($this.Build.GetOutput())
                    if ($this.SafeCopy($copyFromFileName,$copyToFileFullName,$PathServer,$WhatIF,$true)) { $updatedFile = $copyToFileFullName }
                    break
                }
                Other {
                    $this.Build.InvokePreBuild($WhatIF)
                    $this.Build.InvokeBuild($WhatIF)
                    $this.Build.InvokePostBuild($WhatIF)
                    break
                }
                Default {
                    if ($copyToExistingFiles.Count -eq 0) {
                        $this.Build.InvokePreBuild($WhatIF)
                        $this.Build.InvokeBuild($WhatIF)
                        $lastHour = (Get-Date).AddDays(-1)
                        $copyFromExistingFiles = Get-ChildItem -Path $(Join-Path -Path $dirCurrentSource -ChildPath $this.Build.GetOutput()) -File -Exclude @('*-dev.jar','*-sources.jar','*-fatjavadoc.jar','*-noshade.jar','*-api.jar') -EA:0 | Where-Object {$_.CreationTime -ge $lastHour} | Sort-Object -Descending CreationTime | Select-Object -First 1
                        if ( $null -ne $copyFromExistingFiles -or $WhatIF ) {
                            $renameOldFileFilter = [System.Text.RegularExpressions.Regex]::Escape("$($this.GetFinalName())-") + '.*\-CUSTOM\+.*' + [System.Text.RegularExpressions.Regex]::Escape($this.Build.GetOutputExtension()) + '$'
                            $renameOldFiles = Get-ChildItem -File -Path $copyToFilePath | Where-Object { $_.Name -match $renameOldFileFilter }
                            foreach ($renameOldFile in $renameOldFiles) {
                                Write-Console "`"$($this.RelativePath($PathServer, $renameOldFile.FullName))`" to `"$($this.RelativePath($PathServer, $renameOldFile.FullName))^fE.disabled^fz`"" -Title 'Renaming'
                                if ($WhatIF) { Write-Console "Rename-Item -Path `"$($this.RelativePath($PathServer, $renameOldFile.FullName))`" -NewName `"$($this.RelativePath($PathServer, $renameOldFile.FullName)).disabled`" -Force -EA:0" -Title 'WhatIF'}
                                else { Rename-Item -Path "$($renameOldFile.FullName)" -NewName "$($renameOldFile.FullName).disabled" -Force -EA:0 }
                            }
                            [string]$copyFromFileFullName = ($WhatIF ? '<buildOutputFile>' : $copyFromExistingFiles.FullName)
                            if ($this.SafeCopy($copyFromFileFullName,$copyToFileFullName,$PathServer,$WhatIF,$false)) { $updatedFile = $copyToFileFullName }
                            $this.Build.InvokePostBuild($WhatIF)
                        }
                        else { Write-Console "^frNo build output file `"$copyFromExistingFiles`" found." -Title 'Error' }
                    }
                    else { Write-Console "`"^fG$($this.RelativePath($PathServer, ($copyToExistingFiles|Select-Object -First 1).FullName))^fz`" is already up to date." }
                }
            }
        }
        else { Write-Console "^fMBuilding of this submodule is currently disabled.^fz" }
        return $updatedFile
    }
}