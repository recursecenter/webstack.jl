WIP: Implementing the webstack in Julia.

Simple HTTP hello world:

```.jl
using Http

http = HttpHandler() do req::Request, res::Response
    Response( ismatch(r"^/hello/",req.resource) ? string("Hello ", split(req.resource,'/')[3], "!") : 404 )
end

http.events["error"]  = ( client, err ) -> println( err )
http.events["listen"] = ( port )        -> println("Listening on $port...")

server = Server( http )
run( server, 8000 )
```

Middleware using `Meddle`:

```.jl
using Http
using Meddle

stack = [ DefaultHeaders(), CookieDecoder(), FileServer( pwd() ), NotFound() ]

http = HttpHandler( (req, res) -> handle( stack, req, res ) )

for event in split("connect read write close error")
    http.events[event] = ( ( event ) -> ( client, args... ) -> println(client.id,": $event") )( event )
end
http.events["error"] = ( client, err ) -> println( err )

server = Server( http )
run( server, 8000 )
```

[Never graduate][HS].

[HS]: https://www.hackerschool.com