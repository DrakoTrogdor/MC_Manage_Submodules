<#
.SYNOPSIS
    [Brief description of the function or script.  Only used once in each topic.]
.DESCRIPTION
    [Detailed description of the function or script.  Only used once in each topic.]
.PARAMETER [Parameter Name]
    [Parameter Description]
.PARAMETER [Parameter Name]
    [Parameter Descripton]
.EXAMPLE
    PS> Verb-PrivateFunctionName -Parameter1 'Value' -Parameter2 'Value'
    [Description of the example.]
.INPUTS
    The Microsoft .NET Framework types of objects that can be piped to the function or script. You can also include a description of the input objects.
.OUTPUTS
    The .NET Framework type of the objects that the cmdlet returns. You can also include a description of the returned objects.
.NOTES
    Copyright Notice
    Name:       [Verb-PrivateFunctionName]
    Author:     [First Name] [Last Name]
    Version:    [Major].[Minor]     -      [Alpha|Beta|Release Candidate|Release]
    Date:       [Year]-[Month]-[Day]
    Version History:
        [Major].[Minor].[Patch]-[PreRelease]+[BuildMetaData]     -   [Year]-[Month]-[Day]  -   [Description]
    TODO:
        [List of TODOs]
.LINK
    https://subdomain.domain.tld/directory/file.ext
.LINK
    about_Functions
.LINK
    about_Functions_Advanced
.LINK
    about_Functions_Advanced_Methods
.LINK
    about_Functions_Advanced_
.LINK
.LINK
.LINK
.LINK
    Get-Verb

.COMPONENT
    The technology or feature that the function or script uses, or to which it is related. This content appears when the Get-Help command includes the Component parameter of Get-Help.
.FUNCTIONALITY
    [Verb-PrivateFunctionName] The intended use of the function. This content appears when the Get-Help command includes the Functionality parameter of Get-Help.
#>
function script:Verb-PrivateFunctionName {
    <#
      About Scope:
        Function scope is not required and will be in the 'script:' scope by default.
        Variables inside this function will be in the 'function:' scope by default.
        Items within a scope can be listed by using the "Get-ChildItem <scope>:"  cmdlet
    #>
    <#
      About Function vs Filter:
        A function can be described using either the 'function' or 'filter' definitions.
        A filter type function differs from a normal function as it is considered to only have a 'process' block and runs on each object in the pipeline
    #>
    <#
      About Advanced Functions:
        Advanced functions us the CmdletBindgin attribute to identify them as functions tha act similar to .Net Framework compiled cmdlets.
    #>
    [CmdletBinding(
        DefaultParameterSetName = 'Parameter Set 1',
        PositionalBinding = $false,
        <#
          About SupportsShouldProcess:
            Allows implementation of the $PSCmdlet.ShouldProcess() and $PSCmdlet.ShouldContinue() methods in the process block.
            Automatically creates -WhatIf and -Confirm switch parameters.
        #>
        SupportsShouldProcess = $true,
        <#
          About ConfirmImpact:
            Will execute the function as if it was called with '-Confirm' switch if it set to a higher level than the $ConfirmPreference variable.
            By default ConfirmImpact -eq 'Medium' and $ConfirmPreference -eq 'High'
        #>
        ConfirmImpact = 'Medium',
        HelpUri = 'http://www.microsoft.com/'
    )]
    param (
        # Parameter1 Description
        [Parameter(
            Mandatory = $true,
            Position = 0,
            ValueFromPipeline=$true,
            ParameterSetName = 'Parameter Set 1'
        )]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [string]$Parameter1,

        # Parameter2 Description
        [Parameter(
            Mandatory = $false,
            Position = 1,
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = 'Parameter Set 1'
        )]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [PSDefaultValue(Help = 'Parameter2 Default Value')]
        [string]$Parameter2 = 'Parameter2 Default Value',

        # Parameter3 Description
        [Parameter(
            Mandatory = $false,
            Position = 2,
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = 'Parameter Set 1'
        )]
        [switch]$Parameter3

    )
    begin {
        # When function takes input from the pipeline only processes once before enumerating any instances. Will run even if the pipeline is empty
        # The begin block also executes once when run outside of a pipeline
        Write-Verbose -Message 'Verb-PrivateFunctionName->Begin'

        # The $input variable is an automatic variable that contains the objects piped to the function. In the begin block this would empty.
        foreach ($item in $input) {
            Write-Output -InputObject $input
        }
    }
    process {
        # When function takes input from the pipeline processes once each time while enumerating the instances. Will not run if the pipeline is empty
        # The process block also executes once when run outside of a pipeline
        Write-Verbose -Message 'Verb-PrivateFunctionName->Process'

        # The $input variable is an automatic variable that contains the objects piped to the function. In the process block this would contain all objects included to this point.
        foreach ($item in $input) {
            Write-Output -InputObject $input
        }

        # The $_ variable is an automatic variable that contains the current object being piped in to the function.
        Write-Output -InputObject $_

        <#
          $PSCmdlet.ShouldProcess
            Handles '-WhatIf' and '-Confirm' switches
            Can be substituted with $PSCmdlet.ShouldContinue() which will ignors $ConfirmPreference, ConfirmImpact, -Confirm, $WhatIfPreference, and -WhatIf
            $PSCmdlet.ShouldContinue() requires additional code to handle Yes to all.
          $PSCmdlet.ShouldProcess Overloads:
            $PSCmdlet.ShouldProcess([string]$Target)
                -WhatIf Output:
                    What if: Performing the operation "<function_name>" on target "$Target".
                -Confirm Output:
                    Confirm
                    Are you sure you want to perform this action?
                    Performing the operation "<function_name>" on target "$Target".
            $PSCmdlet.ShouldProcess([string]$Target, [string]$Operation)
                -WhatIf Output:
                    What if: Performing the operation "$Operation" on target "$Target".
                -Confirm Output:
                    Confirm
                    Are you sure you want to perform this action?
                    Performing the operation "$Operation" on target "$Target".
            $PSCmdlet.ShouldProcess([string]$Message, [string]$Target, [string]$Operation)
                -WhatIf Output:
                    What if: $Message
                -Confirm Output:
                    $Operation
                    $Target
            $PSCmdlet.ShouldProcess([string]$Message, [string]$Target, [string]$Operation, [ref]$reason )
                Same as above but populates the reference variable with 'None' or 'WhatIf'
        #>
        if($PSCmdlet.ShouldProcess("Performing a -WhatIf on $_","Asking for confirmation on $_","three","Should $_ be processed?")) {
            Write-Output -InputObject "Processed $_"
        }
    }
    end {
        # When function takes input from the pipeline only processes once after enumerating all instances. Will run even if the pipeline is empty
        # The end block also executes once when run outside of a pipeline
        Write-Verbose -Message 'Verb-PrivateFunctionName->End'

        # The $input variable is an automatic variable that contains the objects piped to the function. In the end block this would contain all objects that will be piped.
        foreach ($item in $input) {
            Write-Output -InputObject $input
        }
    }
}
