using Http
using Meddle
using Websockets

##
## Websockets stuff (port 8080)
##

#global Dict to store open connections in
global connections = {0 => WebSocket(0,TcpSocket())}

wsh = websocket_handler((req,client) -> begin
  global connections
  @show connections[client.id] = client 
  while true
    msg = read(client)
    for (k,v) in connections
      if k != client.id
        write(v, msg)
      end
    end
  end
end)

wshh = WebsocketHandler(wsh)

##
## File server stuff (port 8000)
##

stack = middleware(DefaultHeaders, CookieDecoder, FileServer(pwd()), NotFound)
http = HttpHandler((req, res) -> Meddle.handle(stack, req, res))

for event in split("connect read write close error")
    http.events[event] = ((event) -> (client, args...) -> println(client.id,": $event"))(event)
end
http.events["error"] = (client, err) -> println(err)
http.events["listen"] = (port)        -> println("Listening on $port...")

server = Server(http,wshh)
run(server, 8080)
