# if, elseif, else statements
## Syntax  
    if (<condition>) { <script_block> }
    elseif (<condition>) { <script_block> }
    else { <script_block> }

## Input & Input Data Types
### Arrays
A check with an array on the left side of the test will iterate through all values until either the condition is true or it has processed all values:

    if (@(<value_1>,<value_2>,<value_3>) -eq <value>) { <return_1> } else { <return_2> }
    <return_1> if <value> is in the array
    <return_2> if <value> is not found in the array

### Checking for $null  
Always check for $null with $null on the left side in order to avoid iterrating a collection and returning an unwanted result:

      if ($null -eq <value>)

### Variable assignment
Variables can be assigned in the condition test and they will be piped into the script block.

      if (($x = <value>) -eq <value>) { $x } # Returns the first <value> or nothing
      if ($x = <value> -eq <value>) { $x } # Returns $true or nothing
      if ($x = <function>) { $x } # Returns the output from the function or nothing.

## Output
### Pipeline  
Values can be placed directly on the pipeline from each script block and assigned to a variable.

    $variable = if (<condition>) { <value> } else { <value> }
    $array = @('one', 'two'; if (<condition>) { 'three' } else { 'four' })

## Miscellaneous
### Simplification
Long conditional statements can be broken up onto different lines using line continuation:

    if (
        $null -ne <value> -and
        <value> -eq <value> -or
        <value> -match <value>
    ) {
        <script_block>
    }

### Pre-calculating results
Results can be calculated and stored in a variable before the conditional test:

    $variable = $null -ne <value> -and
        <value> -eq <value> -or
        <value> -match <value>
    if ($variable) {
        <script_block>
    }

# switch statements
## Syntax:

    $variable = <value>
    switch ($variable) {
        <value> { <script_block> }
        <value> { <script_block> }
        default { <script_block> }
    }

## Input & Input Data Types
### Strings  
String values without spaces can be tested without quotes:  

      switch ($variable) {
          <value>   { <script_block> }
          "<value>" { <script_block> }
          default   { <script_block> }
      }

### Arrays  
Using a switch statement on an array will iterate through each element of the array:  

      $variable = @(<value>,<value>,<value>)
      switch ($variable) {
          <value> { <script_block> }
          <value> { <script_block> }
          default { <script_block> }
      }

### Enums  
Values can be compared to enums, either weakly or strongly typed. Parentheses are required for the stronly typed enum in order to avoid treating it as a literal string:

      enum ValueTypes {
          Type1
          Type2
          Type3
      }
      $result = switch ($variable) {
          Type1                 { <script_block> }
          ([ValueTypes]::Type2) { <script_block> }
          default               { <script_block> }
      }

### $null  
Matches can be compared to $null successfully

      switch ($variable) {
          $null { "Value is null" }
          default { "Value is not null" }
      }

### ScriptBlock Conditions  
Matches can be performed against a script block. To make differentiating condtion script blocks from result script blocks it is recommended to place the condtion in parentheses. This can be used instead of an if statement if the result must hit multiple conditions:

    switch ($variable) {
        {$PSItem <test> <value>}   { <script_block> }
        ({$PSItem <test> <value>}) { <script_block> }
        default                    { <script_block> }
    }

### Constant Expression  
Setting the value to a constant expression the conditions can be set to different variables in order to test each one:

    $variable_1 = $false
    $variable_2 = $true
    $variable_3 = $true
    switch ( $true )
    {
        $variable_1 { 'variable 1 is true' }
        $variable_2 { 'variable 2 is true' }
        $variable_3 { 'variable 3 is true' }
    }

## Output
### Pipeline  
Values can be placed directly on the pipeline from each script block and assigned to a variable:

      $variable = <value>
      $result = switch ($variable) {
          <value> { <script_block> }
          <value> { <script_block> }
          default { <script_block> }
      }

### $PSItem / $_  
$PSItem or $_ can be used to reference the current item that was processed

      switch ($variable) {
          <value> { "$PSItem" }
          <value> { "$_" }
          default { <script_block> }
      }

## Parameters  
Switch statements have access to the following parameters:
### -CaseSensitive  
Matches the value to the condition only if the case is the same.  

    switch -CaseSensitive ($variable) {
        'value' { <script_block> }
        'VALUE' { <script_block> }
        default { <script_block> }
    }

### -Wildcard  
Uses wildcard matching (* and ?) to compare the value to the condition.  

    switch -Wildcard ($variable) {
        '<value>*' { <script_block> }
        default { <script_block> }
    }

### -Regex  
Uses regular expressions to compare the value to the condition.  

    switch -Regex ($variable) {
        '^<value>.*$' { <script_block> }
        default { <script_block> }
    }

### -File  
Processes a file as if each line were an element of an array.  

    switch -File ($variable) {
        <value> { <script_block> }
        default { <script_block> }
    }

### Combining Parameters  
Parameters can be combined, except -wildcard and -regex due to conflicting search methods:  

    switch -CaseSensitive -Wildcard -File ($variable) {
        'value*' { <script_block> }
        'VALUE*' { <script_block> }
        default { <script_block> }
    }

## Multiple Matches  
If a value matches multiple conditions then the switch statement will return all matches:

    switch -Wildcard ($variable) {
        'value' { <script_block> }
        'value* { <script_block> }
        default { <script_block> }
    }
  
### Continue  
Using the continue command the switch statement either iterates to the next input value or exits if there are no more values on the pipeline. break/continue labels are supported for nested switch statements. execution will be taken to :

    switch ($variable) {
    <value> { <script_block>; continue }
    <value> { <script_block>; continue }
    default { <script_block>; continue }
    }

### Break  
Using the break command the switch statement exits even if there are more values on the pipeline. For single value pipelines continue and break work identiaclly:

    switch ($variable) {
    <value> { <script_block>; break }
    <value> { <script_block>; break }
    default { <script_block>; break }
    }

### Labels  
Break/continue labels are supported for nested switch statements. Execution will be returned to the labelled script block:

    :label1 foreach($item in $collection) {
        :label2 switch ($variable) {
        <value> { <script_block>; break label1 }
        <value> { <script_block>; continue label2 }
        default { <script_block>; continue label1 }
        }
    }


## Automatic Variables  
### $matches  
Using the -regex parameter populates the $matches variable which can then be used to pull multiple items out of a string:  

    switch -regex ($variable) {
        '(?<value1>\d+\.\d+\.\d+)' { "value 1: $($matches.value1)" }
        '(?<value2>\d+\+\d+\+\d+)' { "value 2: $($matches.value2)" }
    }

### $switch  
An enumerator called $switch is created while the switch is processing. This can be used the alter the behaviour of the switch statement:  

    $variable = 1, 2, 3, 4
    switch($variable) {
        1 { [void]$switch.MoveNext(); $switch.Current }
        3 { [void]$switch.MoveNext(); $switch.Current }
    }