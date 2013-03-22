WIP: Implementing the webstack in Julia.

## Dependencies

* Julia, since it's that's what it's all written in.

##Simple HTTP hello world:

If you want to handle things at the level of just
HTTP requests and responses, this is a simple example
of returning "Hello <name>!" only on "/hello/<name>" paths,
and a 404 on all others.

Put it in a file called `http.jl` and then use the command `julia http.jl` to run it.
If you open `localhost:8000/hello/user`, you'll get to see the server say hello.

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

##Middleware using `Meddle`:

This is an example of using our middleware framework, Meddle.
It puts each request through a "stack" of handlers,
each of which can modify the request and/or response objects.

This particular example is a file server.
It will serve files from the directory you run it in,
and respond with `404`s if you give an invalid path.

Put it in a file called `meddle.jl` and then use the command `julia meddle.jl` to run it.
If you run it from inside your `webstack.jl` folder,
you could then open `localhost:8000/examples/meddle.jl` to have it serve its own code to you.

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

##Web Application with `Micro`:

Micro is a Sintra-like micro framework for declaring routes and handling requests.  It is built on top of `Http` and `Meddle`.

Here is a brief example that will return a few different messages for different routes, if you run this and open `localhost:8000` you will see "This is the root" for GET, POST or PUT requests.  The line `get(app, "/about") do ...` is shorthand for only serving GET requests through that route.

```.jl
using Micro

app = Micro.app()

route(app, GET | POST | PUT, "/") do req, res
	"This is the root"
end

get(app, "/about") do req, res
	"This app is running on Micro"
end

start(app, 8000)
```

[Never graduate][HS].

[HS]: https://www.hackerschool.com
