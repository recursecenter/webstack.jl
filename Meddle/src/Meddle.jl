module Meddle

MEDDLE_VERSION = "0.0"

using Http
export Midware, 
       DefaultHeaders, 
       FileServer, 
       CookieDecoder, 
       NotFound, 
       MidwareStack, 
       handle, 
       middleware, 
       respond

immutable Midware
    handler::Function
    expects::Array
    provides::Array
end
Midware(handler::Function) = Midware(handler,[],[])

typealias MidwareStack Array{Midware,1}

# This MidWare sets the Server header on the response
# This would be good as one of the first things in your stack
# because it does not depend on info-grabbing MidWares
# and it sets a response attribute that should be used
# by later response-sending MidWares.
DefaultHeaders = Midware() do req::Request, res::Response
    res.headers["Server"] = string(res.headers["Server"], " Meddle/$MEDDLE_VERSION")
    req, res
end

# This MidWare responds to requests relative to a given directory.
# It pools the path out of the request,
# and responds if there is a file of that name that exists.
# If no such file exists, then it has no effect.
function FileServer(root::String)
    Midware() do req::Request, res::Response
        m = match(r"^/+(.*)$", req.resource)
        if m != nothing
            path = normpath(root, m.captures[1])
            if isfile(path)
                res.data = readall(path)
                return respond(req, res)
            end
        end
        req, res
    end
end

# This MidWare pulls cookies out of the request headers
# and puts them into req.state["cookies"].
# They will be a dictionary of Strings to Strings.
# This would probably come early in your stack,
# before anything that needs to use cookies.
CookieDecoder = Midware() do req::Request, res::Response
    cookies = Dict()
    if has(req.headers, "Cookie")
        for pair in split(req.headers["Cookie"],"; ")
            kv = split(pair,"=")
            cookies[kv[1]] = kv[2]
        end
    end
    req.state["cookies"] = cookies
    req, res
end

# A MidWare that always responds with a 404 error
# This is useful as the last thing in your stack
# to handle all the "no idea what to do" requests.
NotFound = Midware() do req::Request, res::Response
    respond(req, Response(404))
end

function middleware(midware...)
    Midware[typeof(m) == Function ? m() : m::Midware for m in midware]
end

# For each item in the MidwareStack,
# pass the Request and Response through them.
# Stop and retron the response when it's complete.
# This is intended to be passed into the HttpHandler constructor
function handle(stack::MidwareStack, req::Request, res::Response)
    for mid in stack
        # TODO: check these and throw useful error for bad returns
        req, res = mid.handler(req, res)
        if res.finished
            return res
        end
    end
    res
end

function respond(req::Request, res::Response)
    res.finished = true
    req, res
end

end # module Meddle
