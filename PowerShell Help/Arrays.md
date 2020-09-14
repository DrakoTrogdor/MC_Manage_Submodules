# Arrays

## Declaring Arrays
### Basic Array - Empty
    $array = @()

### Basic Array - Initialized
    $array = @(<value>, <value>, <value>)
    $array = @(
        <value>,
        <value>,
        <value>
    )
    $array = <value>, <value>, <value>

### Array from Output
    $array = for ($counter = 0; $counter -lt 10; $counter++) { "Value: $counter" }

### Array from Script Block
Without invoking the script block the array will BE the script block.  

    $array = & { for ($counter = 0; $counter -lt 10; $counter++) { "Value: $counter" } }

### Array from Sequence Operator
    $array = 1..10 # Will set the array to the values from 1 to 10
    $array = 10..1 # Will set the array to the values from 10 to 1

---

## Accessing Array Elements
### Index
Returns values from the array using a 0 based index  

    $array = 'Zero','One','Two','Three'
    $array[0] # Will return 'Zero'
### Negative Index
    $array = 'Zero','One','Two','Three'
    $array[-1] # Will return 'Three'
### Index as an Array
    $array = 'Zero','One','Two','Three'
    $array[0,3,1,1] # Will return a new array containing 'Zero', 'Three', 'One', 'One'
### Index as a Sequence
    $array = 'Zero','One','Two','Three'
    $array[1..3] # Will return a new array containing 'One', 'Two', 'Three'
    $array[3..1] # Will return a new array containing 'Three', 'Two', 'One'
### Index as a Sequence containing a negative number
    $array = 'Zero','One','Two','Three'
    $array[-1..0] # Will return a new array containing 'Three','Zero' (Last and First)
    $array[0..-1] # Will return a new array containing 'Zero','Three' (First and Last)
    $array[-1..-4] # Will return a new array containing 'Three','Two','One','Zero'
### Out of Bounds
Indexes that are out of bounds (above the maximum index or below 0) will return $null  

    $array = 'Zero','One','Two','Three'
    $null -eq $array[1000] # Will throw an array out of range exception
### $null Array Indexes
    $array = $null
    $array[0] # Will throw an exception
### Updating Array Elements
    $array = 'Zero','One','Too','Three'
    $array[2] = 'Two' # Will set the third item to 'Two'
    $array[4] = 'Four' # Will throw an array out of range exception

---

## Iteration
### Pipeline
    $array = 'Zero','One','Two','Three'
    $array | ForEach-Object { Write-Output $PSItem }
### ForEach Loop
    $array = 'Zero','One','Two','Three'
    foreach ($item in $array) {
        Write-Output $item
    }

### ForEach Method
    $array = 'Zero','One','Two','Three'
    $array.foreach{ Write-Output $PSItem }
### For Loop
    $array = 'Zero','One','Two','Three'
    for ( $index = 0; $index -lt $array.count; $index++) {
        Write-Output $array[$index]
    }
### Switch Loop
    $array = 'Zero','One','Two','Three'
    switch($array) {
        'Zero'  { Write-Output 0 }
        'One'   { Write-Output 1 }
        'Two'   { Write-Output 2 }
        'Three' { Write-Output 3 }
    }

---

## Arrays of Objects
### Declaration
    $array = @(
        [PSCustomObject]@{ Key1='Value1';Key2='Value2' }
        [PSCustomObject]@{ Key1='Value3';Key2='Value4' }
    )
### Accessing Object Properties for one Array Element 
    $array[0].Key1 # Will return 'Value1'
### Accessing Object Properties for all Array Elements
All of the following methods will produce the same results  

    $array | ForEach-Object { $_.Key1 }
    $array | Select-Object -ExpandProperty Key1 
    $array.Key1
### Filtering an Array of Objects based on a Property
All of the following methods will produce the same results  

    $array | Where-Object { $_.Key1  -eq 'Value3' }
    $array | Where Key1 -eq 'Value3'
    $array.Where({$_.Key1 -eq 'Value3'})

## Properties
### Count
Will return the number of elements in the array  

    $array = 'Zero','One','Two','Three'
    $array.count # Will return 4
---

## Methods
### ForEach
### Where
A method that allows filtering the array based on a script block.

    $array = @(
        [PSCustomObject]@{ Key1='Value1';Key2='Value2' }
        [PSCustomObject]@{ Key1='Value3';Key2='Value4' }
    )
    $array.Where({$_.Key1 -eq 'Value3'})

## Operators
### -join
Joins elements of an array into a continuous string

    $array = @(1,2,3,4)
    $array -join '-' # Returns '1-2-3-4'
    $array -join $null # Returns '1234'
    -join $array # Returns '1234'
### -split
### -replace
### -contains
### -in
