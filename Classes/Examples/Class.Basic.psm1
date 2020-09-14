<#
    Base PowerShell 5 Class
    Create a new instance using [ClassName]::new("OverloadedParameterValue(s)")
    Call static methods using [ClassName]::staticMethod()
#>

class ClassBasic {
    # Public Properties are exposed and can be {get; set;}
    # Public Properties are Instance type properties
    [String] $StringProperty
    [Int32] $IntegerPropery

    # Static Properties are Class type properties
    # Static properties are the same across all instances of the Class
    static [String] $StaticProperty = "This is a static property of the class"

    # Hidden Properties are typically hidden
    # but can be exposed in PowerShell Classes
    hidden [String] $HiddenProperty

    ClassBasic() {
        # Empty Class1 Constructor
    }

    # Overloaded Constructor
    ClassBasic ([String] $StringValue, [int32] $IntegerValue) {
        # $this is used to access or modify the current instance of the ClassBasic class
        $this.StringProperty = $StringValue
        $this.IntegerPropery = $IntegerValue
    }

    # Overloaded Constructor
    ClassBasic([String] $StringValue) {
        # Set StringProperty for ClassBasic to the passed in $StringValue value
        $this.StringProperty = $StringValue
    }

    # Instance Method
    # An Instance Method will be created for every instance of the Class
    [String] getStringProperty() {
        return $this.StringProperty
    }

    # Static Method
    # A static method will be used across all instance of the Class
    static [String] getStaticProperty() {
        return [ClassBasic]::StaticProperty
    }

    # A VOID method will not return any information
    [void] ExecuteVoidMethod() {
        $this.IntegerPropery += 1
    }
}
