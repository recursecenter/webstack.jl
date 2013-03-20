using Http

type WebSocket
  socket::TcpSocket
  readcb::Function
end

#parse http request for special key
get_websocket_key(request::Request) = begin
  return request.headers["Sec-WebSocket-Key"]
end

generate_websocket_key(key) = begin
  magicstring =  "258EAFA5-E914-47DA-95CA-C5AB0DC85B11"
  resp_key = readall(`echo -n $key$magicstring` | `openssl dgst -sha1`)
  m = match(r"\w+\W+(.+)$",resp_key)
  resp_key = m.captures[1]

  value = parse_hex(resp_key)
  #TODO: use a proper base64 encoder
  dig_syms = uint8(['A':'Z','a':'z','0':'9','+','/'])
  @show resp_key = base(dig_syms,value)

  return resp_key
end

# perform the handshake if it's a websocket request
websocket_handshake(request,client) = begin

  key = get_websocket_key(request)
  resp_key = generate_websocket_key(key)
  
  #TODO: use a proper HTTP response type
  response = "HTTP/1.1 101 Switching Protocols\nUpgrade: websocket\nConnection: Upgrade\nSec-WebSocket-Accept: "
  Base.write(client.sock,"$response$resp_key\n\n")
end

websocket_handler(handler) = (request,client) -> begin
  websocket_handshake(request,client)
  handler(request,client)
end
 
