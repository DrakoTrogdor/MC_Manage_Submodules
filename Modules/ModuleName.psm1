# using module ..\Functions\Class.Basic.psm1
# Import-Module and the #requires statement only import the module functions, aliases, and variables,
# as defined by the module. Classes are not imported. The using module statement imports the classes
# defined in the module. If the module isn't loaded in the current session, the using statement fails.
# Above needs to remain the first line to import Classes remove the comment # when using the class

#requires -Version 2
#Get public and private function definition files.
$Public = @( Get-ChildItem -Path $PSScriptRoot\..\Functions\*-Public*.ps1 -Recurse -ErrorAction SilentlyContinue )
$Private = @( Get-ChildItem -Path $PSScriptRoot\..\Functions\*-Private*.ps1 -Recurse -ErrorAction SilentlyContinue )

#Dot source the files
Foreach ($import in @($Public + $Private)) {
    Try {
        . $import.fullname
    }
    Catch {
        Write-Error -Message "Failed to import function $($import.fullname): $_"
    }
}

Export-ModuleMember -Function $Public.Basename
