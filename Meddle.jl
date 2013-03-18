module Meddle

    MEDDLE_VERSION = "0.0"

    using Http

    immutable Midware
        handler::Function
        expects::Array
        provides::Array
    end

    Midware(handler::Function) = Midware(handler,[],[])

    function DefaultHeaders()
        Midware() do req::Request, res::Response
            res.headers["Server"] = string(res.headers["Server"], " Meddle/$MEDDLE_VERSION")
            req, res
        end
    end

    function FileServer( root::String )
        Midware() do req::Request, res::Response
            m = match(r"^/+(.*)$", req.resource)
            if m != nothing
                path = normpath(root, m.captures[1])
                if isfile(path)
                    res.data = readall(path)
                    return respond( req, res )
                end
            end
            req, res
        end
    end

    function CookieDecoder() 
        Midware() do req::Request, res::Response
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
    end

    function NotFound()
        Midware() do req::Request, res::Response
            respond( req, Response(404) )
        end
    end

    typealias MidwareStack Array

    function handle(stack::MidwareStack, req::Request, res::Response)
        for mid in stack
            println("Running: ", mid.handler, " with ", req.state)
            # TODO: check these and throw useful error for bad returns
            req, res = mid.handler( req, res )
            if res.finished
                return res
                break
            end
        end
        res
    end

    function respond( req::Request, res::Response )
        res.finished = true
        req, res
    end

    export Midware, DefaultHeaders, FileServer, CookieDecoder, NotFound, MidwareStack, handle

end