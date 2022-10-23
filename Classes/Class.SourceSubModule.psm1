using module .\Class.BuildType.psm1
using module .\Class.Repo.psm1

###################
# Declare Classes #
###################
class SourceSubModule {
    [string]$Name
    [GitRepo]$Repo
    [BuildType[]]$Builds
    [string]$FinalName
    Init([string]$Name, [GitRepo]$Repo, [BuildType[]]$Builds, [string]$FinalName) {
        $this.Name = $Name
        $this.Repo = $Repo
        $this.Builds = $Builds
        $this.FinalName = $FinalName
    }
    SourceSubModule() {
<#
        [Collections.Generic.List[BuildType]]$tmpBuilds = [Collections.Generic.List[BuildType]]::new()
        if ($Value.Contains('IgnoreBranches')){
            foreach ($build in $Value.Builds) {
                $tmpBuilds.Add([string]::new([string]$branch))
            }
        }
#>
        $this.Init('', [GitRepo]::new(), [BuildType[]]@(), $null)
    }
    SourceSubModule ([string]$Name, [GitRepo]$Repo, [BuildType[]]$Builds, [string]$FinalName) {
        $this.Init($Name, $Repo, $Builds, $FinalName)
    }
    SourceSubModule ([string]$Name, [GitRepo]$Repo, [BuildType]$Build, [string]$FinalName) {
        $this.Init($Name, $Repo, [BuildType[]]@($Build), $FinalName)
    }
    SourceSubModule([Hashtable]$Value) {
        # Set the Name string
        [string]$tmpName = $Value.Contains('Name') ? [string]$Value.Name : $null

        # Create a GitRepo class
        [GitRepo]$tmpRepo = $Value.Contains('Repo') ? [GitRepo]::new($Value.Repo) : [GitRepo]::new()

        # Retrieve Final Name string
        [string]$tmpFinalName =  $Value.Contains('FinalName')       ? [string]$Value.FinalName          : $null

        if ($Value.Builds -is [hashtable]){
            # Complete constructor by executing the Init function
            $this.Init($tmpName, $tmpRepo, [BuildType[]]@($this.getNewBuild($Value.Builds)), $tmpFinalName)
        }
        else { #if ($Value.Builds -is [array]){
            [BuildType[]]$tmpBuilds=@()
            foreach ($build in $Value.Builds) {
                $tmpBuilds +=  $this.getNewBuild($build)
            }
            $this.Init($tmpName, $tmpRepo, $tmpBuilds, $tmpFinalName)
        }

    }
    [BuildType] hidden getNewBuild([Hashtable]$BuildValue){
        # Create a Build Type class or derived class
        [BuildType]$returnBuild = $null
        if ($BuildValue.Contains('Type')) {
            switch ($BuildValue.Type) {
                "Base"   { $returnBuild = [BuildType]::new($BuildValue);       break }
                "Java"   { $returnBuild = [BuildTypeJava]::new($BuildValue);   break }
                "Gradle" { $returnBuild = [BuildTypeGradle]::new($BuildValue); break }
                "Maven"  { $returnBuild = [BuildTypeMaven]::new($BuildValue);  break }
                "NPM"    { $returnBuild = [BuildTypeNPM]::new($BuildValue);    break }
                Default  { $returnBuild = [BuildType]::new($BuildValue)              }
            }
        }
        else {
            $returnBuild = [BuildType]::new($BuildValue)
        }
        return $returnBuild
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
        [string]$DirectoryRoot
    ){
        $this.DisplayHeader($DirectoryRoot, $false)
    }
    DisplayHeader(
        [string]$DirectoryRoot,
        [switch]$RelativePaths
    ){
        if ($RelativePaths) {
            Write-Host "$('=' * 120)`r`nName:      $($this.Name)`r`nDirectory: $($this.RelativePath($DirectoryRoot,(Get-Location)))`r`n$('=' * 120)" -ForegroundColor red
        }
        else {
            Write-Host "$('=' * 120)`r`nName:      $($this.Name)`r`nDirectory: $(Get-Location)`r`n$('=' * 120)" -ForegroundColor red
        }
    }
    InvokeClean(
        [string]$PathSource
    ){
        $dirCurrentSource = Join-Path -Path $PathSource -ChildPath $this.Name
        Write-Host "Cleaning $($this.GetFinalName())"
        Set-Location -Path $dirCurrentSource
        $this.Repo.InvokeClean()
    }
    [string[]]InvokeBuild (
            [hashtable]$Paths,
            [switch]$PerformCleanAndPull,
            [switch]$WhatIF
    ){
        [string[]]$updatedFiles = @()
        $dirCurrentSource = Join-Path -Path $Paths['Sources'] -ChildPath $this.Name

        Set-Location -Path $dirCurrentSource
        $this.DisplayHeader(($Paths['Root']))

        if ($PerformCleanAndPull) {
            $this.Repo.InvokeClean($true)
            $this.Repo.InvokePull($true)
        }

        $commit = ($this.Repo.GetCommit())

        foreach ($build in $this.Builds) {
            $build.InvokeInitBuild($WhatIF)

            $version = ($build.GetVersion())

            # Determine the copy to output file directory
            [string]$copyToFilePath = ''
            if ($build.OutputType -like 'Other') { $copyToFilePath = $dirCurrentSource }
            else {
                [string]$buildOutputType = $build.OutputType
                $copyToFilePath = $Paths.$buildOutputType
            }
            if ([string]::IsNullOrWhiteSpace($copyToFilePath)) { $copyToFilePath = $dirCurrentSource }

            # Determine the copy to output file name
            [string]$copyToFileName = ''
            if ( $build.OutputType -eq [OutputType]::Script ) {
                $copyToFileName = $build.GetOutputFileName()
            }
            else {
                $copyToFileName =  "$($this.GetFinalName())-$version-CUSTOM+$commit$($build.GetOutputExtension())"
            }
    
            # Determine the copy to full file name
            [string]$copyToFileFullName = Join-Path -Path $copyToFilePath -ChildPath $copyToFileName
    
            # Show current values before checking if a build is required
            $this.Repo.Display()
            Write-Console "$version" -Title 'Version'
            Write-Console "`"$($this.RelativePath($Paths['Server'], $(Join-Path -Path $dirCurrentSource -ChildPath $($build.GetOutput()))))`"" -Title 'Copy From'
            Write-Console "`"$($this.RelativePath($Paths['Server'], $copyToFileFullName))`"" -Title 'Copy To'
    
            if ($build.PerformBuild) {
                [string]$copyToExistingFilter = '^' + [System.Text.RegularExpressions.Regex]::Escape($copyToFileName) + '(\.disabled|\.backup)*$'
                $copyToExistingFiles = Get-ChildItem -File -Path $copyToFilePath | Where-Object { $_.Name -match $copyToExistingFilter }
    
                switch ($build.OutputType) {
                    Script {
                        [string]$copyFromFileName = Join-Path -Path $dirCurrentSource -ChildPath ($build.GetOutput())
                        if ($this.SafeCopy($copyFromFileName,$copyToFileFullName,$Paths['Server'],$WhatIF,$true)) { $updatedFiles += $copyToFileFullName }
                        break
                    }
                    Other {
                        $build.InvokePreBuild($WhatIF)
                        $build.InvokeBuild($WhatIF)
                        $build.InvokePostBuild($WhatIF)
                        break
                    }
                    Default {
                        if ($copyToExistingFiles.Count -eq 0) {
                            $build.InvokePreBuild($WhatIF)
                            $build.InvokeBuild($WhatIF)
                            $lastHour = (Get-Date).AddDays(-1)
                            $copyFromExistingFiles = Get-ChildItem -Path $(Join-Path -Path $dirCurrentSource -ChildPath $build.GetOutput()) -File -Exclude @('*-dev.jar','*-sources.jar','*-fatjavadoc.jar','*-noshade.jar','*-api.jar','*-javadoc.jar') -EA:0 | Where-Object {$_.CreationTime -ge $lastHour} | Sort-Object -Descending CreationTime | Select-Object -First 1
                            if ( $null -ne $copyFromExistingFiles -or $WhatIF ) {
                                $renameOldFileFilter = [System.Text.RegularExpressions.Regex]::Escape("$($this.GetFinalName())-") + '.*\-CUSTOM\+.*' + [System.Text.RegularExpressions.Regex]::Escape($build.GetOutputExtension()) + '$'
                                $renameOldFiles = Get-ChildItem -File -Path $copyToFilePath | Where-Object { $_.Name -match $renameOldFileFilter }
                                foreach ($renameOldFile in $renameOldFiles) {
                                    Write-Console "`"$($this.RelativePath($Paths['Server'], $renameOldFile.FullName))`" to `"$($this.RelativePath($Paths['Server'], $renameOldFile.FullName))^fE.disabled^fz`"" -Title 'Renaming'
                                    if ($WhatIF) { Write-Console "Rename-Item -Path `"$($this.RelativePath($Paths['Server'], $renameOldFile.FullName))`" -NewName `"$($this.RelativePath($Paths['Server'], $renameOldFile.FullName)).disabled`" -Force -EA:0" -Title 'WhatIF'}
                                    else { Rename-Item -Path "$($renameOldFile.FullName)" -NewName "$($renameOldFile.FullName).disabled" -Force -EA:0 }
                                }
                                [string]$copyFromFileFullName = ($WhatIF ? '<buildOutputFile>' : $copyFromExistingFiles.FullName)
                                if ($this.SafeCopy($copyFromFileFullName,$copyToFileFullName,$Paths['Server'],$WhatIF,$false)) { $updatedFiles += $copyToFileFullName }
                                $build.InvokePostBuild($WhatIF)
                            }
                            else { Write-Console "^frNo build output file `"$copyFromExistingFiles`" found." -Title 'Error' }
                        }
                        else { Write-Console "`"^fG$($this.RelativePath($Paths['Server'], ($copyToExistingFiles|Select-Object -First 1).FullName))^fz`" is already up to date." }
                    }
                }
            }
            else { Write-Console "^fMBuilding of this submodule is currently disabled.^fz" }
        }

        return $updatedFiles
    }
}