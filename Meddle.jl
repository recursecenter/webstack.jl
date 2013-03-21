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

DefaultHeaders = Midware() do req::Request, res::Response
    res.headers["Server"] = string(res.headers["Server"], " Meddle/$MEDDLE_VERSION")
    req, res
end

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

NotFound = Midware() do req::Request, res::Response
    respond(req, Response(404))
end

function middleware(midware...)
    Midware[typeof(m) == Function ? m() : m::Midware for m in midware]
end

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
