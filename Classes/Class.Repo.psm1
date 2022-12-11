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
        $this.Name           = [string]::IsNullOrWhiteSpace($Name)          ? 'origin'      : ( $Name -ilike 'origin' ? 'origin' : $Name )
        $this.URL            = [string]::IsNullOrWhiteSpace($URL)           ? ''            : $URL
        $this.DefaultBranch  = [string]::IsNullOrWhiteSpace($DefaultBranch) ? 'master'      : ( $DefaultBranch -ilike 'master' ? 'master' : $DefaultBranch )
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
    RemoteRepo([System.Collections.DictionaryEntry]$Value) {
        [string]$tmpName          = $Value.Key
        [hashtable]$tmpValue      = $Value.Value
        [string]$tmpURL           = $tmpValue.Contains('URL')                  ? [string]$tmpValue.URL           : $null
        [string]$tmpDefaultBranch = $tmpValue.Contains('DefaultBranch')        ? [string]$tmpValue.DefaultBranch : $null
        [bool]$tmpDetatched       = $tmpValue.Contains('Detatched')            ? [string]$tmpValue.Detatched     : $false
        [Collections.Generic.List[string]]$tmpIgnoreBranches = [Collections.Generic.List[string]]::new()
        if ($tmpValue.Contains('IgnoreBranches')){
            foreach ($branch in $tmpValue.IgnoreBranches) {
                $tmpIgnoreBranches.Add([string]::new([string]$branch))
            }
        }
        $this.Init($tmpName, $tmpURL, $tmpDefaultBranch, $tmpDetatched, $tmpIgnoreBranches.ToArray())
    }
    [void]InitializeBranches() {
        [System.Collections.Generic.List[BranchDetails]]$tmpBranches = [System.Collections.Generic.List[BranchDetails]]::new()
        if ($this.Name -eq 'HEAD' -or $this.Name -eq 'DETATCHED') {
            if (((git rev-list HEAD -n 1 --date=unix --pretty=format:"%cd") -join "`r`n") -match '(?ms)(?:^commit (?<commit>[a-f0-9]+)\s*(?:(?<time>\d+))$)' ) {
                $tmpBranches.Add([BranchDetails]::new($this.Name, $Matches.commit, $Matches.time))
            }
            else { $tmpBranches.Add([BranchDetails]::new($this.Name, '', '')) }
        }
        else {
            [string]$branchIgnoreRegex = '.*(' + (($this.IgnoreBranches.Where({$_ -notmatch '^\s*$'}).ForEach({$_.Trim()})) -join '|') +').*'
            if ($branchIgnoreRegex -eq '.*().*') { $branchIgnoreRegex = '^$' }
            [string[]]$lsRemoteHeads = git ls-remote --heads $this.Name
            foreach ($item in $lsRemoteHeads) {
                if ($item -match '^(?<commit>[a-fA-F0-9]+)\s+refs/heads/(?<branch>.*)$') {
                    [string]$tmpBranch = $Matches.branch
                    [string]$tmpCommit = $Matches.commit
                    if ($tmpBranch -notmatch $branchIgnoreRegex) {
                        if (((git rev-list $tmpCommit -n 1 --date=unix --pretty=format:"%cd") -join "`r`n") -match '(?ms)(?:^commit (?<commit>[a-f0-9]+)\s*(?:(?<time>\d+))$)' ) {
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
        $this.RemoteRepos      = $null -eq $RemoteRepos                      ? [RemoteRepo[]]@() : $RemoteRepos
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
            foreach ($remote in $Value.Remotes.GetEnumerator()) {
                $tmpRemoteRepo.Add([RemoteRepo]::new([System.Collections.DictionaryEntry]$remote))
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
    [RemoteRepo]GetConfiguredOrigin() { return $this.GetConfiguredByName('Origin') }
    [RemoteRepo]GetConfiguredUpstream() { return $this.GetConfiguredByName('Upstream') }
    [RemoteRepo[]]GetConfiguredOthers() {
        [System.Collections.Generic.List[RemoteRepo]]$return = [System.Collections.Generic.List[RemoteRepo]]::new()
        foreach ($repo in $this.RemoteRepos) {
            if ($repo -ne $this.GetConfiguredOrigin() -and $repo -ne $this.GetConfiguredUpstream()) {
                $repo.InitializeBranches()
                $return.Add($repo)
            }
        }
        return $return.ToArray()
    }
    [RemoteRepo]GetConfiguredByName([string]$Name) {
        [RemoteRepo]$return = $this.RemoteRepos |
            Where-Object { $_.Name -like $Name } |
            Select-Object -First 1
        if ($null -ne $return) { $return.InitializeBranches() }
        return $return
    }
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
            $return.URL = $this.GetURL($this.GetConfiguredByName('origin').Name)
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

        # Set the Default Branch and URL
        if ($return.Detatched) {
            $return.DefaultBranch = "DETATCHED - $($return.Commit)"
            $return.URL = $this.GetURL($this.GetConfiguredByName('origin').Name)
        }
        else {
            $return.DefaultBranch = $symbolicFullName -replace '^[^/]*/',''
            $return.URL = $this.GetURL($return.Name)
        }

        if (-not $return.Detatched) {
            [RemoteRepo]$configuredRepo = $this.GetConfiguredByName($return.Name)
            if ($null -ne $configuredRepo) { $return.IgnoreBranches = $configuredRepo.IgnoreBranches }

        }
        $return.InitializeBranches()
        return $return
    }
    [RemoteRepo[]]GetLocalOthers() {
        [System.Collections.Generic.List[RemoteRepo]]$return = [System.Collections.Generic.List[RemoteRepo]]::new()
        [string]$headBranch = (git rev-parse --symbolic-full-name HEAD) -replace 'refs/heads/',''
        [string[]]$remotes = (git remote)
        foreach ($remote in $remotes) {
            $remote = $remote.Trim()
            $defaultBranch = (git symbolic-ref refs/remotes/$remote/HEAD) -replace "refs/remotes/$remote/",''
            if ($defaultBranch -ne $headBranch) {
                [RemoteRepo]$repo = [RemoteRepo]::new()
                git fetch $remote --tags --prune --prune-tags --update-head-ok
                $repo.Name = $remote
                $repo.URL = $this.GetURL($remote)
                $repo.DefaultBranch = (git symbolic-ref refs/remotes/$remote/HEAD) -replace "refs/remotes/$remote/",''

                [RemoteRepo]$configuredRepo = $this.GetConfiguredByName($remote)
                if ($null -ne $configuredRepo) { $repo.IgnoreBranches = $configuredRepo.IgnoreBranches }
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
            if ($currentRepo.Detatched -or $this.IsLockedAtCommit()) { $branch.Branch = $branch.Commit }
            else { $branch.Branch = "refs/heads/$(git branch --show-current)" }
            if ($null -eq $localHead) { $localHead = $branch }
            $branches.Add($branch)
        }

        ## Configured Origin set as remoteOrigin if one has not been set already
        $currentRepo = $this.GetConfiguredOrigin()
        foreach ($branch in [BranchDetails[]]$currentRepo.Branches) {
            [string]$branchName = $branch.Branch
            $branch.Branch = "refs/remotes/$($currentRepo.Name)/$($branch.Branch)"
            if ($null -eq $remoteOrigin -and $branchName -like $currentRepo.DefaultBranch ) {
                $branch.Comment = 'Set from Configured Origin'
                $remoteOrigin = $branch
            }
            if ($branches -notcontains $branch) { $branches.Add($branch) }
        }

        ## Local Upstream (Origin) set as remoteOrigin if one has not been set already
        $currentRepo = $this.GetLocalUpstream()
        foreach ($branch in [BranchDetails[]]$currentRepo.Branches) {
            [string]$branchName = $branch.Branch
            $branch.Branch = "refs/remotes/$($currentRepo.Name)/$($branch.Branch)"
            if ($null -eq $remoteOrigin -and $branchName -like $currentRepo.DefaultBranch ) {
                $branch.Comment = 'Set from Local Upstream'
                $remoteOrigin = $branch
            }
            if ($branches -notcontains $branch) { $branches.Add($branch) }
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
                if ($branchB -eq $branchA) { continue } # Skip over comparing a branch to itself

                # Skip over commits that have already been compared.
                if ($compareAheadBehind.Where({$_.Left.Commit -eq $branchA.Commit -and $_.Right.Commit -eq $branchB.Commit})) { continue }
                if ($compareAheadBehind.Where({$_.Left.Commit -eq $branchB.Commit -and $_.Right.Commit -eq $branchA.Commit})) { continue }

                ### TODO: Add check for when local = origin fetch/push, therefore don't redo origin and others
                # Double quotes is required around the entire "A...B" in order to parse properly
                [string]$compareAandB = (git rev-list --left-right --count "$($branchA.Branch)...$($branchB.Branch)" -- ) 2> $null
                if ($compareAandB -match '^\s*(?<ahead>\d+)\s+(?<behind>\d+)\s*$') {
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
        foreach ($branch in [BranchDetails[]]$branches) {
            [string]$branchName = $branch.Branch -replace 'refs/(?:heads|remotes)/',''
            if ($branchName.Length -gt $longest) { $longest = $branchName.Length }
        }
        Write-Console " Bnd | Ahd  - $('Branch A'.PadLeft($longest,' ')) --- $('Branch B'.PadRight($longest,' '))`t LastCmt --- LastCmt" -Title 'Compare'
        [DateTime]$now = Get-Date
        [DateTime]$stale = (Get-Date).AddDays(-90)
        [string]$local = $localHead.Branch -replace 'refs/(?:heads|remotes)/',''
        [string]$upstream = $remoteOrigin.Branch -replace 'refs/(?:heads|remotes)/',''
        $compareAheadBehind |
        #Sort-Object Left,Right |
        ForEach-Object {
            [string]$left = $_.Left.Branch -replace 'refs/(?:heads|remotes)/',''
            [string]$right = $_.Right.Branch -replace 'refs/(?:heads|remotes)/',''

            [DateTime]$leftTime      = $_.Left.Time
            [DateTime]$rightTime     = $_.Right.Time

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
    [string]GetCommit() { return (git rev-parse --short=7 HEAD) 2>$null }
    [string]GetCommitDate([string]$Commit) { return (git show $Commit -s --format=%ci) 2>$null }
    [string]GetCommitDate() { return (git show -s --format=%ci) 2>$null }
    [void]Display(){
        [RemoteRepo]$localRepo    = $this.GetLocalHead()
        [RemoteRepo]$upstreamRepo = $this.GetLocalUpstream()
        [RemoteRepo]$defaultRepo  = $this.GetConfiguredOrigin()
        [string]$compareRemotes   = $upstreamRepo.Name + ($upstreamRepo.Name -like $defaultRepo.Name ?  " (^fgSame^fz)" : " (^frChanged from `"" + $defaultRepo.Name + "`"^fz)")
        [string]$compareURLs      = $upstreamRepo.URL + ($upstreamRepo.URL -like $defaultRepo.URL ? " (^fgSame^fz)" : " (^frChanged from `"" + $defaultRepo.URL + "`"^fz)")
        [string]$compareBranches  = $localRepo.DefaultBranch + ($localRepo.DefaultBranch -like $defaultRepo.DefaultBranch ? " (^fgSame^fz)" : " (^frChanged from `"" + $defaultRepo.DefaultBranch + "`"^fz)")
        [string]$commit           = $this.GetCommit()
        [string]$commitDate       = $this.GetCommitDate($commit)

        #if ($ShowName) { Write-Color "^fM$($this.Name)^fz" }
        Write-Console "$compareRemotes" -Title 'Remote'
        Write-Console "$compareURLs" -Title 'URL'
        Write-Console "$compareBranches" -Title 'Branch'
        Write-Console "$commit" -Title 'Commit'
        Write-Console "$commitDate" -Title 'Date'
    }
    [void] hidden UpdateAndCheckoutSubmodule([string]$Branch,[bool]$SetUpstream=$false){
        git submodule update --init --recursive -- .
        git checkout -B $Branch --force
        if($SetUpstream) { git branch --set-upstream-to=origin/$Branch $Branch }
    }
    [void]InvokeInitialize() {
        if ((Get-ChildItem).Count -eq 0) {
            if ([string]::IsNullOrWhiteSpace($this.LockAtCommit)) {
                $this.UpdateAndCheckoutSubmodule($this.GetConfiguredOrigin().DefaultBranch,$true)
<#
                [string]$currentBranch = $this.Branch
                git submodule update --init --recursive -- .
                git checkout -B $currentBranch --force
                git branch --set-upstream-to=origin/$currentBranch $currentBranch
 #>
            }
            else {
                $this.UpdateAndCheckoutSubmodule($this.LockAtCommit)
<#
                git submodule update --init --recursive -- .
                git checkout $($this.LockAtCommit) --force
#>
            }
            $this.Display()
        }
        else {
            $this.Display()
            [string]$symbolicFullName = (git rev-parse --abbrev-ref --symbolic-full-name HEAD)
            [string]$branchRemote = (git config --get branch.$($symbolicFullName).remote)
            if ([string]::IsNullOrWhiteSpace($this.GetURL($branchRemote))){
                if ([string]::IsNullOrWhiteSpace($this.LockAtCommit)) {
                    $this.UpdateAndCheckoutSubmodule($this.GetConfiguredOrigin().DefaultBranch,$true)
                }
                else {
                    $this.UpdateAndCheckoutSubmodule($this.LockAtCommit)
                }
                }
            else {
                Write-Console "$($this.Name) is already initialized." -Title 'Init'
            }
        }
    }
    [void]InvokeCheckout() {
        $this.Display()
        if ([string]::IsNullOrWhiteSpace($this.LockAtCommit)) {
            [string]$reportedBranch = (git branch --show-current)
            if ([string]::IsNullOrEmpty($reportedBranch)) { $reportedBranch = "DETATCHED - $(git rev-parse --short=7 HEAD)" }

            [RemoteRepo]$defaultRepo  = $this.GetConfiguredOrigin()

            [string]$defaultBranch = $defaultRepo.DefaultBranch
            [string]$returnBranch = if ($defaultBranch -eq $reportedBranch)                                                                      { $defaultBranch }
                                    elseif (YesOrNo -Prompt "Do you want to swtich from branch `"$($reportedBranch)`" to `"$($defaultBranch)`"") { $defaultBranch }
                                    else                                                                                                         { $reportedBranch }
            git checkout -B $($returnBranch) --force --quiet
            [string]$remote = (git rev-parse --abbrev-ref --symbolic-full-name '@{upstream}') 2>&1
            if ($remote -like 'fatal: * does not point to a branch') { $remote = $defaultBranch.Name }
            else { $remote = $remote -replace '/.*$', '' }
            git branch --set-upstream-to=$remote/$returnBranch $returnBranch
            git fetch $remote --tags --prune --prune-tags --update-head-ok --write-commit-graph --force --quiet
        }
        else { (git checkout "$($this.LockAtCommit)") }
    }
    [void]InvokeReset([bool]$Quiet) {
        if ($Quiet) { Write-Console -Value "Resetting..." -Title "Action" } else { $this.Display() }
        $configuredOrigin = $this.GetConfiguredOrigin()
        $remoteOrigin = $configuredOrigin.Name
        if ($remoteOrigin -eq 'DETATCHED') { $remoteOrigin = 'origin' }
        $remoteBranch = $configuredOrigin.DefaultBranch
        [string]$upstream = [string]::IsNullOrWhiteSpace($this.LockAtCommit) ? $remoteOrigin + "/" + $remoteBranch : $this.LockAtCommit
        if ($script:WhatIF) { Write-Console "git reset --hard $upstream --recurse-submodules" -Title 'WhatIF' }
        else { git reset --hard "$upstream" --recurse-submodules }
    }
    [void]InvokeReset() { $this.InvokeReset($false) }
    [void]InvokeRepair([bool]$Quiet) {
        if ($Quiet) { Write-Console -Value "Repairing..." -Title "Action" } else { $this.Display() }
        $remoteOrigin = $this.GetConfiguredOrigin().Name
        [string]$upstream = [string]::IsNullOrWhiteSpace($this.LockAtCommit) ? $remoteOrigin.Name : $this.LockAtCommit
        if ($upstream -eq 'DETATCHED') { $upstream = 'origin' }
        if ($script:WhatIF) {
            Write-Console "git fetch --all --tags --prune --prune-tags --update-head-ok --write-commit-graph --force" -Title 'WhatIF'
            Write-Console "git fsck --full --strict" -Title 'WhatIF'
            Write-Console "git reflog expire --expire=now --expire-unreachable=now --stale-fix --all" -Title 'WhatIF'
            Write-Console "git gc --prune=now" -Title 'WhatIF'
            Write-Console "git repack -ad" -Title 'WhatIF'
            Write-Console "git commit-graph write" -Title 'WhatIF'
        }
        else {
            git fetch --all --tags --prune --prune-tags --update-head-ok --write-commit-graph --force
            git fsck --full --strict
            git reflog expire --expire=now --expire-unreachable=now --stale-fix --all
            git gc --prune=now
            git repack -ad
        }
    }
    [void]InvokeRepair() { $this.InvokeRepair($false) }
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
                    git fetch --all --tags --prune --prune-tags --force
                    git pull
                    git submodule update --checkout --recursive
                }
                else { (git checkout "$($this.LockAtCommit)") }
            }
        }
    }
    [void]InvokePull() { $this.InvokePull($false) }
}