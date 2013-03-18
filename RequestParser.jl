module RequestParser

using HttpParser
export RequestParser, Request, Headers

typealias Headers Dict{String,String}

immutable Request
    method::String
    resource::String
    headers::Headers
    data::String
    raw::String
    state::Dict
end

type PartialRequest
    method::Any
    resource::String
    headers::Headers
    data::String
end

function reset(r::PartialRequest)
    r.method = ""
    r.resource = ""
    r.headers = Dict{String, String}()
    r.data = ""
    r
end

r = PartialRequest("","",Dict{String, String}(),"")

function on_message_begin(parser)
    r.resource = ""
    return 0
end

function on_url(parser, at, len)
    r.resource = string(r.resource, bytestring(convert(Ptr{Uint8}, at),int(len)))
    return 0
end

function on_status_complete(parser)
    return 0
end

# Gather the header_field, set the field
# on header value, set the value for the current field
# there might be a better way than this: https://github.com/joyent/node/blob/master/src/node_http_parser.cc#L207

function on_header_field(parser, at, len)
    header = bytestring(convert(Ptr{Uint8}, at))
    header_field = header[1:len]
    # set the current header
    r.headers["current_header"] = header_field
    return 0
end
function on_header_value(parser, at, len)
    s = bytestring(convert(Ptr{Uint8}, at),int(len))
    # once we know we have the header value, that will be the value for current header
    r.headers[r.headers["current_header"]] = s
    # reset current_header
    r.headers["current_header"] = ""
    return 0
end
function on_headers_complete(parser)
    p = unsafe_ref(parser)
    # get first two bits of p.type_and_flags
    println("Type and flags: ", p.type_and_flags)
    println("Errno and upgrade: ", p.errno_and_upgrade)
    ptype = p.type_and_flags & 0x03
    if ptype == 0
        r.method = http_method_str(convert(Int, p.method))
    end
    if ptype == 1
        r.headers["status_code"] = string(convert(Int, p.status_code))
    end
    r.headers["http_major"] = string(convert(Int, p.http_major))
    r.headers["http_minor"] = string(convert(Int, p.http_minor))
    r.headers["Keep-Alive"] = string(http_should_keep_alive(parser))
    return 0
end
function on_body(parser, at, len)
    r.data = string(r.data, bytestring(convert(Ptr{Uint8}, at)))
    return 0
end
function on_message_complete(parser)
    return 0
end

c_message_begin_cb = cfunction(on_message_begin, Int, (Ptr{Parser},))
c_url_cb = cfunction(on_url, Int, (Ptr{Parser}, Ptr{Cchar}, Csize_t,))
c_status_complete_cb = cfunction(on_status_complete, Int, (Ptr{Parser},))
c_header_field_cb = cfunction(on_header_field, Int, (Ptr{Parser}, Ptr{Cchar}, Csize_t,))
c_header_value_cb = cfunction(on_header_value, Int, (Ptr{Parser}, Ptr{Cchar}, Csize_t,))
c_headers_complete_cb = cfunction(on_headers_complete, Int, (Ptr{Parser},))
c_body_cb = cfunction(on_body, Int, (Ptr{Parser}, Ptr{Cchar}, Csize_t,))
c_message_complete_cb = cfunction(on_message_complete, Int, (Ptr{Parser},))

function parse_http_request(http_request::String)
    parser = Parser()
    http_parser_init(parser)
    settings = ParserSettings(c_message_begin_cb, c_url_cb, c_status_complete_cb, c_header_field_cb, c_header_value_cb, c_headers_complete_cb, c_body_cb, c_message_complete_cb)

    http_parser_execute( parser, settings, http_request )

    # lines = split(http_request, "\r\n")

    # for i=1:length(lines)
    #     size = http_parser_execute(parser, settings, string(lines[i],"\r\n"))
    # end
    # size = http_parser_execute(parser, settings, "\r\n")

    delete!(r.headers,"current_header",nothing)
    req = Request(r.method,r.resource,r.headers,r.data,http_request,Dict())
    reset(r)
    req
end

end
