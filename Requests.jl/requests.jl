module Requests
# Use integers for HTTP methods
const GET = 1
const POST = 2
const PUT = 3
const DELETE = 4

# Integers to Strings for HTTP Methods
_method_dict = Dict{Int,String}()
_method_dict[1] = "GET"
_method_dict[2] = "POST"
_method_dict[3] = "PUT"
_method_dict[4] = "DELETE"

typealias Headers Dict{String, String}
# Represent Headers the way a server would expect them (\r\n) and end with \r\n\r\n
repr(h::Headers) = string(join(["$k: $v" for (k, v) in h], "\r\n"), "\r\n")
add_header(h::Headers, key::String, value::String) = h[key] = value

type Request
    method::String
    headers::Headers
    uri::String
end
repr(r::Request) = string("$(r.method) / HTTP/1.1\r\n", "Host: $(r.uri)\r\n", repr(r.headers), "\r\n") 

request(uri::String)                             = request{T <: String}(GET, uri, Dict{T, T}())
request(uri::String, data::Dict{String, String}) = request(GET, uri, data)
function request{T <: String}(method::Integer, uri::T, data::Dict{T, T})
    client = connect(TcpSocket(), uri, 80)[1]
    # make the request with default headers
    req = Request(_method_dict[method], default_headers(), uri)
    merge!(req.headers, data)
    write(client, repr(req))
    readall(client)
end

function convert(String, x::VersionNumber)
    io = memio()
    print(io, x)
    seek(io, 0)
    v = readall(io)
    v[3:end-1]
end

default_user_agent() = "julia-requests/0.1 julia/$(convert(String, Base.VERSION))"
function default_headers()
    h = Headers()
    add_header(h, "User-Agent", default_user_agent())
    add_header(h, "Accept-Encoding", "gzip, deflate, compress")
    add_header(h, "Accept", "*/*")
    h
end

# Todo add data to a POST and ensure a Content-Length header
response = request(POST, "http://httpbin.org/post", ["hello" => "world"])
@show response
end
