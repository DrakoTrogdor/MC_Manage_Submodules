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
            $javaProcess = Start-Process -FilePath "$javaCommand" -ArgumentList "-jar $ToolPath\\BuildTools.jar --rev $Version --compile CRAFTBUKKIT,SPIGOT --output-dir Build" -NoNewWindow -PassThru
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
    git apply --ignore-space-change --ignore-whitespace $PatchFile
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