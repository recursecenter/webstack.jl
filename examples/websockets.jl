using Http
using Websockets

wsh = WebsocketHandler() do req::Request,client::WebSocket
	while true
		msg = read(client)
		write(client, msg)
	end
end
server = Server(wsh)
run(server,8080)
