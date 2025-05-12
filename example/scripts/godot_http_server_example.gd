class_name GodotHttpServerExample
extends Node


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var server = HttpServer.new()
	server.register_router("/", MyExampleRouter.new())
	add_child(server)
	server.enable_cors(["http://localhost:8060"])
	server.start()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

class MyExampleRouter extends HttpRouter:
	# Handle a GET request
	func handle_get(request: HttpRequest, response: HttpResponse):
		response.send(200, "Hello! from GET")

	# Handle a POST request
	func handle_post(request: HttpRequest, response: HttpResponse) -> void:
		response.send(200, JSON.stringify({
			message = "Hello! from POST",
			raw_body = request.body,
			parsed_body = request.get_body_parsed(),
			params = request.query
		}), "application/json")

	# Handle a PUT request
	func handle_put(request: HttpRequest, response: HttpResponse) -> void:
		response.send(200, "Hello! from PUT")

	# Handle a PATCH request
	func handle_patch(request: HttpRequest, response: HttpResponse) -> void:
		response.send(200, "Hello! from PATCH")

	# Handle a DELETE request
	func handle_delete(request: HttpRequest, response: HttpResponse) -> void:
		response.send(200, "Hello! from DELETE")
