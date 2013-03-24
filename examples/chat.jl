using Http
using Websockets

#global Dict to store open connections in
@show global connections = {0 => WebSocket(0,TcpSocket())}

wsh = WebsocketHandler() do req,client
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
end

onepage = readall("./examples/chat-client.html")
httph = HttpHandler() do req::Request, res::Response
  Response(onepage)
end

server = Server(httph,wsh)
run(server,8080)
