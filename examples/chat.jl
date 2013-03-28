using Http
using Websockets

#global Dict to store open connections in
global connections = Dict{Int,Websocket}()
global usernames   = Dict{Int,String}()

function decodeMessage( msg )
    str = ""
    for d in msg
        str = string( str, convert(Char, d) )
    end
    str
end

wsh = WebsocketHandler() do req, client
    global connections
    @show connections[client.id] = client
    @show usernames[client.id] = string(client.id)
    while true
        msg = read(client)
        msg = decodeMessage(msg)
        if( length(msg) > 12 && msg[1:12] == "setusername:" )
            println("SETTING USERNAME: $msg")
            usernames[client.id] = msg[13:length(msg)]
        end
        if( length(msg) > 4 && msg[1:4] == "say:")
            println("EMITTING MESSAGE: $msg")
            for (k,v) in connections
                if k != client.id
                    write(v, usernames[client.id] * ": " * msg[5:length(msg)])
                end
            end
        end
    end
end

httph = HttpHandler() do req::Request, res::Response
  onepage = readall("./examples/chat-client.html")
  Response(onepage)
end

server = Server(httph, wsh)
run(server,8000)
