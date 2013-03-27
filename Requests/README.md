# Requests

A human friendly API for sending a request. It's the Julia version of Python [Requests](http://docs.python-requests.org/en/latest/).

## Usage

```.jl
# implicit GET
response = request("http://httpbin.org")

# a broken, but API example
response = request(POST, "http://httpbin.org/post", ["EXTRA" => "HEADERS"], DATA)
```
