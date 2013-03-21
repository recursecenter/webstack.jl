require("websockets.jl")

wsh = websocket_handler((req,client) -> begin
	while true
		read(client)
	end
end)
wshh = WebsocketHandler(wsh)
server = Server(wshh)
run(server,8080)