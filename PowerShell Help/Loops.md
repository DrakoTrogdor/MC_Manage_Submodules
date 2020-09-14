## For Loop
    for (<init>; <condition>; <repeat>) { <script block> }
    for (;;) { <script block> }
## ForEach Loop
    foreach ($item in $collection) { $item }
## ForEach-Object
    $collection | ForEach-Object { $_ }
    ForEach-Object InputObject $collection { $_ }
    ForEach-Object -Begin { <script block> } -Process { <script block>[] } -End { <script block> }
    ForEach-Object -InputObject $collection -Parallel { <script block> }
## While Loop
    while ( <condition> ) { <script block> }
## Do While Loop
    do { <script block> } while (<condition>)
## Do Until Loop
    do { <script block> } until (<condition>)
## Break
## Continue
## Return