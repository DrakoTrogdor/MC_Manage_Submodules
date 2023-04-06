function BuildSpigot {
    param (
        [string]$Version,
        [string]$ToolPath,
        [string]$JDKPath,
        [Parameter(Mandatory=$false)][Switch]$Remapped,
        [Parameter(Mandatory=$false)][Switch]$ForceBuild,
        [Parameter(Mandatory=$false)][Switch]$ForceInstall,
        [Parameter(Mandatory=$false)][Switch]$SkipCraftBukkitCheck,
        [Parameter(Mandatory=$false)][Switch]$SkipSpigotCheck
    )
    $spigotFile     = Join-Path -Path "$ToolPath" -ChildPath "spigot-$Version$($Remapped ? '-remapped' : '').jar"
    $bukkitFile     = Join-Path -Path "$ToolPath" -ChildPath "craftbukkit-$Version$($Remapped ? '-remapped' : '').jar"
    $spigotBuild    = Join-Path -Path "$ToolPath" -ChildPath "Build" -AdditionalChildPath "spigot-$Version.jar"
    $bukkitBuild    = Join-Path -Path "$ToolPath" -ChildPath "Build" -AdditionalChildPath "craftbukkit-$Version.jar"
    $altBukkitBuild = Join-Path -Path "$ToolPath" -ChildPath "CraftBukkit\target" -AdditionalChildPath "craftbukkit-$Version-R0.1-SNAPSHOT.jar"

    Write-Console "Checking for Spigot and CraftBukkit $Version builds" -Title "Info"
    if ($ForceBuild -or (-not (Test-Path -Path $spigotFile) -and -not $SkipSpigotCheck) -or (-not (Test-Path -Path $bukkitFile) -and -not $SkipCraftBukkitCheck)) {
        Push-Location -Path "$ToolPath" -StackName 'SpigotBuild'

        # Prepare filesystem
        if(!$(Test-Path .\Build))      { New-Item    -Path .\Build        -ItemType Directory }
        if($(Test-Path .\BuildData))   { Remove-Item -Path .\BuildData\   -Recurse -Force }
        if($(Test-Path .\Bukkit))      { Remove-Item -Path .\Bukkit\      -Recurse -Force }
        if($(Test-Path .\CraftBukkit)) { Remove-Item -Path .\CraftBukkit\ -Recurse -Force }
        if($(Test-Path .\Spigot))      { Remove-Item -Path .\Spigot\      -Recurse -Force }
        if($(Test-Path .\work))        { Remove-Item -Path .\work\        -Recurse -Force }

        $javaCommand = [BuildTypeJava]::PushEnvJava($JDKPath)
        Write-Console "Building Craftbukkit and Spigot versions $Version"
        if ($Remapped) {
            $javaProcess = Start-Process -FilePath "$javaCommand" -ArgumentList "-jar $ToolPath\\BuildTools.jar --rev $Version --compile CRAFTBUKKIT,SPIGOT --remapped --output-dir Build" -NoNewWindow -PassThru
        } else {
            if ($Version -like '1.16.2') {
                
                # Clone all repositories
                $javaProcess = Start-Process -FilePath "$javaCommand" -ArgumentList "-jar $ToolPath\\BuildTools.jar --rev $Version --compile NONE --output-dir Build" -NoNewWindow -PassThru
                $javaProcess.WaitForExit()
                
                # Create RegEx search and replacement strings
                $searchString = '\s*<dependency>[\r\n]+\s*<groupId>org\.ow2\.asm</groupId>[\r\n]+\s*<artifactId>asm-tree</artifactId>[\r\n]+\s*<version>8\.0\.1</version>[\r\n]+\s*<scope>test</scope>[\r\n]+\s*</dependency>[\r\n]+'
                $replaceString = @'

        <dependency>
            <groupId>org.ow2.asm</groupId>
            <artifactId>asm</artifactId>
            <version>8.0.1</version>
            <scope>test</scope>
        </dependency>
        <dependency>
            <groupId>org.ow2.asm</groupId>
            <artifactId>asm-tree</artifactId>
            <version>8.0.1</version>
            <scope>test</scope>
        </dependency>

'@
                # Add dependencies to all pom.xml files based on RegEx search and replace
                Get-ChildItem -Filter pom.xml -Recurse | 
                ForEach-Object {
                    ReplaceInFile -SearchRegExp $searchString -ReplaceString $replaceString -File $_.FullName
                }
            
                # Continue with compilation.
                $javaProcess = Start-Process -FilePath "$javaCommand" -ArgumentList "-jar $ToolPath\\BuildTools.jar --dont-update --compile CRAFTBUKKIT,SPIGOT --output-dir Build" -NoNewWindow -PassThru
            }
            else {
                $javaProcess = Start-Process -FilePath "$javaCommand" -ArgumentList "-jar $ToolPath\\BuildTools.jar --rev $Version --compile CRAFTBUKKIT,SPIGOT --output-dir Build" -NoNewWindow -PassThru
            }
        }
        $javaProcess.WaitForExit()
        [BuildTypeJava]::PopEnvJava()

        Move-Item -Path $spigotBuild -Destination $spigotFile -Force -EA:0
        if (Test-Path -Path $bukkitBuild) { Move-Item -Path $bukkitBuild -Destination $bukkitFile -Force -EA:0 }
        elseif (Test-Path -Path $altBukkitBuild) { Copy-Item -Path $altBukkitBuild -Destination $bukkitFile -Force -EA:0 }

        Pop-Location -StackName 'SpigotBuild'
    }
    <#
    if ($Remapped) {
        if ($ForceInstall -or ($null -ne (mvn dependency:get -DgroupId='org.spigotmc' -DartifactId=spigot -Dversion="$Version-R0.1-SNAPSHOT" -Dpackaging=jar -Dclassifier="remapped-mojang" -o -q))){
            Write-Host "Installing spigot $Version-R0.1-SNAPSHOT-remapped-mojang to maven local repository"
            mvn install:install-file -DgroupId='org.spigotmc' -DartifactId=spigot -Dversion="$Version-R0.1-SNAPSHOT" -Dpackaging=jar -Dclassifier="remapped-mojang" -Dfile="$spigotFile"
        }
        if ($ForceInstall -or ($null -ne (mvn dependency:get -DgroupId='org.spigotmc' -DartifactId=spigot-api -Dversion="$Version-R0.1-SNAPSHOT" -Dpackaging=jar -Dclassifier="remapped-mojang" -o -q))){
            Write-Host "Installing spigot-API $Version-R0.1-SNAPSHOT-remapped-mojang to maven local repository"
            mvn install:install-file -DgroupId='org.spigotmc' -DartifactId=spigot-api -Dversion="$Version-R0.1-SNAPSHOT" -Dpackaging=jar -Dclassifier="remapped-mojang" -Dfile="$spigotFile"
        }
        if ($ForceInstall -or ($null -ne (mvn dependency:get -DgroupId='org.bukkit' -DartifactId=craftbukkit -Dversion="$Version-R0.1-SNAPSHOT" -Dpackaging=jar -Dclassifier="remapped-mojang" -o -q))){
            Write-Host "Installing craftbukkit $Version-R0.1-SNAPSHOT-remapped-mojang to maven local repository"
            mvn install:install-file -DgroupId='org.bukkit' -DartifactId=craftbukkit -Dversion="$Version-R0.1-SNAPSHOT" -Dpackaging=jar -Dclassifier="remapped-mojang" -Dfile="$bukkitFile"
        }
    }
    if ($ForceInstall -or ($null -ne (mvn dependency:get -DgroupId='org.spigotmc' -DartifactId=spigot -Dversion="$Version-R0.1-SNAPSHOT" -Dpackaging=jar -Dclassifier="" -o -q))){
        Write-Host "Installing spigot $Version-R0.1-SNAPSHOT to maven local repository"
        mvn install:install-file -DgroupId='org.spigotmc' -DartifactId=spigot -Dversion="$Version-R0.1-SNAPSHOT" -Dpackaging=jar -Dfile="$spigotFile"
    }
    if ($ForceInstall -or ($null -ne (mvn dependency:get -DgroupId='org.spigotmc' -DartifactId=spigot-api -Dversion="$Version-R0.1-SNAPSHOT" -Dpackaging=jar -Dclassifier="" -o -q))){
        Write-Host "Installing spigot-API $Version-R0.1-SNAPSHOT to maven local repository"
        mvn install:install-file -DgroupId='org.spigotmc' -DartifactId=spigot-api -Dversion="$Version-R0.1-SNAPSHOT" -Dpackaging=jar -Dfile="$spigotFile"
    }
    if ($ForceInstall -or ($null -ne (mvn dependency:get -DgroupId='org.bukkit' -DartifactId=craftbukkit -Dversion="$Version-R0.1-SNAPSHOT" -Dpackaging=jar -Dclassifier="" -o -q))){
        Write-Host "Installing craftbukkit $Version-R0.1-SNAPSHOT to maven local repository"
        mvn install:install-file -DgroupId='org.bukkit' -DartifactId=craftbukkit -Dversion="$Version-R0.1-SNAPSHOT" -Dpackaging=jar -Dfile="$bukkitFile"
    }
    #>
}
function DownloadFile {
    param (
        [string]$URL
    )
    $file = Split-Path -Path "$URL" -Leaf
    if (-not (Test-Path -Path $file)) {
        Write-Console "Downloading $file..."
        $progressPreference = 'silentlyContinue'
        Invoke-WebRequest -Uri $url -OutFile $file
        Write-Console "$file downloaded."
    }

}
function DownloadFileProvideName {
    param (
        [string]$URL,
        [Parameter(Mandatory=$false)][string]$File
    )
    if ([string]::IsNullOrEmpty($File)) { $File = Join-Path -Path (Resolve-Path -Path .) -ChildPath (Split-Path -Path "$URL" -Leaf) }
    if (-not (Test-Path -Path $File)) {
        Write-Console "Downloading $File..."
        $progressPreference = 'silentlyContinue'
        Invoke-WebRequest -Uri $url -OutFile $File
        Write-Console "$File downloaded."
    }

}

function ConvertLineEndingsToLF {
    param (
        [string]$Path
    )
    if (Test-Path -Path $Path) {
        $Path = Resolve-Path -Path $Path
        $content = [IO.File]::ReadAllText($Path) -replace "`r`n", "`n"
        [IO.File]::WriteAllText($Path, $content)
    }
}
function UnescapeJSONString {
    param (
        [string]$InputString
    )
    # Checks for escaped characters behind odd numbers of '\' (only up to 100, infinite look behinds not allowed)
    $InputString = $InputString  -replace '\\r(?<![^\\](?:\\\\){1,100}r)', "`r" # Carriage Return
    $InputString = $InputString  -replace '\\n(?<![^\\](?:\\\\){1,100}n)', "`n" # New Line
    $InputString = $InputString  -replace '\\b(?<![^\\](?:\\\\){1,100}b)', "`b" # Backspace
    $InputString = $InputString  -replace '\\f(?<![^\\](?:\\\\){1,100}f)', "`f" # Form Feed
    $InputString = $InputString  -replace '\\t(?<![^\\](?:\\\\){1,100}r)', "`t" # Tab
    $InputString = $InputString  -replace '\\"(?<![^\\](?:\\\\){1,100}")', "`"" # Double Quote
    $InputString = $InputString  -replace '\\/(?<![^\\](?:\\\\){1,100}/)', "/"  # Forward Slash
    $InputString = $InputString.Replace("\\","\") # Backslash
    return $InputString
}
function GitCreatePatch {
    param (
        [string]$Branch,
        $LSFilter,
        [Parameter(Mandatory=$false)][Switch]$IgnoreIndexMode
    )
    [string]$patchFile = ".\" + (new-guid).Guid + ".patch"
    # $LSFilter in the style of:
    #    @('*.json', ':(top)*.md', ':/*.md', ':(exclude)*.png', ':!*.png', ':(glob)**/resources/*.txt', '**/resources/*.txt','*.[tj]s', '')
    $PatchString = (git diff $Branch --name-only --diff-filter=M -- $($LSFilter)) | 
    ForEach-Object { git diff --unified=0 --minimal --patch --ignore-blank-lines --ignore-all-space --ignore-cr-at-eol $Branch -- $_ }
    if ($IgnoreIndexMode) { 
        $PatchString = $PatchString | Select-String -NotMatch '^index [a-f0-9]{6,}(?:,[a-f0-9]{6,})*\.\.[a-f0-9]{6,} 100644$'
    }
    $PatchString | Out-File -FilePath $patchFile
    ConvertLineEndingsToLF -Path $patchFile
    Write-Console "PatchFile Written to `"$patchFile`"" -Title 'Create Patch'
    return $patchFile
}
function GitApplyPatch {
    param (
        [string]$PatchString,
        [Parameter(Mandatory=$false)][Switch]$UnescapeJSON
    )
    [string]$patchFile = ".\" + (new-guid).Guid + ".patch"
    if ($UnescapeJSON) {
        $PatchString = (UnescapeJSONString -InputString $PatchString)
    }
    $PatchString | Out-File -FilePath $patchFile
    ConvertLineEndingsToLF -Path $patchFile
    GitApplyPatchFile -PatchFile $patchFile
    # Remove-Item -Path $patchFile -Force
}
function GitApplyPatchFile {
    param (
        [string]$PatchFile
    )
    Write-Console "Applying GIT patch file $PatchFile"
    git apply --ignore-space-change --ignore-whitespace  --unidiff-zero $PatchFile
}
function ReplaceInFile {
    param (
        [string]$SearchRegExp,
        [string]$ReplaceString,
        [string]$File,
        [Parameter(Mandatory=$false)][Switch]$UnescapeJSON
    )
    if ($UnescapeJSON) {
        $SearchRegExp = (UnescapeJSONString -InputString $SearchRegExp)
        $ReplaceString = (UnescapeJSONString -InputString $ReplaceString)
    }
    $content = (Get-Content -Path $File -Raw)
    $content = $content -replace "$searchRegExp","$replaceString"
    Set-Content -Path $File -Value $content -NoNewline
}
function ExecuteGradleTask {
    param (
        [string]$GradleTask,
        [Parameter(Mandatory=$false)][string]$JAVA_OPTS,
        [Parameter(Mandatory=$false)][Switch]$PlainText,
        [Parameter(Mandatory=$false)][Switch]$Quiet
    )
    [string]$gradlewInvokeString = [string]::IsNullOrWhiteSpace($JAVA_OPTS) ? $([BuildTypeGradle]::gradlew) : $([BuildTypeGradle]::gradlew) -replace '(java(?:.exe)?[''"]?)', "`$1 $JAVA_OPTS"
    $gradlewInvokeString += " $GradleTask $([BuildTypeGradle]::gradleOptions -join ' ')"
    if ($PlainText) {
        $gradlewInvokeString = $gradlewInvokeString -replace '--console=\w+', ''
        $gradlewInvokeString += '--console=plain'
    }
    if ($Quiet) {
        return (Invoke-Expression -Command "$gradlewInvokeString")
    }
    else {
        Write-Console "Gradle Task: $GradleTask" -Title "Executing"
        $currentProcess = Start-Process -FilePath "$env:ComSpec" -ArgumentList "/c $gradlewInvokeString" -NoNewWindow -PassThru
        $currentProcess.WaitForExit()
        Stop-Process $currentProcess -ErrorAction SilentlyContinue
    }
}

function HasParentProcess {
    param (
        [PSCustomObject]$Process,
        [string]$TargetProcessName
    )
    if (-not $process) {
        # FALSE - No Process
        return $false
    }
    $parentProcess = $process.Parent
    if ($parentProcess.ProcessName -like $targetProcessName) {
        # TRUE - ProcessName == $targetProcessName
        return $true
    }
    elseif ([string]::IsNullOrEmpty($parentProcess.ProcessName)) {
       # FALSE - ProcessName == Null or Empty
       return $false
    }
    else {
        # DIVE - ProcessName != $targetProcessName
        return HasParentProcess -Process $parentProcess -TargetProcessName $targetProcessName
    }
}