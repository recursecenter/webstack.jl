require("websockets.jl")

#global Dict to store open connections in
@show global connections = {0 => WebSocket(0,TcpSocket())}

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
server = Server(wshh)
run(server,8080)
