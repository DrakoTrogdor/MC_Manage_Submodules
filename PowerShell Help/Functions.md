# Functions

## Function Syntax:
    [function|filter] [<scope:>]<name> [([type]$parameter1[,[type]$parameter2])]
    {
        param ([type]$parameter1 [,[type]$parameter2])
        dynamicparam {<statement list>}
        begin {<statement list>}
        process {<statement list>}
        end {<statement list>}
    }

## Function Names:
Functions names should consist of a verb-noun pair in which the verb
identifies the action that the function performs and the noun identifies
the item on which the cmdlet performs its action.  
Functions should use the standard verbs which can be listed using the "Get-Verbs" cmdlet.  

## Function vs Filter:
A function can be described using either the 'function' or 'filter' definitions.  
A filter type function differs from a normal function as it is considered to only have a 'process' block and runs on each object in the pipeline.  

## Scope:
Function scope is not required and will be in the 'script:' scope by default.  
Variables within a scope can be listed by using the "Get-Variable -Scope \<scope\>" cmdlet.  

### Scopes:
- global
- local
- script
- private
- [numbered] Scope '0' is the current or local level, '1' is the parent scope, etc...

## Providers, Drives, & Items:
Functions will be added to the 'function:' provider/drive by default.  
Providers can be listed using the "Get-PSProvider" cmdlet.  
Drives within a provider can be listed by using the "Get-PSDrive" cmdlet.  
Items within a drive can be listed by using the "Get-ChildItem \<provider\>:" cmdlet.  

### Providers with Drives:
- **Alias** - *Cmdlet aliases*
    - Alias
- **Certificate** - *Certificate store*
    - Cert
- **Environment** - *Environmental variables*
    - Env
- **Function** - *Loaded functions*
    - Function
- **Variable** - *Loaded Variables*
    - Variable
- **Credentials** - *Credentials*
    - WSMan
- **FileSystem** - *The file system drives*
    - [Letter]
    - Temp - *The 'temp' folder*
- **Registry** - *Registry hives*
    - HKLM - *Local Machine Hive*
    - HKCU - *Current User Hive*

### Provider, Drive, Item, and ChildItem Cmdlets
- **Provder**
    - Get-PSProvider

- **Drive**
    - Get-PSDrive
    - New-PSDrive
    - Remove-PSDrive

- **ChildItem**
    - Get-ChildItem

- **Items**
    - Clear-Item
    - Copy-Item
    - Get-Item
    - Invoke-Item
    - Move-Item
    - New-Item
    - Remove-Item
    - Rename-Item
    - Set-Item

- **Properties**
    - Clear-ItemProperty
    - Copy-ItemProperty
    - Get-ItemProperty
    - Move-ItemProperty
    - New-ItemProperty
    - Remove-ItemProperty
    - Rename-ItemProperty
    - Set-ItemProperty

- **Content**
    - Add-Content
    - Clear-Content
    - Get-Content
    - Set-Content

- **Location**
    - Get-Location
    - Pop-Location
    - Push-Location
    - Set-Location

- **Path**  
    - Join-Path
    - Convert-Path
    - Split-Path
    - Resolve-Path
    - Test-Path

    Path Syntax:

        [<provider>::]<drive>:[\<container>[\<subcontainer>...]]\<item>

## Advanced Functions:
- Advanced functions use the CmdletBinding attribute to identify them as functions tha act similar to .Net Framework compiled cmdlets.  
  
### CmdletBinding Attribute:
- An attribute added to a function in order to to allow advanced functions.  
  
    CmdletBinding Syntax:  

        [CmdletBinding([<attribute> = <value>][,<attribute> = <value>][,...])]
  
    CmdletBinding Attributes:  
- **ConfirmImpact** *[string]*  
    Specifies at which level of the $ConfirmPreference variable that the ShouldProcess method displays a confirmation prompt.  
    Will execute the function as if it was called with '-Confirm' switch if it set to a higher level than the $ConfirmPreference variable.
    By default ConfirmImpact -eq 'Medium' and $ConfirmPreference -eq 'High'.  
    Values:
    - High
    - Medium *(Default)*
    - Low
    - None

- **DefaultParameterSetName** *[boolean]*  
    Specifies the default parameter set to use when one cannot be determined  

- **HelpURI** *[string]*  
    URI for the help topic for this function. Must start with http or https  

- **SupportsPaging** *[boolean]*  
    Adds the First, Skip and IncludeTotalCount parameters to the function  
    - First - Getsonly the first 'n' objects.
    - Skip = Ignores the first 'n' objects then returns the remaining.
    - IncludeTotalCount - Reports the number of objects in the dataset, followed by the objects.  

            function Get-Numbers {
                [CmdletBinding(SupportsPaging = $true)]
                param()
                $FirstNumber = [Math]::Min($PSCmdlet.PagingParameters.Skip, 100)
                $LastNumber = [Math]::Min($PSCmdlet.PagingParameters.First +
                $FirstNumber - 1, 100)
                if ($PSCmdlet.PagingParameters.IncludeTotalCount) {
                    $TotalCountAccuracy = 1.0
                    $TotalCount = $PSCmdlet.PagingParameters.NewTotalCount(100,
                    $TotalCountAccuracy)
                    Write-Output $TotalCount
                }
                $FirstNumber .. $LastNumber | Write-Output
            }

- **SupportsShouldProcess** *[boolean]*  
    Adds Confirm and WhatIf switch parameters to the function and allows the  implementation of the $PSCmdlet.ShouldProcess() method in the process block.  
  

- **PositionalBinding** *[boolean]*  
    Determines if the function's parameters are positional by default  
    The default value is $true.  

### OutputType Attribute
- An attribute reports the type of object a function will return.  
OutputType is dependent on CmdletBinding.
This is only reported to the System.Management.Automation.FunctionInfo object that the Get-Command cmdlet returns
Multiple OutputType attributes may be used with different ParameterSets
  
    OutputType Syntax:  

        [OutputType([<type>]|"<type_string>"[,[<type>]|"<type_string>"][,...], ParameterSetName="<name>[,<name>][,...]")]
  
### Parameters
- **Static Parametrs**  
    Parameters that are always available in the function.  
  
    Parameter Syntax:  

        param (
            [Paramter([<attribute> = <value>][,<attribute> = <value>][,...])]
            [[<validation_attribute>([<value>])]]
            [[<validation_attribute>([<value>])]...]
            [type]$ParameterName
        )  

    Parameter Attributes:  
    - **Mandatory** *[boolean]*  
    Is the argument mandatory?  
    e.g. Mandatory = $true  

    - **Position** *[integer]*  
    The position of the argument as it was called.  
    e.g. Position = 0  

    - **ParameterSetName** *[string]*  
    In order to add to more than one set, add multiple parameter blocks.  
    Parameters not in a set belong to the all parameters set.  
    e.g. ParameterSetName = "Parameter Set 1"  

    - **ValueFromPipeline** *[boolean]*  
    Accepts the entire input object from the pipeline  
    e.g. ValueFromPipeline = $true  

    - **ValueFromPipelineByPropertyName** *[boolean]*  
    Accepts a value from the input object's corresponding property from the pipeline  
    e.g. ValueFromPipelineByPropertyName = $true  

    - **ValueFromRemainingArguments** *[boolean]*  
    Accepts all remaining arguments that are not assigned to other function parameters.  
    e.g. ValueFromRemainingArguments = $true  

    - **HelpMessage** *[string]*  
    A brief description that is prompted when the parameter value is missing.  
    e.g. HelpMessage = "Parameter Help Message."  

    Alias Attribute:
    - **Alias** *[string[]]*  
    Establishes an alternate name for the parameter.  
    e.g. Alias("name1","name2")
  
    Validation Attributes:
    - **AllowNull** *[switch]*  
    Allows a mandatory parameter to be $null  
    e.g. AllowNull()

    - **ValidateNotNull** *[switch]*  
    Validates that a non-mandatory parameter is not $null  

    - **AllowEmptyString** *[swtich]*  
    Allows a mandatory parameter to be an empty string "".  

    - **AllowEmptyCollection** *[switch]*  
    Allows a mandatory parameter to be and empty collection @().  

    - **ValidateNotNullOrEmpty** *[switch]*  
    Validates that a non-mandatory parameter is not $null or an empty string "" or array @()  

    - **ValidateCount** *[integer[]]*  
    The minimum and maximum "(x,y)" number of parameters values to accept.  

    - **ValidateLength** *[integer[]]*  
    The minimum and maximum "(x,y)" number of characters in a parameter value to accept.  

    - **ValidatePattern** *[string]*  
    Validates the parameter value based on a regular expression.  
    e.g. ValidatePattern ("[0-9][0-9][0-9][a-zA-Z]")

    - **ValidateRange** *[integer[]]*  
    Validates a parameter value that lies within the range of numbers  
    e.g. ValidateRange (0,10)  

    - **ValidateRange** *[[string]ValidateRangeKind]*  
    Validates a parameter value based on:
        - Positive - Greater than zero.
        - Negative - Less than zero.
        - Not Positive - Less than or equal to zero.
        - Not Negative - Greater than or equal to zero.

        e.g. ValidateRange ("Positive")  

    - **ValidateScript** *[script block]*  
    Validates a parameter value based on the outcome of the script block $false or an error will throw an exception  
    e.g. ValidateScript ({$_ -lt 0})  

    - **ValidateSet** *[array]*  
    Validates a parameter value from a set of values supplied.  
    e.g. ValidateSet ('one','two','three')..

    - **ValidateSet** *[class]*  
    Validates the parameter value using a class to dynamically generate the ValidateSet at runtime.  
    e.g. ValidateSet ([ExampleClass])  

            class ExampleClass : System.Management.Automation.IValidateSetValuesGenerator {
                [string[]] GetValidValues () { return [string[]]@('one','two','three') }
            }

    - **ValidateDrive** *[string[]]*  
    Validates that the parameter is a valid path type value for the drive(s) listed. Does not validate the path itself.  
    e.g. ValidateDrive ("C", "D", "Function", "Variable")  

    - **ValidateUserDrive** *[switch]*  
    Validates that the parameter is a valid path type value for the user drive listed. Just Enough Administration (JEA)  

- **Switch Parametrs**  
    A parameters that is equal to false if not present or called as -Name:$false or is equal to true if present or called as -Name:$true
  
    Parameter Syntax:  

        param (
            [switch]$ParameterName
        )
- **Dynamic Parametrs**  
    Parameters that are created dynamically based on particular conditions such as location called from or the value of other parameters.  

    Parameter Syntax:  

        dynamicparam {
            if (<condition>) {
                $attributes = New-Object -Type `
                    System.Management.Automation.ParameterAttribute
                $attributes.ParameterSetName = "<parameter_set_name>"
                $attributes.Mandatory = <boolean>

                $attributesCollection = New-Object -Type `
                    System.Collections.ObjectModel.Collection[System.Attribute]
                $attributesColleciton.Add($attribute)

                $dynamicParameter1 = New-Object -Type `
                    System.Management.Automation.RuntimeDefinedParameters(
                    "DP1",
                    [Int32],
                    $attributeCollection
                )

                $paramaterDictionary = New-Object -Type `
                System.Management.Automation.RuntimeDefinedParameterDictionary
                $paramaterDictionary.Add("DP1", $dynamicParameter1)

                return $paramaterDictionary
            }

### Advanced Methods
- **$PSCmdlet.WriteCommandDetail**  
    Writes to the pipeline execution log

- **$PSCmdlet.WriteDebug**  
    Writes to the debug pipe. Will be displayed if the '-Debug' switch is set. Can be configured globally with the $DebugPreference variable.

- **$PSCmdlet.WriteError**  
    Writes to the error pipe

- **$PSCmdlet.WriteObject**  
    Writes one or more objects to the output pipe (writes as a single object, unless the parameter enumerateCollection is set to $true)

- **$PSCmdlet.WriteProgress**  
    Displays progress information

- **$PSCmdlet.WriteVerbose**  
    Writes to the verbose pipe. Will be displayed if the '-Verbose' switch is set. Can be configured globally with the $VerbosePreference variable.

- **$PSCmdlet.WriteInformation**  
    Writes to the information pipe. Can be configured globally with the $InformationPreference variable

- **$PSCmdlet.WriteWarning**  
    Writes to the warning pipe. Can be configured globally with the $WarningPreference variable

- **$PSCmdlet.ShouldProcess**  
    Handles '-WhatIf' and '-Confirm' switches  
  
    Overloads:  
    - **$PSCmdlet.ShouldProcess ([string]$Target)**  
        -WhatIf Output:

            What if: Performing the operation "<function_name>" on target "$Target".

        -Confirm Output:

            Confirm
            Are you sure you want to perform this action?
            Performing the operation "<function_name>" on target "$Target".

    - **$PSCmdlet.ShouldProcess ([string]$Target, [string]$Operation)**  
        -WhatIf Output:

            What if: Performing the operation "$Operation" on target "$Target".

        -Confirm Output:

            Confirm
            Are you sure you want to perform this action?
            Performing the operation "$Operation" on target "$Target".

    - **$PSCmdlet.ShouldProcess ([string]$Message, [string]$Target, [string]$Operation)**  
        -WhatIf Output:

            What if: $Message

        -Confirm Output:

            $Operation
            $Target

    - **$PSCmdlet.ShouldProcess ([string]$Message, [string]$Target, [string]$Operation, [ref]$reason)**  
        Same as above but populates the reference variable with 'None' or 'WhatIf'

- **$PSCmdlet.ShouldContinue**  
    Can be used as a substitute for $PSCmdlet.ShouldProcess() but will ignore $ConfirmPreference, ConfirmImpact, -Confirm, $WhatIfPreference, and -WhatIf  
    Requires additional code to handle Yes to all.

*Markdown Guide at:*  
*https://www.markdownguide.org/basic-syntax/*