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

get(app, "/regex/<test::%[0-9][0-9]-[a-z]*>") do req, res
	"Now you have 2 problems! test: $(route_params(req, :test))"
end

get(app, "/datatype/<test::Int>") do req, res
	"Int: $(route_params(req, :test))"
end

get(app, "/named/<test>") do req, res
	"Named: $(route_params(req, :test))"
end

global boner = function( args... )
	"Suck it."
end

get(app, "/converter/<test::boner>") do req, res
	"Converter: $(route_params(req, :test))"
end

start(app, 8000)
