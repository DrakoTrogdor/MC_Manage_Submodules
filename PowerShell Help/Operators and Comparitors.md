# Comparison
## Equal/Not Equal
    -eq
    -ieq
    -ceq
    -ne
    -ine
    -cne
## Greater Than/Greater Than or Equal
    -gt
    -igt
    -cgt
    -ge
    -ige
    -cge
## Less Than/Less Than or Equal
    -lt
    -ilt
    -clt
    -le
    -ile
    -cle
## Like/Not Like - Wildcard
    -like
    -ilike
    -clike
    -notlike
    -inotlike
    -cnotlike
## Match/Not Match - Regular Expression
    -match
    -imatch
    -cmatch
    -notmatch
    -inotmatch
    -cnotmatch
## Type of/Not Type of Comparisons
    -is [<type>]
    -isnot [<type>]

# Array / Collection Operators
When comparing against a collection all items on the left are iterated through and compared against the entire value on the right.

    PS> 1,2,3,4 -eq 3
      3

    PS> 1,2,3,4 -ne 3
      1
      2
      4

    PS> 3 -eq 1,2,3,4
      False
Therefore: *It is imperative to watch for this when piped values might contain collections.*
## Contains/Not Contains Comparisons
Iterate the left side and match a value on the right side, exiting if condition is met.  

    -contains
    -icontains
    -ccontains
    -notcontains
    -inotcontains
    -cnotcontains
## In/Not In Comparisons
Iterate the right side and match a value on the left side,exiting if the condition is met.  

    -in
    -iin
    -cin
    -notin
    -inotin
    -cnotin
## Join
    -join
## Split
    -split
## Replace
    -replace
# Logical
## Not or Inverse
    -not
    !
## And
    - -and
## Or
    -or
## Exclusive Or
    -xor

# Bitwise
## Binary Not
    -bnot
## Binary And
    -band
## Binary Or
    -bor
## Binary Exclusive Or
    -bxor
## Binary Shift Left
    -shl
## Binary Shift Right
    -shr

