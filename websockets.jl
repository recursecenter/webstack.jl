using Http

type WebSocket
  socket::TcpSocket
end

#
# Websocket Packets
#

#      0                   1                   2                   3
#      0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
#     +-+-+-+-+-------+-+-------------+-------------------------------+
#     |F|R|R|R| opcode|M| Payload len |    Extended payload length    |
#     |I|S|S|S|  (4)  |A|     (7)     |             (16/64)           |
#     |N|V|V|V|       |S|             |   (if payload len==126/127)   |
#     | |1|2|3|       |K|             |                               |
#     +-+-+-+-+-------+-+-------------+ - - - - - - - - - - - - - - - +
#     |     Extended payload length continued, if payload len == 127  |
#     + - - - - - - - - - - - - - - - +-------------------------------+
#     |                               |Masking-key, if MASK set to 1  |
#     +-------------------------------+-------------------------------+
#     | Masking-key (continued)       |          Payload Data         |
#     +-------------------------------- - - - - - - - - - - - - - - - +
#     :                     Payload Data continued ...                :
#     + - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - +
#     |                     Payload Data continued ...                |
#     +---------------------------------------------------------------+
#

function write(ws::WebSocket,data)
  println(data)
end

import Base.read
function read(ws::WebSocket)
  println("starting")
  str = read(ws.socket,Uint8)
  println("end")
end

function close(ws::WebSocket)
  println("...send close frame")
  println("...make sure we don't send anything else")
  println("...wait for their close frame, then close the Tcpsocket")
end

#
# Websocket Handshake
#

#parse http request for special key
get_websocket_key(request::Request) = begin
  return request.headers["Sec-WebSocket-Key"]
end

char2digit(c::Char) = '0' <= c <= '9' ? c-'0' : lowercase(c)-'a'+10

hex2bytes(s::ASCIIString) =
  [ uint8(char2digit(s[i])<<4 | char2digit(s[i+1])) for i=1:2:length(s) ]

const base64chars = ['A':'Z','a':'z','0':'9','+','/']

function base64(x::Uint8, y::Uint8, z::Uint8)
  n = int(x)<<16 | int(y)<<8 | int(z)
  base64chars[(n >> 18)            + 1],
  base64chars[(n >> 12) & 0b111111 + 1],
  base64chars[(n >>  6) & 0b111111 + 1],
  base64chars[(n      ) & 0b111111 + 1]
end

function base64(x::Uint8, y::Uint8)
  a, b, c = base64(x, y, 0x0)
  a, b, c, '='
end

function base64(x::Uint8)
  a, b = base64(x, 0x0, 0x0)
  a, b, '=', '='
end

function base64(v::Array{Uint8})
  n = length(v)
  w = Array(Uint8,4*iceil(n/3))
  j = 0
  for i = 1:3:n-2
    w[j+=1], w[j+=1], w[j+=1], w[j+=1] = base64(v[i], v[i+1], v[i+2])
  end
  tail = n % 3
  if tail > 0
    w[j+=1], w[j+=1], w[j+=1], w[j+=1] = base64(v[end-tail+1:end]...)
  end
  ASCIIString(w)
end

generate_websocket_key(key) = begin
  magicstring = "258EAFA5-E914-47DA-95CA-C5AB0DC85B11"
  resp_key = readall(`echo -n $key$magicstring` | `openssl dgst -sha1`)
  m = match(r"\w+\W+(.+)$", resp_key)
  bytes = hex2bytes(m.captures[1])
  return base64(bytes)
end

# perform the handshake if it's a websocket request
websocket_handshake(request,client) = begin

  key = get_websocket_key(request)
  resp_key = generate_websocket_key(key)
  
  #TODO: use a proper HTTP response type
  response = "HTTP/1.1 101 Switching Protocols\r\nUpgrade: websocket\r\nConnection: Upgrade\r\nSec-WebSocket-Accept: "
  Base.write(client.sock,"$response$resp_key\r\n\r\n")
  @show Base.read(client.sock,Uint8)
end

websocket_handler(handler) = (request,client) -> begin
  websocket_handshake(request,client)
  handler(request,WebSocket(client.sock))
end
