using Micro

app = Micro.app()

# Route with HTTP verbs
route(app, GET | POST, "/admin/new") do req, res
    "Hello admin"
end

start(app, 8000)