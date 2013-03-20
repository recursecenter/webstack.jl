using Micro

app = Micro.app()

# Route with HTTP verbs
route(app, GET | POST, "/admin/new") do req, res
    "Hello admin"
end

get(app, "/foo/bar") do req, res
    "totally"
end

start(app, 8000)
