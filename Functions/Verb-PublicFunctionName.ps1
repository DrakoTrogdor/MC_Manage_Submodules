<#
.SYNOPSIS
    [Brief description of the function or script.  Onlu used once in each topic.]
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
        [Major].[Minor]     -   [Year]-[Month]-[Day]  -   [Description]
    TODO:
        [List of TODOs]
.LINK
    https://subdomain.domain.tld/directory/file.ext
.COMPONENT
    The technology or feature that the function or script uses, or to which it is related. This content appears when the Get-Help command includes the Component parameter of Get-Help.
.FUNCTIONALITY
    [Verb-PublicFunctionName] The intended use of the function. This content appears when the Get-Help command includes the Functionality parameter of Get-Help.
#>
function Verb-PublicFunctionName {
    [CmdletBinding(DefaultParameterSetName = 'Parameter Set 1',
        PositionalBinding = $false,
        HelpUri = 'http://www.microsoft.com/',
        ConfirmImpact = 'Medium')]
    Param (
        # Parameter1 Description
        [Parameter(Mandatory = $true,
            Position = 0,
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = 'Parameter Set 1')]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [string]$Parameter1,

        # Parameter2 Description
        [Parameter(Mandatory = $true,
            Position = 1,
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = 'Parameter Set 1')]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [string]$Parameter2
    )
    begin {
        #When function takes input from the pipeline only processes once before enumerating any instances.
        Write-Verbose -Message 'Verb-PublicFunctionName->Begin'
    }
    process {
        #When function takes input from the pipeline processes once each time while enumerating the instances.
        foreach ($pkg in $pkgs) {
            Write-Verbose -Message 'Verb-PublicFunctionName->Process'
        }
    }
    end {
        #When function takes input from the pipeline only processes once after enumerating all instances.
        Write-Verbose -Message 'Verb-PublicFunctionName->End'
    }
}
