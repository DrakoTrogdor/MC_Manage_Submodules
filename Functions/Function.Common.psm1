function BuildSpigot {
    param (
        [string]$Version,
        [string]$ToolPath,
        [string]$JDKPath
    )
    $file = Join-Path -Path "$ToolPath" -ChildPath "spigot-$Version.jar"
    if (($null -ne (mvn dependency:get -Dartifact="org.spigotmc:spigot:$Version-R0.1-SNAPSHOT" -o -q)) -or ($null -ne (mvn dependency:get -Dartifact="org.spigotmc:spigot-api:$Version-R0.1-SNAPSHOT" -o -q))) {
        if (-not (Test-Path -Path $file)) {
            Push-Location -Path "$ToolPath" -StackName 'SpigotBuild'
            $javaCommand = [BuildTypeJava]::PushEnvJava($JDKPath)
            Write-Host "Building Craftbukkit and Spigot versions $Version"
            $javaProcess = Start-Process -FilePath "$javaCommand" -ArgumentList "-jar $ToolPath\\BuildTools.jar --rev $Version --compile CRAFTBUKKIT,SPIGOT" -NoNewWindow -PassThru
            $javaProcess.WaitForExit()
            [BuildTypeJava]::PopEnvJava()
            Pop-Location -StackName 'SpigotBuild'
        }
        Write-Host "Installing spigot $Version-R0.1-SNAPSHOT to maven local repository"
        mvn install:install-file -DgroupId='org.spigotmc' -DartifactId=spigot -Dversion="$Version-R0.1-SNAPSHOT" -Dpackaging=jar -Dfile="$file"
        Write-Host "Installing spigot-API $Version-R0.1-SNAPSHOT to maven local repository"
        mvn install:install-file -DgroupId='org.spigotmc' -DartifactId=spigot-api -Dversion="$Version-R0.1-SNAPSHOT" -Dpackaging=jar -Dfile="$file"
    }
}