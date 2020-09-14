class ClassSingleton {
    # Single Instance Property
    [string] $SingleInstanceName

    # Static property that does not change between instances
    # And used to check if an instance is already created
    static [ClassSingleton] $StaticInstance

    # Static method to get the instance
    static [ClassSingleton] GetInstance() {
        # if our StaticInstance variable is still set to $null
        # then we create a new instance
        if ($null -eq [ClassSingleton]::StaticInstance) {
            [ClassSingleton]::StaticInstance = [ClassSingleton]::new()
        }
        # if the instance already exists or not, we return it
        return [ClassSingleton]::StaticInstance
    }
}
