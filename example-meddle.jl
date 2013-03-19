using Http
using Meddle

stack = [DefaultHeaders(), CookieDecoder(), FileServer(pwd()), NotFound()]

http = HttpHandler((req, res) -> Meddle.handle(stack, req, res))

for event in split("connect read write close error")
    http.events[event] = ((event) -> (client, args...) -> println(client.id,": $event"))(event)
end
http.events["error"] = (client, err) -> println(err)

server = Server(http)
run(server, 8000)