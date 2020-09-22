#########################
# Declare Class GitRepo #
#########################
class GitRepo {
    [string]$Name
    [string]$Origin
    [string]$Branch
    [string]$LockAtCommit
    [System.Boolean]$Pull
    [GitRepo[]]$SubModules
    [string[]]$BranchIgnore
    [string[]]$ArchiveAdditions
    [string[]]$CleanAdditions
    [string[]]$CleanExceptions
    [void] hidden Init (
        [string]$Name,
        [string]$Origin,
        [string]$Branch,
        [string]$LockAtCommit,
        [System.Boolean]$Pull,
        [string[]]$BranchIgnore,
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
        $this.Branch           = if ([string]::IsNullOrWhiteSpace($Branch))       { 'master' } else { $Branch       }
        $this.LockAtCommit     = if ([string]::IsNullOrWhiteSpace($LockAtCommit)) { $null    } else { $LockAtCommit }
        $this.Pull             = if ($null -eq $Pull)             { $true          } else { $Pull             }
        $this.SubModules       = if ($null -eq $SubModules)       { [GitRepo[]]@() } else { $SubModules       }
        $this.BranchIgnore     = if ($null -eq $BranchIgnore)     { [string[]]@()  } else { $BranchIgnore     }
        $this.ArchiveAdditions = if ($null -eq $ArchiveAdditions) { [string[]]@()  } else { $ArchiveAdditions }
        $this.CleanAdditions   = if ($null -eq $CleanAdditions)   { [string[]]@()  } else { $CleanAdditions   }
        $this.CleanExceptions  = if ($null -eq $CleanExceptions)  { [string[]]@()  } else { $CleanExceptions  }
    }
    GitRepo() { $this.init($null, $null,   'master', $true, [string[]]@(), [GitRepo[]]@()), [string[]]@(), [string[]]@(), [string[]]@() }
    GitRepo([Hashtable]$Value) {
        $tmpName        = $Value.Contains('Name')           ? [string]$Value.Name          : $null
        $tmpOrigin      = $Value.Contains('Origin')         ? [string]$Value.Origin        : $null
        $tmpBranch      = $Value.Contains('Branch')         ? [string]$Value.Branch        : 'master'
        $tmpPull        = $Value.Contains('Pull')           ? [System.Boolean]$Value.Pull  : $true
        $tmpLockAtCommit  = $Value.Contains('LockAtCommit') ? [string]$Value.LockAtCommit  : $null
        $tmpSubModules =  [GitRepo[]]@()
        $tmpBranchIgnore = [string[]]@()
        if ($Value.Contains('BranchIgnore')){
            foreach ($item in $Value.BranchIgnore){
                $tmpBranchIgnore += [string]$item
            }
            
        }
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
        $this.Init($tmpName, $tmpOrigin, $tmpBranch, $tmpLockAtCommit, $tmpPull, $tmpBranchIgnore, $tmpSubModules, $tmpArchiveAdditions, $tmpCleanAdditions, $tmpCleanExceptions)
    }
    [string]GetUpstream() {
        [string]$return = (git rev-parse --abbrev-ref --symbolic-full-name '@{upstream}') 2>&1
        if ($return -like 'fatal: * does not point to a branch') { $return = 'DETATCHED' }
        return $return
    }
    [string]GetRemote() {
        [string]$return = $this.GetUpstream() -replace '/.*$',''
        return $return
    }
    [string]GetURL() {
        [string]$remote = $this.GetRemote()
        if ($remote -ne 'DETATCHED' -and [string]::IsNullOrWhiteSpace($this.LockAtCommit)) {
            [string]$return = $this.GetURL($remote)
        }
        else {
            [string]$return = $this.Origin
        }
        return $return
    }
    [string]GetURL([string]$remote) {
        [string]$return = (git config --get remote.$remote.url)
        return $return
    }
    [string]GetBranch() {
        [string[]]$Value = (git branch)
        [string]$return = ( $Value | Select-String -Pattern '(^\* (?''match''.*)$)' | Select-Object -First 1 | ForEach-Object {
            $_.matches.groups | Where-Object {
                $_.Name -match 'match'
            }
        } | Select-Object -Expand Value )
        if ($return -match '\(.* detached at (?<commit>[a-f0-9]+)\)') { $return = "DETATCHED - $($Matches.commit)" }
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
    [void]CompareAheadBehind() {
        [string]$upstream = $this.GetUpstream()
        if ($upstream -ne 'DETATCHED' -and [string]::IsNullOrWhiteSpace($this.LockAtCommit)) { [string]$local = $this.GetBranch() }
        elseif($upstream -eq 'DETATCHED' -and -not [string]::IsNullOrWhiteSpace($this.LockAtCommit)) { [string]$local = $this.LockAtCommit }
        else { 
            $this.InvokeCheckout()
            [string]$local = $this.GetBranch()
        }
        [string[]]$remotes = (git remote)
        foreach ($remote in $remotes) {
            ### TODO: Add check for deleted repositories ####
            Write-Console "$($remote): $($this.GetURL($remote))" -Title 'Compare'
            git fetch "$($remote.Trim())"
        }
        [string]$branchIgnoreRegex = '(' + (($this.BranchIgnore.Where({$_ -notmatch '^\s*$'}).ForEach({$_.Trim()})) -join '|') +')'
        if ($branchIgnoreRegex -eq '()') {
            [string[]]$branches = @($local) + @((git branch -r) -notmatch '^\s*(?<remote>.*)/HEAD -> \k<remote>/.*$').trim()
        }
        else {
            [string[]]$branches = @($local) + @((git branch -r) -notmatch '^\s*(?<remote>.*)/HEAD -> \k<remote>/.*$' -notmatch ".*$branchIgnoreRegex.*").trim()
        }
        [System.Collections.Hashtable]$branchCommits = New-Object System.Collections.Hashtable
        [PSCustomObject[]]$compareAheadBehind = @()
        foreach ($branchA in $branches) {
            [string]$commitA = switch ($branchA) {
                ({![string]::IsNullOrWhiteSpace($this.LockAtCommit) -and $branchA -eq $this.LockAtCommit}) { $this.LockAtCommit; break }
                $local { "refs/heads/$branchA"; break }
                default { "refs/remotes/$branchA" }
            }
            if (((git rev-list "$commitA" -n 1 --date=unix --abbrev-commit --pretty=format:"%cd") `
            -join "`r`n") -match '(?ms)(?:^commit (?<commit>[a-f0-9]+)\s*(?:(?<time>\d+))$)' ) {
                [string]$tmpCommit = $Matches.commit.Trim()
                [DateTime]$tmpTime = ConvertFrom-UnixTime $($Matches.time.Trim())
                $branchCommits.$branchA = [PSCustomObject]@{ Commit = $tmpCommit; Time = $tmpTime }
            }
            else { $branchCommits.$branchA = [PSCustomObject]@{ Commit = ''; Time = '' } }
            foreach ($branchB in $branches) {
                if ($branchB -eq $branchA) { continue }
                if ($compareAheadBehind.Where({$_.Left -eq $branchB -and $_.Right -eq $branchA})) { continue }
                ### TODO: Add check for when local = origin fetch/push, therefore don't redo origin and others
                # Double quotes is required around the entire "A...B" in order to parse properly
                [string]$commitB = switch ($branchB) {
                    ({![string]::IsNullOrWhiteSpace($this.LockAtCommit) -and $branchB -eq $this.LockAtCommit}) { $this.LockAtCommit; break }
                    $local { "refs/heads/$branchB"; break }
                    default { "refs/remotes/$branchB" }
                }
                if ((git rev-list --left-right --count "$($commitA)...$($commitB)") -match '^\s*(?<ahead>\d+)\s+(?<behind>\d+)\s*$') {
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
        Write-Console "$($this.CheckConfigRemote($true))" -Title 'Remote'
        Write-Console "$($this.CheckConfigURL($true))" -Title 'URL'
        Write-Console "$($this.CheckConfigBranch($true))" -Title 'Branch'
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
            [string]$reportedBranch = $this.GetBranch()
            [string]$returnBranch = if ($this.Branch -eq $reportedBranch){ $this.Branch }
            elseif (YesOrNo -Prompt "Do you want to swtich from branch `"$($reportedBranch)`" to `"$($this.Branch)`"") { $this.Branch }
            else { $reportedBranch }
            git checkout -B $($returnBranch) --force
            [string]$remote=$this.GetRemote()
            if ($remote -eq 'DETATCHED') { $remote = 'origin' }
            git branch --set-upstream-to=$remote/$returnBranch $returnBranch
            git fetch --force $remote
        }
        else { (git checkout "$($this.LockAtCommit)") }
    }
    [void]InvokeReset() {
        $this.Display()
        [string]$upstream = [string]::IsNullOrWhiteSpace($this.LockAtCommit) ? $this.GetUpstream() : $this.LockAtCommit
        if ($upstream -eq 'DETATCHED') { $upstream = 'origin' }
        if ($script:WhatIF) { Write-Console "git reset --hard $upstream --recurse-submodules" -Title 'WhatIF' }
        else { git reset --hard "$upstream" --recurse-submodules }
    }
    [void]InvokeClean([System.Boolean]$Quiet) {
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
    [void]InvokePull([System.Boolean]$Quiet) {
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