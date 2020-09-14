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
    PS> Verb-PublicFunctionName -Parameter1 'Value' -Parameter2 'Value'
    [Description of the example.]
.INPUTS
    The Microsoft .NET Framework types of objects that can be piped to the function or script. You can also include a description of the input objects.
.OUTPUTS
    The .NET Framework type of the objects that the cmdlet returns. You can also include a description of the returned objects.
.NOTES
    Copyright Notice
    Name:       [Verb-PublicFunctionName]
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
    about_Functions_Advanced_Parameters
.LINK
    about_Functions_CmdletBinding_Attribute
.LINK
    about_Functions_OutputTypeAttribute
.LINK
    about_Automatic_Variables
.LINK
    about_Comment_Based_Help
.LINK
    about_Parameters
.LINK
    about_Profiles
.LINK
    about_Scopes
.LINK
    about_Script_Blocks
.LINK
    about_Function_provider
.LINK
    Get-Verb

.COMPONENT
    The technology or feature that the function or script uses, or to which it is related. This content appears when the Get-Help command includes the Component parameter of Get-Help.
.FUNCTIONALITY
    [Verb-PublicFunctionName] The intended use of the function. This content appears when the Get-Help command includes the Functionality parameter of Get-Help.
#>
function Verb-PublicFunctionName {
    [CmdletBinding(
        ConfirmImpact = 'Medium',
        DefaultParameterSetName = 'Parameter Set 1',
        HelpUri = 'http://www.sulltec.com/',
        PositionalBinding = $true,
        SupportsPaging = $false,
        SupportsShouldProcess = $true
    )]
    [OutputType(
        [object],
        [string],
        ParameterSetName="Parameter Set 1"
    )]
    param (
        # Parameter1 Description
        [Parameter(
            Mandatory = $true,
            Position = 0,
            ParameterSetName = 'Parameter Set 1',
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage = "Parameter 1 Help Message"
        )]
        [Alias("parm1","p1")]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [ValidateLength(1,25)]
        [ValidatePattern('^[a-zA-Z0-9]$')]
        [string]$Parameter1,

        # Parameter2 Description
        [Parameter(
            Mandatory = $false,
            Position = 1,
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = 'Parameter Set 1'
        )]
        [PSDefaultValue(Help = 'Parameter2 Default Value')]
        [string]$Parameter2 = 'Parameter2 Default Value',

        # Parameter3 Description
        [Parameter(
            Mandatory = $false,
            Position = 2,
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = 'Parameter Set 1'
        )]
        [ValidateRange('Positive')]
        [int]$Parameter3 = 'Parameter2 Default Value',

        # Parameter4 Description
        [Parameter(
            Mandatory = $false,
            Position = 3,
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = 'Parameter Set 1'
        )]
        [switch]$Parameter4

    )
    begin {
        # When function takes input from the pipeline only processes once before enumerating any instances. Will run even if the pipeline is empty
        # The begin block also executes once when run outside of a pipeline
        Write-Verbose -Message 'Verb-PublicFunctionName->Begin'

        # The $input variable is an automatic variable that contains the objects piped to the function. In the begin block this would empty.
        foreach ($item in $input) {
            Write-Output -InputObject $input
        }
    }
    process {
        # When function takes input from the pipeline processes once each time while enumerating the instances. Will not run if the pipeline is empty
        # The process block also executes once when run outside of a pipeline
        Write-Verbose -Message 'Verb-PublicFunctionName->Process'

        # The $input variable is an automatic variable that contains the objects piped to the function. In the process block this would contain all objects included to this point.
        foreach ($item in $input) {
            Write-Output -InputObject $input
        }

        # The $_ variable is an automatic variable that contains the current object being piped in to the function.
        Write-Output -InputObject $_

        # Perform -WhatIf and -Confirm processing based on SupportsShouldProcess
        if($PSCmdlet.ShouldProcess("Performing a -WhatIf on $_","Asking for confirmation on $_","three","Should $_ be processed?")) {
            Write-Output -InputObject "Processed $_"
        }
    }
    end {
        # When function takes input from the pipeline only processes once after enumerating all instances. Will run even if the pipeline is empty
        # The end block also executes once when run outside of a pipeline
        Write-Verbose -Message 'Verb-PublicFunctionName->End'

        # The $input variable is an automatic variable that contains the objects piped to the function. In the end block this would contain all objects that will be piped.
        foreach ($item in $input) {
            Write-Output -InputObject $input
        }
    }
}
