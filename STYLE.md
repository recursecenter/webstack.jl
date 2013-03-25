```.jl
module FooBar

using Lib
export Foo,
       do_bar

# Foo is a type, it has fields and multiple constructors
type Foo
    name::String
    label::String
    body::String
    Foo(name, label, body) = new(name, label, body)
end
Foo(n::String, l::String) = Foo(n, l, "")
Foo(n::String)            = Foo(n, "")

# `do_bar` does some stuff
#
# It accepts some arguments and this is a really good
# multiline explanation of those arguments.
#
#       do_bar(Foo()) # => something
#
function do_bar(f::Foo)
    bar = string(f.label, f.body)   # inline comments

    if bar == "baz buzz"            # should be in a column
        for c in bar
            println(c)
        end
    end

    bar
end

end # module FooBar
```