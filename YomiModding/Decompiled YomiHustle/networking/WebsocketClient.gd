class_name MultiplayerClient






var _client = WebSocketClient.new()
var connected = false

var address

signal connection_ended()
signal connection_succeeded()

func _init(address):
	self.address = address
	
	_client.connect("connection_failed", self, "_closed", [], CONNECT_DEFERRED)
	_client.connect("server_disconnected", self, "_closed", [], CONNECT_DEFERRED)
	_client.connect("connection_succeeded", self, "_connected", [], CONNECT_DEFERRED)

	
	var err = _client.connect_to_url(address, PoolStringArray(["binary"]), true)
	if err != OK:
		print("Unable to connect")
		end_connection()

func get_client():
	return _client

func end_connection():
	emit_signal("connection_ended")
	_client.disconnect_from_host()

func _closed():
	
	
	print("closed connection.")
	end_connection()

func _connected():
	connected = true
	print("connected to server at " + str(address))
	emit_signal("connection_succeeded")

func poll():
	_client.poll()
