## Class inheriting HttpRouter for handling file serving requests
## [br]
## [br]NOTE: This class mainly handles behind the scenes stuff.
class_name HttpFileRouter
extends HttpRouter

## Full path to the folder which will be exposed to web
var path: String = ""

## Relative path to the index page, which will be served when a request is made to "/" (server root)
var index_page: String = "index.html"

## Relative path to the fallback page which will be served if the requested file was not found
var fallback_page: String = ""

## An ordered list of extensions that will be checked
## if no file extension is provided by the request
var extensions: PackedStringArray = ["html"]

## A list of extensions that will be excluded if requested
var exclude_extensions: PackedStringArray = []

#region main
## Creates an HttpFileRouter intance
## [br]
## [br][param path] - Full path to the folder which will be exposed to web.
## [br][param options] - Optional Dictionary of options which can be configured:
## [br] - [param fallback_page]: Full path to the fallback page which will be served if the requested file was not found
## [br] - [param extensions]: A list of extensions that will be checked if no file extension is provided by the request
## [br]	- [param exclude_extensions]: A list of extensions that will be excluded if requested
@warning_ignore("shadowed_variable")
func _init(
	path: String,
	options: Dictionary = {
		index_page = index_page,
		fallback_page = fallback_page,
		extensions = extensions,
		exclude_extensions = exclude_extensions,
	}
	) -> void:
	self.path = path
	self.index_page = options.get("index_page", "")
	self.fallback_page = options.get("fallback_page", "")
	self.extensions = options.get("extensions", [])
	self.exclude_extensions = options.get("exclude_extensions", [])
#endregion

#region methods
## Handle a GET request
## [br]
## [br][param request] - The request from the client
## [br][param response] - The response to send to the client
func handle_get(request: HttpRequest, response: HttpResponse) -> void:
	var serving_path: String = _determine_serving_path(request.path)
	if _is_valid_file_path(serving_path):
		_serve_existing_file(serving_path, response)
	else:
		_handle_fallback(response)

#region handle_get() auxiliar
## Checks if the determined serving path is a valid file to serve.
func _is_valid_file_path(serving_path: String) -> bool:
	return FileAccess.file_exists(serving_path) and not _has_excluded_extension(serving_path.get_extension(), ["gd"])

## Checks if the given extension is in the list of excluded extensions.
func _has_excluded_extension(extension: String, extra_excluded_extensions: Array = []) -> bool:
	return extension in extra_excluded_extensions + Array(exclude_extensions)

## Determines the correct path to serve based on the request.
func _determine_serving_path(request_path: String) -> String:
	var serving_path: String = path + request_path
	if !FileAccess.file_exists(serving_path):
		if request_path == "/" and index_page.length() > 0:
			serving_path = path + "/" + index_page
		elif request_path.get_extension() == "":
			serving_path = _check_extensions(request_path)

	return serving_path

## Serves the existing file to the client.
func _serve_existing_file(serving_path: String, response: HttpResponse) -> void:
	response.send_raw(
		200,
		_serve_file(serving_path),
		_get_mime(serving_path.get_extension())
	)

## Handles the case when the requested file is not found, serving the fallback page if available.
func _handle_fallback(response: HttpResponse) -> void:
	if fallback_page.length() > 0:
		var fallback_path: String = path + "/" + fallback_page
		response.send_raw(200 if index_page == fallback_page else 404, _serve_file(fallback_path), _get_mime(fallback_page.get_extension()))
	else:
		response.send_raw(404)

## Checks for the file with different extensions if the original path doesn't exist.
func _check_extensions(request_path: String) -> String:
	for extension in extensions:
		var potential_path: String = path + request_path + "." + extension
		if FileAccess.file_exists(potential_path):
			return potential_path

	return path + request_path # Return the original path if no extension matches

#endregion

## Reads a file as text
## [br]
## [br][param file_path] - Full path to the file
func _serve_file(file_path: String) -> PackedByteArray:
	var content: PackedByteArray = []
	var file: FileAccess = FileAccess.open(file_path, FileAccess.READ)
	var error = FileAccess.get_open_error()
	if error:
		content = ("Couldn't serve file, ERROR = %s" % error).to_ascii_buffer()
	else:
		content = file.get_buffer(file.get_length())

	file.close()

	return content

## Get the full MIME type of a file from its extension
## [br]
## [br][param file_extension] - Extension of the file to be served
## [codeblock]".html", ".png", etc..[/codeblock]
func _get_mime(file_extension: String) -> String:
	var type: String = "application"
	var subtype: String = "octet-stream"

	match file_extension:
		# Web files
		"css","html","csv","js","mjs":
			type = "text"
			subtype = "javascript" if file_extension in ["js","mjs"] else file_extension
		"php":
			subtype = "x-httpd-php"
		"ttf","woff","woff2":
			type = "font"
			subtype = file_extension

		# Image
		"png","bmp","gif","png","webp":
			type = "image"
			subtype = file_extension
		"jpeg","jpg":
			type = "image"
			subtype = "jpg"
		"tiff", "tif":
			type = "image"
			subtype = "jpg"
		"svg":
			type = "image"
			subtype = "svg+xml"
		"ico":
			type = "image"
			subtype = "vnd.microsoft.icon"

		# Documents
		"doc":
			subtype = "msword"
		"docx":
			subtype = "vnd.openxmlformats-officedocument.wordprocessingml.document"
		"7z":
			subtype = "x-7x-compressed"
		"gz":
			subtype = "gzip"
		"tar":
			subtype = "application/x-tar"
		"json","pdf","zip":
			subtype = file_extension
		"txt":
			type = "text"
			subtype = "plain"
		"ppt":
			subtype = "vnd.ms-powerpoint"

		# Audio
		"midi","mp3","wav":
			type = "audio"
			subtype = file_extension
		"mp4","mpeg","webm":
			type = "audio"
			subtype = file_extension
		"oga","ogg":
			type = "audio"
			subtype = "ogg"
		"mpkg":
			subtype = "vnd.apple.installer+xml"

		# Video
		"ogv":
			type = "video"
			subtype = "ogg"
		"avi":
			type = "video"
			subtype = "x-msvideo"
		"ogx":
			subtype = "ogg"

	return type + "/" + subtype

#endregion