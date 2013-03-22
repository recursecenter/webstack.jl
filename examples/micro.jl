using Micro

app = Micro.app()

# Route with HTTP verbs
route(app, GET, "/") do req, res
	"This is the root"
end

route(app, GET | POST, "/admin/new") do req, res
    "Hello admin"
end

get(app, "/foo/bar") do req, res
    "totally"
end

get(app, "/show/urlparams") do req, res
	params = url_params(req)
	repr(params)
end

start(app, 8000)
