############################
# Declare Class RemoteRepo #
############################
class BranchDetails : System.IEquatable[Object] {
    [string]$Branch
    [string]$Commit
    [DateTime]$Time
    [string]$Comment
    BranchDetails([string]$Branch,[string]$Commit,[string]$Time) { $this.Branch = $Branch; $this.Commit = $Commit; $this.Time = ConvertFrom-UnixTime $($Time.Trim()) }
    [bool]Equals($Object) {
        if (-not $Object -is [BranchDetails]) { return $false }
        elseif ($this.Branch -like $Object.Branch -and $this.Commit -like $Object.Commit) { return $true }
        else { return $false }
    }
}
class RemoteRepo {
    [string]$Name
    [string]$URL
    [string]$DefaultBranch
    [BranchDetails[]]$Branches
    [bool]$Detatched
    [string[]]$IgnoreBranches
    [void] hidden Init ([string]$Name, [string]$URL, [string]$DefaultBranch, [bool]$Detatched, [string[]]$IgnoreBranches) {
        $this.Name           = [string]::IsNullOrWhiteSpace($Name)          ? 'origin'      : $Name
        $this.URL            = [string]::IsNullOrWhiteSpace($URL)           ? ''            : $URL
        $this.DefaultBranch  = [string]::IsNullOrWhiteSpace($DefaultBranch) ? 'master'      : $DefaultBranch
        $this.Detatched      = $null -eq $Detatched                         ? $false        : $Detatched
        $this.IgnoreBranches = $null -eq $IgnoreBranches                    ? [string[]]@() : $IgnoreBranches
    }
    RemoteRepo() { $this.Init($null, $null, $null, $false, $null) }
    RemoteRepo([string]$Name, [string]$URL, [string]$DefaultBranch, [bool]$Detatched, [string[]]$IgnoreBranches) { $this.Init($Name, $URL, $DefaultBranch, $Detatched, $IgnoreBranches) }
    RemoteRepo([Hashtable]$Value) {
        [string]$tmpName          = $Value.Contains('Name')                 ? [string]$Value.Name          : $null
        [string]$tmpURL           = $Value.Contains('URL')                  ? [string]$Value.URL           : $null
        [string]$tmpDefaultBranch = $Value.Contains('DefaultBranch')        ? [string]$Value.DefaultBranch : $null
        [bool]$tmpDetatched       = $Value.Contains('Detatched')            ? [string]$Value.Detatched     : $false
        [Collections.Generic.List[string]]$tmpIgnoreBranches = [Collections.Generic.List[string]]::new()
        if ($Value.Contains('IgnoreBranches')){
            foreach ($branch in $Value.IgnoreBranches) {
                $tmpIgnoreBranches.Add([string]::new([string]$branch))
            }
        }
        $this.Init($tmpName, $tmpURL, $tmpDefaultBranch, $tmpDetatched, $tmpIgnoreBranches.ToArray())
    }
    [void]InitializeBranches() {
        [System.Collections.Generic.List[BranchDetails]]$tmpBranches = [System.Collections.Generic.List[BranchDetails]]::new()
        if ($this.Name -eq 'HEAD' -or $this.Name -eq 'DETATCHED') {
            if (((git rev-list HEAD -n 1 --date=unix --abbrev-commit --pretty=format:"%cd") -join "`r`n") -match '(?ms)(?:^commit (?<commit>[a-f0-9]+)\s*(?:(?<time>\d+))$)' ) {
                $tmpBranches.Add([BranchDetails]::new($this.Name, $Matches.commit, $Matches.time))
            }
            else { $tmpBranches.Add([BranchDetails]::new($this.Name, '', '')) }
        }
        else {
            [string]$branchIgnoreRegex = '.*(' + (($this.IgnoreBranches.Where({$_ -notmatch '^\s*$'}).ForEach({$_.Trim()})) -join '|') +').*'
            if ($branchIgnoreRegex -eq '.*().*') { $branchIgnoreRegex = '^$' }
            [string[]]$lsRemoteHeads = git ls-remote --heads $this.Name
            foreach ($item in $lsRemoteHeads) {
                if ($item -match '^(?<commit>[a-fA-F0-9]+)\h+refs/heads/(?<branch>.*)$') {
                    [string]$tmpBranch = $Matches.branch
                    [string]$tmpCommit = $Matches.commit
                    if ($tmpBranch -notmatch $branchIgnoreRegex) {
                        if (((git rev-list $tmpCommit -n 1 --date=unix --abbrev-commit --pretty=format:"%cd") -join "`r`n") -match '(?ms)(?:^commit (?<commit>[a-f0-9]+)\s*(?:(?<time>\d+))$)' ) {
                            $tmpBranches.Add([BranchDetails]::new($tmpBranch, $tmpCommit, $Matches.time))
                        }
                        else { $tmpBranches.Add([BranchDetails]::new($tmpBranch, $tmpCommit, '')) }
                    }
                }
            }
        }
        $this.Branches = $tmpBranches.ToArray()
    }
}
#########################
# Declare Class GitRepo #
#########################
class GitRepo {
    [string]$Name
    [RemoteRepo[]]$RemoteRepos
    [string]$LockAtCommit
    [bool]$Pull
    [GitRepo[]]$SubModules
    [string[]]$ArchiveAdditions
    [string[]]$CleanAdditions
    [string[]]$CleanExceptions
    [void] hidden Init (
        [string]$Name,
        [RemoteRepo[]]$RemoteRepos,
        [string]$LockAtCommit,
        [bool]$Pull,
        [GitRepo[]]$SubModules,
        [string[]]$ArchiveAdditions,
        [string[]]$CleanAdditions,
        [string[]]$CleanExceptions
    ){
        $this.Name             = [string]::IsNullOrWhiteSpace($Name)         ? ''                : $Name
        $this.RemoteRepos      = $null -ne $RemoteRepos                      ? [RemoteRepo[]]@() : $RemoteRepos
        $this.LockAtCommit     = [string]::IsNullOrWhiteSpace($LockAtCommit) ? $null             : $LockAtCommit
        $this.Pull             = $null -eq $Pull                             ? $true             : $Pull
        $this.SubModules       = $null -eq $SubModules                       ? [GitRepo[]]@()    : $SubModules
        $this.ArchiveAdditions = $null -eq $ArchiveAdditions                 ? [string[]]@()     : $ArchiveAdditions
        $this.CleanAdditions   = $null -eq $CleanAdditions                   ? [string[]]@()     : $CleanAdditions
        $this.CleanExceptions  = $null -eq $CleanExceptions                  ? [string[]]@()     : $CleanExceptions
    }
    GitRepo() { $this.init($null, [RemoteRepo[]]@(), $null, $true, [GitRepo[]]@()), [string[]]@(), [string[]]@(), [string[]]@() }
    GitRepo([Hashtable]$Value) {
        $tmpName                                             = $Value.Contains('Name')                       ? [string]$Value.Name          : $null
        [bool]$tmpPull                                       = $Value.Contains('Pull')                       ? [bool]$Value.Pull  : $true
        [string]$tmpLockAtCommit                             = $Value.Contains('LockAtCommit')               ? [string]$Value.LockAtCommit  : $null
        [Collections.Generic.List[RemoteRepo]]$tmpRemoteRepo = [Collections.Generic.List[RemoteRepo]]::new()
        if ($Value.Contains('Remotes')){
            foreach ($remote in $Value.RemoteRepos) {
                $tmpRemoteRepo.Add([RemoteRepo]::new([Hashtable]$remote))
            }
        }
        [Collections.Generic.List[GitRepo]]$tmpSubModules    = [Collections.Generic.List[GitRepo]]::new()
        if ($Value.Contains('SubModules')){
            foreach ($submodule in $Value.SubModules) {
                $tmpSubModules.Add([GitRepo]::new([Hashtable]$submodule))
            }
        }
        [Collections.Generic.List[string]]$tmpArchiveAdditions = [Collections.Generic.List[string]]::new()
        if ($Value.Contains('ArchiveAdditions')) {
            foreach ($item in $Value.ArchiveAdditions){
                $tmpArchiveAdditions.Add([string]$item)
            }
        }
        [Collections.Generic.List[string]]$tmpCleanAdditions = [Collections.Generic.List[string]]::new()
        if ($Value.Contains('CleanAdditions')) {
            foreach ($item in $Value.CleanAdditions) {
                $tmpCleanAdditions.Add([string]$item)
            }
        }
        [Collections.Generic.List[string]]$tmpCleanExceptions = [Collections.Generic.List[string]]::new()
        if ($Value.Contains('CleanExceptions')) {
            foreach ($item in $Value.CleanExceptions) {
                $tmpCleanExceptions.Add([string]$item)
            }
        }
        $this.Init($tmpName, $tmpRemoteRepo.ToArray(), $tmpLockAtCommit, $tmpPull, $tmpSubModules.ToArray(), $tmpArchiveAdditions.ToArray(), $tmpCleanAdditions.ToArray(), $tmpCleanExceptions.ToArray())
    }
    [bool]IsLockedAtCommit() { return -not [string]::IsNullOrWhiteSpace($this.LockAtCommit) }

    # (git rev-parse --short=7 refs/remotes/$Remote/$Branch)
    # (git rev-parse --short=7 refs/heads/$Branch)
    [RemoteRepo]GetConfiguredOrigin() { [RemoteRepo]$return = $this.RemoteRepos.Origin; $return.InitializeBranches(); return $return }
    [RemoteRepo]GetConfiguredUpstream() { [RemoteRepo]$return = $this.RemoteRepos.Upstream; $return.InitializeBranches(); return $return }
    [RemoteRepo[]]GetConfiguredOthers() {
        [System.Collections.Generic.List[RemoteRepo]]$return = [System.Collections.Generic.List[RemoteRepo]]::new()
        foreach ($repo in $this.RemoteRepos) {
            if ($repo -isnot $this.RemoteRepos.Origin -and $repo -isnot $this.RemoteRepos.Upstream) {
                $repo.InitializeBranches()
                $return.Add($repo)
            }
        }
        return $return.ToArray()
    }
    [RemoteRepo]GetConfiguredByName([string]$Name) { [RemoteRepo]$return = $this.RemoteRepos.$Name; $return.InitializeBranches(); return $return }
    [RemoteRepo]GetLocalHead() { 
        [RemoteRepo]$return = [RemoteRepo]::new()
        # Set the Name
        $return.Name = 'HEAD'

        # Set the Default Branch
        $return.DefaultBranch = (git branch --show-current)
        if ([string]::IsNullOrEmpty($return.DefaultBranch)) {
            $return.DefaultBranch = "DETATCHED - $($return.Commit)"
            $return.Detatched = $true
        }
        else {
            $return.Detatched = $false
        }

        # Set the URL
        if ($return.Detatched) {
            $return.URL = $this.GetURL($this.RemoteRepo.Origin.Name)
        }
        else {
            [string]$symbolicFullName = (git rev-parse --abbrev-ref --symbolic-full-name HEAD)
            [string]$branchRemote = (git config --get branch.$($symbolicFullName).remote)
            $return.URL = $this.GetURL($branchRemote)
        }

        $return.InitializeBranches()
        return $return
    }
    [RemoteRepo]GetLocalUpstream() { 
        [RemoteRepo]$return = [RemoteRepo]::new()
        # Set the Name
        [string]$symbolicFullName = (git rev-parse --abbrev-ref --symbolic-full-name '@{upstream}') 2>&1 # @{upstream} is short for HEAD@{upstream}
        if ($symbolicFullName -like 'fatal: * does not point to a branch') {
            $return.Name = 'DETATCHED'
            $return.Detatched = $true
        }
        else {
            $return.Name = $symbolicFullName -replace '/.*$',''
            $return.Detatched = $false
        }

        # Set the Default Branch
        if ($return.Detatched) { $return.DefaultBranch = "DETATCHED - $($return.Commit)"}
        else                   { $return.DefaultBranch = $symbolicFullName -replace '^[^/]*/',''}

        # Set the URL
        $return.URL = $this.GetURL($this.RemoteRepo.Origin.Name)
        $return.URL = $this.GetURL($return.Name)

        $return.InitializeBranches()
        return $return
    }
    [RemoteRepo[]]GetLocalOthers() {
        [System.Collections.Generic.List[RemoteRepo]]$return = [System.Collections.Generic.List[RemoteRepo]]::new()
        [string]$headBranch = (git rev-parse --symbolic-full-name HEAD)
        [string[]]$remotes = (git remote)
        foreach ($remote in $remotes) {
            $remote = $remote.Trim()
            [string]$tmpThisBranch = (git config --get branch.$remote.merge)
            if ($tmpThisBranch -ne $headBranch) {
                [RemoteRepo]$repo = [RemoteRepo]::new()
                git fetch $remote
                $repo.Name = $remote
                $repo.URL = $this.GetURL($remote)
                $repo.DefaultBranch = $tmpThisBranch -replace 'refs/heads/',''
                $repo.InitializeBranches()
                $return.Add($repo)
            }
        }
        return $return.ToArray()
    }
    [RemoteRepo]GetLocalByName([string]$Name) {
        [RemoteRepo]$return = [RemoteRepo]::new()
        $return.Name = (git config --get branch.$Name.remote)
        $return.URL = $this.GetURL($return.Name)
        $return.DefaultBranch = (git config --get branch.$($return.Name).merge) -replace 'refs/heads/',''
        return $return
    }
    [string]GetURL([string]$RemoteName) { return [string](git config --get remote.$RemoteName.url) }
    [string]CheckConfigRemote(){
        [RemoteRepo]$localRepo = $this.GetLocal()
        [RemoteRepo]$defaultRepo = $this.GetOrigin()
        return $localRepo.Name + ($localRepo.Name -like $defaultRepo.Name ?  " (^fgSame^fz)" : " (^frChanged from `"" + $defaultRepo.Name + "`"^fz)")
    }
    [string]CheckConfigURL(){
        [RemoteRepo]$localRepo = $this.GetLocal()
        [RemoteRepo]$defaultRepo = $this.GetOrigin()
        return $localRepo.URL + ($localRepo.URL -like $defaultRepo.URL ? " (^fgSame^fz)" : " (^frChanged from `"" + $defaultRepo.URL + "`"^fz)")
    }
    [string]CheckConfigBranch(){
        [RemoteRepo]$localRepo = $this.GetLocal()
        [RemoteRepo]$defaultRepo = $this.GetOrigin()
        return $localRepo.Branch + ($localRepo.Branch -like $defaultRepo.Branch ? " (^fgSame^fz)" : " (^frChanged from `"" + $defaultRepo.Branch + "`"^fz)")
    }
    [void]CompareAheadBehind() {
        # Invoke a checkout (will checkout the commit if locked at commit)
        $this.InvokeCheckout()

        [System.Collections.Generic.List[BranchDetails]]$branches = [System.Collections.Generic.List[BranchDetails]]::new()
        [BranchDetails]$localHead = $null
        [BranchDetails]$remoteOrigin = $null


        # Get the current branches and commits

        ## Local HEAD
        [RemoteRepo]$currentRepo = $this.GetLocalHead()
        foreach ($branch in [BranchDetails[]]$currentRepo.Branches) {
            if ($currentRepo.Detatched -or $this.IsLockedAtCommit) { $branch.Branch = $branch.Commit }
            else { $branch.Branch = "refs/heads/$($branch.Branch)" }
            if ($null -eq $localHead) { $localHead = $branch }
            $branches.Add($branch)
        }

        ## Configured Origin
        $currentRepo = $this.GetConfiguredOrigin()
        foreach ($branch in [BranchDetails[]]$currentRepo.Branches) {
            $branch.Branch = "refs/remotes/$($currentRepo.Name)/$($branch.Branch)"
            if ($null -eq $remoteOrigin) { $remoteOrigin = $branch }
            $branches.Add($branch)
        }

        ## Local Upstream (Origin)
        $currentRepo = $this.GetLocalUpstream()
        foreach ($branch in [BranchDetails[]]$currentRepo.Branches) {
            $branch.Branch = "refs/remotes/$($currentRepo.Name)/$($branch.Branch)"
            if ($branch -ne $remoteOrigin) {
                $branch.Comment = "Changed from $($remoteOrigin.Branch)"
                $branches.Add($branch)
            }
        }

        ## Local Remote Upstream
        $currentRepo = $this.GetConfiguredUpstream()
        foreach ($branch in [BranchDetails[]]$currentRepo.Branches) {
            $branch.Branch = "refs/remotes/$($currentRepo.Name)/$($branch.Branch)"
            if ($branches -notcontains $branch) { $branches.Add($branch) }
        }

        ## Configured Other
        foreach ($repo in [RemoteRepo[]]$this.GetConfiguredOthers()) {
            foreach ($branch in [BranchDetails[]]$repo.Branches) {
                $branch.Branch = "refs/remotes/$($repo.Name)/$($branch.Branch)"
                if ($branches -notcontains $branch) { $branches.Add($branch) }
            }
        }

        ## Local Other
        foreach ($repo in [RemoteRepo[]]$this.GetLocalOthers()) {
            foreach ($branch in [BranchDetails[]]$repo.Branches) {
                $branch.Branch = "refs/heads/$($branch.Branch)"
                if ($branches -notcontains $branch) { $branches.Add($branch) }
            }
        }

        [PSCustomObject[]]$compareAheadBehind = @()
        foreach ($branchA in $branches) {
            foreach ($branchB in $branches) {
                #if ($branchB -eq $branchA) { continue }
                #if ($compareAheadBehind.Where({$_.Left -eq $branchB -and $_.Right -eq $branchA})) { continue }
                ### TODO: Add check for when local = origin fetch/push, therefore don't redo origin and others
                # Double quotes is required around the entire "A...B" in order to parse properly
                if ((git rev-list --left-right --count "$($branchA.Branch)...$($branchB.Branch)") -match '^\s*(?<ahead>\d+)\s+(?<behind>\d+)\s*$') {
                    [string]$left = $branchA
                    [string]$right = $branchB
                    [string]$ahead = $Matches.ahead
                    [string]$behind = $Matches.behind
                    $compareAheadBehind += [PSCustomObject]@{
                        Left = $branchA
                        Right = $branchB
                        Ahead = $Matches.ahead
                        Behind = $Matches.behind
                        Arrow = $(switch ($true){
                            ({$Matches.behind -eq 0 -and $Matches.ahead -eq 0}){'^fe===^fz'}
                            ({$Matches.behind -eq 0 -and $Matches.ahead -gt 0}){'^fg==>^fz'}
                            ({$Matches.behind -gt 0 -and $Matches.ahead -eq 0}){'^fr<==^fz'}
                            default{'^fR<=>^fz'}
                        })
                    }
                }
            }
        }
        [int]$longest=0
        $branches.ForEach({if (([string]$_).Length -gt $longest) {$longest = ([string]$_).Length}})
        Write-Console " Bnd | Ahd  - $('Branch A'.PadLeft($longest,' ')) --- $('Branch B'.PadRight($longest,' '))`t LastCmt --- LastCmt" -Title 'Compare'
        [DateTime]$now = Get-Date
        [DateTime]$stale = (Get-Date).AddDays(-90)
        $compareAheadBehind |
        #Sort-Object Left,Right |
        ForEach-Object {
            [string]$left = $_.Left
            [string]$right = $_.Right

            [DateTime]$leftTime      = $branchCommits.$($left).Time
            [DateTime]$rightTime     = $branchCommits.$($right).Time

            if (($left -eq $local) -or ($leftTime -gt $stale -and $rightTime -gt $stale)) {

                [string]$fgl    = $(switch ($left) { $local {'^fM'} $upstream {'^fM'} default { '' }})
                [string]$fgr    = $(switch ($right) { $local {'^fM'} $upstream {'^fM'} default { '' }})

                [string]$ahead  = ([string]($_.Ahead)).PadRight(4,' ')
                [string]$behind = ([string]($_.Behind)).PadLeft(4,' ')

                [string]$arrow  = $_.Arrow

                [string]$leftString   = $fgl + $left.PadLeft($longest,' ') + '^fz'
                [string]$rightString  = $fgr + $right.PadRight($longest,' ') + '^fz'

                [string]$leftTimeString  = (Format-DateDiff $now $leftTime).PadLeft(7,' ')
                [string]$rightTimeString = (Format-DateDiff $now $rightTime).PadRight(7,' ')

                if ($leftTime -lt $rightTime)     {[string]$timearrow = '^fr<==^fz'}
                elseif ($leftTime -gt $rightTime) {[string]$timearrow = '^fg==>^fz'}
                else                              {[string]$timearrow = '^fe===^fz'}

                Write-Console "$behind | $ahead - $leftString $arrow $rightString^bz`t $leftTimeString $timearrow $rightTimeString" -Title 'Compare'
            }
        }
    }
    [void]Display(){
        #if ($ShowName) { Write-Color "^fM$($this.Name)^fz" }
        Write-Console "$($this.CheckConfigRemote())" -Title 'Remote'
        Write-Console "$($this.CheckConfigURL())" -Title 'URL'
        Write-Console "$($this.CheckConfigBranch())" -Title 'Branch'
        Write-Console "$($this.GetCommit())" -Title 'Commit'
    }
    [void]InvokeInitialize() {
        if ((Get-ChildItem).Count -eq 0) {
            if ([string]::IsNullOrWhiteSpace($this.LockAtCommit)) {
                [string]$currentBranch = $this.Branch
                git submodule update --init --recursive -- .
                git checkout -B $currentBranch --force
                git branch --set-upstream-to=origin/$currentBranch $currentBranch
            }
            else {
                git submodule update --init --recursive -- .
                git checkout $($this.LockAtCommit) --force
            }
            $this.Display()
        }
        else {
            $this.Display()
            Write-Console "$($this.Name) is already initialized." -Title 'Init'
        }
    }
    [void]InvokeCheckout() {
        $this.Display()
        if ([string]::IsNullOrWhiteSpace($this.LockAtCommit)) {
            [string]$reportedBranch = $this.GetCurrentBranch()
            [string]$returnBranch = if ($this.Branch -eq $reportedBranch){ $this.Branch }
            elseif (YesOrNo -Prompt "Do you want to swtich from branch `"$($reportedBranch)`" to `"$($this.Branch)`"") { $this.Branch }
            else { $reportedBranch }
            git checkout -B $($returnBranch) --force
            [string]$remote=$this.GetCurrentRemote()
            if ($remote -eq 'DETATCHED') { $remote = 'origin' }
            git branch --set-upstream-to=$remote/$returnBranch $returnBranch
            git fetch --force $remote
        }
        else { (git checkout "$($this.LockAtCommit)") }
    }
    [void]InvokeReset() {
        $this.Display()
        [string]$upstream = [string]::IsNullOrWhiteSpace($this.LockAtCommit) ? $this.GetCurrentUpstream() : $this.LockAtCommit
        if ($upstream -eq 'DETATCHED') { $upstream = 'origin' }
        if ($script:WhatIF) { Write-Console "git reset --hard $upstream --recurse-submodules" -Title 'WhatIF' }
        else { git reset --hard "$upstream" --recurse-submodules }
    }
    [void]InvokeClean([bool]$Quiet) {
        if ($Quiet) { Write-Console -Value "Cleaning..." -Title "Action" } else { $this.Display() }
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
    [void]InvokePull([bool]$Quiet) {
        if ($this.Pull) {
            if ($Quiet) { Write-Console -Value "Pulling..." -Title "Action" } else { $this.Display() }
            if ($script:WhatIF -and -not $script:ForcePull) { Write-Console "git pull" -Title 'WhatIF' }
            else {
                if ([string]::IsNullOrWhiteSpace($this.LockAtCommit)) {
                    [string]$tmpBranch = $null
                    try { $tmpBranch = git symbolic-ref HEAD }
                    catch { Write-Console "^fr$($_.Exception.Message)^fz" -Title 'Error' }
                    if ([string]::IsNullOrWhiteSpace($tmpBranch)) {
                        $this.InvokeCheckout()
                    }
                    git pull
                }
                else { (git checkout "$($this.LockAtCommit)") }
            }
        }
    }
    [void]InvokePull() { $this.InvokePull($false) }
}