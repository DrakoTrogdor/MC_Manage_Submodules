#########################
# Declare Class GitRepo #
#########################
class GitRepo {
	[string]$Name
	[string]$Origin
	[string]$Branch
	[System.Boolean]$Pull
    [GitRepo[]]$SubModules
    [string[]]$ArchiveAdditions
    [string[]]$CleanAdditions
    [string[]]$CleanExceptions
    [void] hidden Init (
        [string]$Name,
        [string]$Origin,
        [string]$Branch,
        [System.Boolean]$Pull,
        [GitRepo[]]$SubModules,
        [string[]]$ArchiveAdditions,
        [string[]]$CleanAdditions,
        [string[]]$CleanExceptions
    ){
        if ([string]::IsNullOrWhiteSpace($Name) -and -not [string]::IsNullOrWhiteSpace($Origin)) {
            $this.Name = (Split-Path -Path $Origin -Leaf) -replace '^(.*)\.git$', '$1'
            $this.Origin = $Origin
        }
        elseif ([string]::IsNullOrWhiteSpace($Origin) -and -not [string]::IsNullOrWhiteSpace($Name)) {
            $this.Name = $Name
            $this.Origin = "$($script:myGit_URL)/$Name" }
        else {
            $this.Name = $Name
            $this.Origin = $Origin
        }
        if([string]::IsNullOrWhiteSpace($Branch)){ $this.Branch = 'master' }
        else { $this.Branch = $Branch }
        if ($null -eq $Pull) { $this.Pull = $true }
        else { $this.Pull = $Pull }
        if ($null -eq $SubModules) { $this.SubModules = [GitRepo[]]@() }
        else { $this.SubModules = $SubModules }
        if ($null -eq $ArchiveAdditions) { $this.ArchiveAdditions = [string[]]@() }
        else { $this.ArchiveAdditions = $ArchiveAdditions }
        if ($null -eq $CleanAdditions) { $this.CleanAdditions = [string[]]@() }
        else { $this.CleanAdditions = $CleanAdditions }
        if ($null -eq $CleanExceptions) { $this.CleanExceptions = [string[]]@() }
        else { $this.CleanExceptions = $CleanExceptions }
    }
    GitRepo() { $this.init($null, $null,   'master', $true, [GitRepo[]]@()), [string[]]@() }
    GitRepo(
        [string]$Name,
        [string]$Origin,
        [string]$Branch,
        [System.Boolean]$Pull,
        [GitRepo[]]$SubModules,
        [string[]]$ArchiveAdditions,
        [string[]]$CleanAdditions,
        [string[]]$CleanExceptions
    ) {
        $this.Init($Name, $Origin, $Branch,  $Pull, $SubModules, $ArchiveAdditions, $CleanAdditions, $CleanExceptions)
    }
    GitRepo([Hashtable]$Value) {
        $tmpName        = $Value.Contains('Name')       ? [string]$Value.Name          : $null
        $tmpOrigin      = $Value.Contains('Origin')     ? [string]$Value.Origin        : $null
        $tmpBranch      = $Value.Contains('Branch')     ? [string]$Value.Branch        : 'master'
        $tmpPull        = $Value.Contains('Pull')       ? [System.Boolean]$Value.Pull  : $true
        $tmpSubModules =  [GitRepo[]]@()
        if ($Value.Contains('SubModules')){
            foreach ($submodule in $Value.SubModules){
                $tmpSubModules += [GitRepo]::new([Hashtable]$submodule)
            }
            
        }
        $tmpArchiveAdditions = [string[]]@()
        if ($Value.Contains('ArchiveAdditions')){
            foreach ($item in $Value.ArchiveAdditions){
                $tmpArchiveAdditions += [string]$item
            }
            
        }
        $tmpCleanAdditions = [string[]]@()
        if ($Value.Contains('CleanAdditions')){
            foreach ($item in $Value.CleanAdditions){
                $tmpCleanAdditions += [string]$item
            }
            
        }
        $tmpCleanExceptions = [string[]]@()
        if ($Value.Contains('CleanExceptions')){
            foreach ($item in $Value.CleanExceptions){
                $tmpCleanExceptions += [string]$item
            }
            
        }
        $this.Init($tmpName, $tmpOrigin, $tmpBranch,  $tmpPull, $tmpSubModules, $tmpArchiveAdditions, $tmpCleanAdditions, $tmpCleanExceptions)
    }
    [string]GetUpstream() {
        [string]$return = (git rev-parse --abbrev-ref --symbolic-full-name '@{upstream}')
        return $return
    }
    [string]GetRemote() {
        [string]$return = $this.GetUpstream() -replace '/.*$',''
        return $return
    }
    [string]GetURL() {
        [string]$return = (git config --get remote.$($this.GetRemote()).url)
        return $return
    }
    [string]GetBranch() {
        [string[]]$Value = (git branch)
        [string]$return = ( $Value | Select-String -Pattern '(^\* (?''match''.*)$)' | Select-Object -First 1 | ForEach-Object {
            $_.matches.groups | Where-Object {
                $_.Name -match 'match'
            }
        } | Select-Object -Expand Value )
        return $return

        return $return
    }
    [string]GetCommit(){
        [string]$return = (git rev-parse --short=7 HEAD)
        return $return
    }
    [string]CheckConfigRemote([System.Boolean]$InColor){
        [string]$reportedRemote = $this.GetRemote()
        if ($reportedRemote -like 'origin') { $reportedRemote += " ($($InColor ? '^fgSame^fz' : 'Same'))" } else { $reportedRemote += " (" + ($InColor ? "^frChanged from `"origin`"^fz" : "Changed from `"origin`"") + ")" }
        return $reportedRemote
    }
    [string]CheckConfigRemote() { return CheckConfigURL($false) }
    [string]CheckConfigURL([System.Boolean]$InColor){
        [string]$reportedURL = $this.GetURL()
        if ($reportedURL -like $this.Origin) { $reportedURL += " ($($InColor ? '^fgSame^fz' : 'Same'))" } else { $reportedURL += " (" + ($InColor ? "^frChanged from `"" + $this.Origin + "`"^fz" : "Changed from `"" + $this.Origin + "`"") + ")" }
        return $reportedURL
    }
    [string]CheckConfigURL() { return CheckConfigURL($false) }

    [string]CheckConfigBranch([System.Boolean]$InColor){
        [string]$reportedBranch = $this.GetBranch()
        if ($reportedBranch -like $this.Branch) { $reportedBranch += " ($($InColor ? '^fgSame^fz' : 'Same'))" } else { $reportedBranch += " (" + ($InColor ? "^frChanged from `"" + $this.Branch + "`"^fz" : "Changed from `"" + $this.Branch + "`"") + ")" } #" (Same)" } else { $reportedBranch += " (Changed from `"$($this.Branch)`")" }
        return $reportedBranch
    }
    [string]CheckConfigBranch() { return CheckConfigBranch($false) }

    [void]Display([System.Boolean]$ShowName){
        if ($ShowName) { Write-Color "^fM$($this.Name)^fz" }
        Write-Log "$($this.CheckConfigRemote($true))" -Title 'Remote'
        Write-Log "$($this.CheckConfigURL($true))" -Title 'URL'
        Write-Log "$($this.CheckConfigBranch($true))" -Title 'Branch'
        Write-Log "$($this.GetCommit())" -Title 'Commit'
    }
    [void]Display(){ $this.Display($true) }
    [void]InvokeCheckout() {
        Write-Host "(before)"
        $this.Display()
        git checkout -B $($this.Branch) --force
        git branch --set-upstream-to=$($this.GetRemote())/$($this.Branch) $($this.Branch)
        git fetch --force $($this.GetRemote())
        Write-Host "(after)"
        $this.Display()
        Write-Host ''
    }
    [void]InvokeReset() {
        $this.Display()
        [string]$upstream = $this.GetUpstream()
        if ($script:WhatIF) { Write-Log "git reset --hard $upstream --recurse-submodules" -Title 'WhatIF' }
        else { git reset --hard "$upstream" --recurse-submodules }
        Write-Host ''
    }
    [void]InvokeClean([System.Boolean]$Quiet) {
        if ($Quiet) { Write-Log -Value "Cleaning..." -Title "Action" } else { $this.Display() }
        [string[]]$cleanArguments = @('clean')
        $cleanArguments += ($script:WhatIF ? '-nxfd' : '-xfd')
        foreach ($item in $this.CleanExceptions) {
            $cleanArguments += @('-e',$([string]$item))
        }
        git @cleanArguments
        foreach ($item in $this.CleanAdditions) {
            Remove-Item $item -Force -Recurse -WhatIf:$($script:WhatIF)
        }
    }
    [void]InvokeClean() { $this.InvokeClean($false) }
    [void]InvokePull([System.Boolean]$Quiet) {
        if ($this.Pull) {
            if ($Quiet) { Write-Log -Value "Pulling..." -Title "Action" } else { $this.Display() }
            if ($script:WhatIF -and -not $script:ForcePull) { Write-Log "git pull" -Title 'WhatIF' }
            else {
                [string]$tmpBranch = $null
                try { $tmpBranch = git symbolic-ref HEAD }
                catch { Write-Log "^fr$($_.Exception.Message)^fz" -Title 'Error' }
                if ([string]::IsNullOrWhiteSpace($tmpBranch)) {
                    $this.InvokeCheckout()
                }
                git pull
            }
        }
    }
    [void]InvokePull() { $this.InvokePull($false) }
}

###############################
# Declare Class GitRepoForked #
###############################
class GitRepoForked : GITRepo {
	[string]$Upstream
	GITRepoForked() : base() {}
    GITRepoForked([string]$Name, [string]$Origin, [string]$Branch, [System.Boolean]$Pull, [string]$Upstream, [GitRepo[]]$SubModules) : base($Name, $Origin, $Branch, $Pull, $SubModules) { $this.Upstream = $Upstream }
    GITRepoForked([Hashtable]$Value) : base ($Value) { $this.Upstream ? $Value.Contains('Upstream') : $Value.Upstream }
}