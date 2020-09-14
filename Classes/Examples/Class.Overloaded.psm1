# ClassParent is the parent class
class ClassParent {
    #Simple Property
    [string] $StringProperty

    #Property with Hidden attribute.  Hidden from Get-Member, tab completion or IntelliSense when outside the class definition
    hidden [string]$HiddenStringProperty = "Hidden String Property"
    
    #Property with Static attribute.  Exists even without an instantiated class
    static [string]$StaticStringProperty = "Static String Property"

    #Default Constructor
    ClassParent () {
        $this.StringProperty = "String Property"
    }
    
    #Overloaded Constructor
    ClassParent ([string] $StringValue) {
        $this.StringProperty = $StringValue
    }

    #Method with no return value
    [void] Reset() {
        $this.StringProperty = "String Property"
    }
    
    #Method with return value
    [string] getStringProperty() {
        return ("ClassParent.StringProperty: {0}" -f $this.StringProperty)
    }

    #Method with return value, accesses hidden property
    [string] getHiddenStringProperty() {
        return $this.HiddenStringProperty
    }
    
    #Method with return value, accesses static property
    static [string] getStaticStringProperty() {
        return [ClassParent]::StaticStringProperty
    }
}

# ClassChild extends ClassParent and inherits its members
class ClassChild : ClassParent {
    #Simple Property
    [int]$IntegerProperty

    #Overridden Constructor
    ClassChild(){
        $this.StringProperty = "Overridden String Property"
        $this.IntegerProperty = 20
    }
    
    #Overridden Constructor which calls base class constructor
    ClassChild([string]$StringValue, [int]$IntegerValue) : base($StringValue) {
        $this.IntegerProperty = $IntegerValue
    }
    
    #Method with return value
    [int]getIntegerProperty(){
        return $this.IntegerProperty
    }
    
    #Overridden method
    [void] Reset(){
        #Cast $this to base class in order to call the base class version of the overrideen method
        ([ClassParent]$this).Reset()
        $this.IntegerProperty = 10
    }
}

# ClassInterface extends an interface and can extend a base class at the same time
class ClassInterface : System.IComparable
{
    [int] CompareTo([object] $obj)
    {
        return 0;
    }
}

# ClassInterface extends an interface and can extend a base class at the same time
class ClassInterfaceWithBase : ClassChild, System.IComparable
{
    [int] CompareTo([object] $obj)
    {
        return 0;
    }
}
