using Http

http = HttpHandler() do req::Request, res::Response
    mb = 1024*1024
    
    x = memio(mb, true)
    for i=1:mb
        write(x, 'd')
    end
    seek(x, 0)
    #Response( ismatch(r"^/hello/",req.resource) ? string("Hello ", split(req.resource,'/')[3], "!") : 404 ),
    Response( ismatch(r"^/", req.resource) ? readall(x) : 404)
end

http.events["error"]  = ( client, err ) -> println( err )
http.events["listen"] = ( port )        -> println("Listening on $port...")

server = Server( http )
run( server, 8000 )
