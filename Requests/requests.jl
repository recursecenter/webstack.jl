# A human API for making HTTP Requests
module Requests

using Httplib

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
add_header{T <: String}(h::Headers, key::T, value::T) = h[key] = value

repr(r::Request) = string("$(r.method) / HTTP/1.1\r\n", "Host: $(r.resource)\r\n", repr(r.headers), "\r\n") 

# Make an HTTP request and get the response.
# 
#     # An implicit GET request
#     request("http://google.com")
#     # FIXME
#     request("http://duckduckgo.com", ["q" => "dogs"])
#     # FIXME
#     request(POST, "http://httpbin.org/post", ["data" => "some data"])
#
request{T <: String}(uri::T)                   = request(GET, uri, Dict{T, T}())
request{T <: String}(uri::T, data::Dict{T, T}) = request(GET, uri, data)
function request{T <: String}(method::Int, uri::T, data::Dict{T, T})
    client = connect(TcpSocket(), uri, 80)[1]
    req = Request(_method_dict[method], uri, default_headers(), "", Dict{T, T}())
    merge!(req.headers, data)
    write(client, repr(req))
    readall(client)
end

default_user_agent() = "julia-requests/0.1 julia/$VERSION"
# Set the default headers for a request
function default_headers()
    h = Headers()
    add_header(h, "User-Agent", default_user_agent())
    add_header(h, "Accept-Encoding", "gzip, deflate, compress")
    add_header(h, "Accept", "*/*")
    h
end

end # end module
