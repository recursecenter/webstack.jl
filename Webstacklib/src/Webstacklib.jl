module Webstacklib
    export @interface

    macro interface(iexp::Expr)
        iexp.head == :type || throw("@interface macro expects a type expression, got $(exp.head)")
        name = iexp.args[2]
        oexp = :(begin abstract $(esc(name)) end)
        for exp in iexp.args[3].args
            if exp.head == :call
                strexp = string(exp)[3:end-1]
                err = string("method ", strexp, " for interface ", name, " not implemented.")
                fun = Expr(:function, esc(exp), quote
                    throw($err)
                end)
                push!( oexp.args, fun )
            end
        end
        oexp
    end
end
