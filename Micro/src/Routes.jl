include("Trees.jl")

typealias Params Dict{Any,Any}

abstract RouteNode

# StringNodes store all static route parts
# For example, route "/foo/bar/" is comprised of 2 StringNodes, "foo" and "bar"
#
immutable StringNode <: RouteNode
    val::String
end
# Equality & Matching for building / traversing the routing table
isequal(s1::StringNode, s2::String)     = s1.val == s2
isequal(s1::StringNode, s2::StringNode) = s1.val == s2.val
ismatch(s1::StringNode, s2::String)     = isequal(s1, s2)

# Returns the name part of a RegEx or DataType dynamic route
# Will return `foo` in `<foo::String>`
#
getname(p::String) = Base.ismatch(r"^<([^\:]*)::", p) ? match(r"^<([^\:]*)::", p).captures[1] : nothing

# DynamicNodes
#
# Route search uses `regex` to validate matches,
# then adds key `name` to `req.state[:params]` with unique value from
# resource after it is ( optionally ) processed through `convert`.
#
# DynamicNodes are used for three kinds of nodes:
#
#   - NamedParamNodes:     "/foo/<bar>" 
#            => matches    "/foo/*", adds `req.params[:bar]::String`
#
#   - RegexNodes:          "/foo/<bar::%[0-9][0-9]-[A-Z]{5}>"
#            => matches    "/foo/00-ABCDE", adds `req.params[:bar]::String`
#            => wont match "/foo/00-ABCDEF", "foo/0-ABCDE"
#
#   - DataTypeNodes:       "/foo/<bar::Int>"
#            => matches    "/foo/10", adds `req.params[:bar]::Int`
#            => wont match "/foo/10.0", "foo/abc"
#
immutable DynamicNode <: RouteNode
    name::String
    regex::Regex
    convert::Union(Nothing, Function)
end
DynamicNode(n::String, r::Regex)    = DynamicNode(n,r,nothing)
DynamicNode(p::String, c::Function) = DynamicNode(getname(p), Regex("^$(match(r":%([^>]*)>", p).captures[1])\$"), c)

# Equality & Matching for building / traversing the routing table
isequal(s1::DynamicNode, s2::String)      = Base.ismatch( s1.regex, s2 )
isequal(s1::DynamicNode, s2::DynamicNode) = s1.regex.pattern == s2.regex.pattern && s1.name == s2.name
ismatch(s1::DynamicNode, s2::String)      = isequal( s1, s2 )

# NamedParam & Regex node constructors, these are NOT types.
NamedParamNode(p::String) = DynamicNode(p[2:length(p)-1], r".*")
RegexNode(p::String)      = DynamicNode(getname(p), Regex("^$(match(r":%([^>]*)>", p).captures[1])\$"))

# All valid DataTypeNode types -- provides `regex` validator + converter.
# Should be exposed to users for extension with custom DataTypes?
#
const DataTypeNodeBuilders = (String => (Regex, Function))[ 
    "Int"   => (r"^[0-9]*$", int),
    "Float" => (r"^[0-9]*\.[0-9]*$", float),
    "String"=> (r"^.*$", string)
]
# DataType node constructor, also NOT a type.
DataTypeNode(p::String, t::String) = DynamicNode(getname(p), DataTypeNodeBuilders[t]...)

# Build the params dataset – dispatch needed for both route types.
extend_params(params::Params, v::RouteNode, p::String) = params
extend_params(params::Params, v::DynamicNode, p::String) = params[symbol(v.name)] = v.convert == nothing ? p : v.convert(p)

typealias Route (RouteNode,Union(Function,Nothing)) # ('/about', function()...)
isequal(r::Route, v) = isequal(r[1], v)
ismatch(r::Route, v) = ismatch(r[1], v)
isequal(node::RouteNode, route::Route) = isequal(node, route[1])

typealias RoutingTable Tree
RoutingTable() = RoutingTable((StringNode("/"), nothing))

ismatch(node::String, resource_chunk::String) = node == resource_chunk

# Regex matchers for determining DynamicRoute types =>
# Functions for building matching type from `part`.
#
const dynamic_route_dispatch = (Regex => Function)[
    r"^<[^:%]*::%"          => RegexNode,
    r"^<[^:>]*::[^%>]*>$"   => part -> DataTypeNode(part, match(r"^<[^:>]*::([^%>]*)>$", part).captures[1]),
    r"^<[^:>]*>$"           => NamedParamNode
]

# Run for each part of a route, builds RouteNodes.
function parse_part(part::String)
    if length(part) > 0 && Base.ismatch(r"^<[^>]*>$", part) 
        for v in dynamic_route_dispatch
            if Base.ismatch(v[1], part)
                return v[2](part)
            end
        end
        throw("$part is an invalid route part.")
    end
    StringNode(part != "" ? part : "/")
end

# `path_to_handler` returns an array of `(RouteNode,Union(Nothing,Function))`
# pairs. Each element will hold a `nothing` except for the final element which
# will contain the handler function. e.g.:
#
#   path_to_handler("/hello/world", ()->"")
#
# returns:
#
#   (StringNode("hello"),nothing)
#   (StringNode("world"),# function)
#
function path_to_handler(route::String, handler::Function)
    path = Route[(parse_part(part),nothing) for part in split(strip(route, "/"), "/")]
    path[end] = (path[end][1], handler)
    path
end

# `register!` inserts a handler into a `RoutingTable`. If it is for the root
# resource, "/", then it overwrites the route node rather than inserting a new
# one.
#
function register!(table::RoutingTable, resource::String, handler::Function)
    path = path_to_handler(resource, handler)
    # NOTE: a bit hack-ey, but fixes the root routing problem
    if resource == "/" 
        table.value = path[1]
    else
        insert!(table, path)
    end
end

# It is easiest to understand the behavior of `searchroute` by example.
# When passed an array of url/resource components, e.g. for "/hello/world" the
# array `["hello", "world"], `searchroute` returns a function, `searchpred` that
# takes a single argument.
#
# When passed matching components `searchpred` returns `false` until the final
# element of `paths` is matched, e.g.:
#
#   > searchpred = searchroute(["hello", "world"])
#   > searchpred("hello")
#   false
#   > searchpred("world")
#   true
#
# However if a non-matching component is passed to `search` it returns `PRUNE`:
#
#   > searchpred = searchroute(["hello", "world"])
#   > searchpred("goodbye")
#   PRUNE
#
# This is used to indicate that it is not neccessary to continue searching a
# given branch of the `RoutingTable`.
#
function searchroute(parts::Array, params::Params)
    function searchpred(val)
        if ismatch(val, parts[1])
            params = extend_params(params, val[1], parts[1])
            if length(parts) == 1
                true
            else
                parts = parts[2:end]; false
            end
        else
            PRUNE
        end
    end
end

# `match_route_handler` looks up a handler in `table` when given a route to a
# resource array form (e.g. "/hello/world" would be `["hello", "world"]`). If
# no match is found then it returns `nothing`.
#
function match_route_handler(table::RoutingTable, parts::Array)
    params = Params()
    result = search(table, searchroute(parts, params))
    ((result != nothing ? result[2] : nothing), params)
end
