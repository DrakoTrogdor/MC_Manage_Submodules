function BuildSpigot {
    param (
        [string]$Version,
        [string]$ToolPath,
        [string]$JDKPath,
        [Parameter(Mandatory=$false)][Switch]$Remapped,
        [Parameter(Mandatory=$false)][Switch]$ForceBuild,
        [Parameter(Mandatory=$false)][Switch]$ForceInstall
    )
    $spigotFile = Join-Path -Path "$ToolPath" -ChildPath "spigot-$Version.jar"
    $bukkitFile = Join-Path -Path "$ToolPath" -ChildPath "craftbukkit-$Version.jar"
    Write-Console "Checking for Spigot and CraftBukkit $Version builds" -Title "Info"
    if ($ForceBuild -or -not (Test-Path -Path $spigotFile) -or -not (Test-Path -Path $bukkitFile)) {
        Push-Location -Path "$ToolPath" -StackName 'SpigotBuild'
        $javaCommand = [BuildTypeJava]::PushEnvJava($JDKPath)
        Write-Console "Building Craftbukkit and Spigot versions $Version"
        if ($Remapped) {
            $javaProcess = Start-Process -FilePath "$javaCommand" -ArgumentList "-jar $ToolPath\\BuildTools.jar --rev $Version --compile CRAFTBUKKIT,SPIGOT --remapped" -NoNewWindow -PassThru
        } else {
            $javaProcess = Start-Process -FilePath "$javaCommand" -ArgumentList "-jar $ToolPath\\BuildTools.jar --rev $Version --compile CRAFTBUKKIT,SPIGOT" -NoNewWindow -PassThru
        }
        $javaProcess.WaitForExit()
        [BuildTypeJava]::PopEnvJava()
        Pop-Location -StackName 'SpigotBuild'
    }
    if ($ForceInstall -or ($null -ne (mvn dependency:get -Dartifact="org.spigotmc:spigot:$Version-R0.1-SNAPSHOT" -o -q))){
        Write-Console "Installing spigot $Version-R0.1-SNAPSHOT to maven local repository"
        if ($Remapped) { mvn install:install-file -DgroupId='org.spigotmc' -DartifactId=spigot -Dversion="$Version-R0.1-SNAPSHOT" -Dpackaging=jar -Dclassifier="remapped-mojang" -Dfile="$spigotFile" }
        else { mvn install:install-file -DgroupId='org.spigotmc' -DartifactId=spigot -Dversion="$Version-R0.1-SNAPSHOT" -Dpackaging=jar -Dfile="$spigotFile" }
    }
    if ($ForceInstall -or ($null -ne (mvn dependency:get -Dartifact="org.spigotmc:spigot-api:$Version-R0.1-SNAPSHOT" -o -q))) {
        Write-Console "Installing spigot-API $Version-R0.1-SNAPSHOT to maven local repository"
        if ($Remapped) { mvn install:install-file -DgroupId='org.spigotmc' -DartifactId=spigot-api -Dversion="$Version-R0.1-SNAPSHOT" -Dpackaging=jar -Dclassifier="remapped-mojang" -Dfile="$spigotFile" }
        else { mvn install:install-file -DgroupId='org.spigotmc' -DartifactId=spigot-api -Dversion="$Version-R0.1-SNAPSHOT" -Dpackaging=jar -Dfile="$spigotFile" }
    }
    if ($ForceInstall -or ($null -ne (mvn dependency:get -Dartifact="org.bukkit:craftbukkit:$Version-R0.1-SNAPSHOT" -o -q))) {
        Write-Console "Installing craftbukkit $Version-R0.1-SNAPSHOT to maven local repository"
        if ($Remapped) { mvn install:install-file -DgroupId='org.bukkit' -DartifactId=craftbukkit -Dversion="$Version-R0.1-SNAPSHOT" -Dpackaging=jar -Dclassifier="remapped-mojang" -Dfile="$bukkitFile" }
        else { mvn install:install-file -DgroupId='org.bukkit' -DartifactId=craftbukkit -Dversion="$Version-R0.1-SNAPSHOT" -Dpackaging=jar -Dfile="$bukkitFile" }
    }
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
        [string]$File
    )
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

function GitApplyPatch {
    param (
        [string]$PatchString,
        [Parameter(Mandatory=$false)][Switch]$UnescapeJSON
    )
    [string]$patchFile = ".\" + (new-guid).Guid + ".patch"
    if ($UnescapeJSON) {
        # Checks for escaped characters behind odd numbers of '\' (only up to 100, infinite look behinds not allowed)
        $PatchString = $PatchString  -replace '\\r(?<![^\\](?:\\\\){1,100}r)', "`r" # Carriage Return
        $PatchString = $PatchString  -replace '\\n(?<![^\\](?:\\\\){1,100}n)', "`n" # New Line
        $PatchString = $PatchString  -replace '\\b(?<![^\\](?:\\\\){1,100}b)', "`b" # Backspace
        $PatchString = $PatchString  -replace '\\f(?<![^\\](?:\\\\){1,100}f)', "`f" # Form Feed
        $PatchString = $PatchString  -replace '\\t(?<![^\\](?:\\\\){1,100}r)', "`t" # Tab
        $PatchString = $PatchString  -replace '\\"(?<![^\\](?:\\\\){1,100}")', "`"" # Double Quote
        $PatchString = $PatchString  -replace '\\/(?<![^\\](?:\\\\){1,100}/)', "/"  # Forward Slash
        $PatchString = $PatchString.Replace("\\","\") # Backslash
    }
    $PatchString | Out-File -FilePath $patchFile
    ConvertLineEndingsToLF -Path $patchFile
    Write-Console "Applying GIT patch file $patchFile"
    git apply --ignore-space-change --ignore-whitespace $patchFile
    Remove-Item -Path $patchFile -Force
}