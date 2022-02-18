extends Node

var api

func _ready():
	api = $".".get_parent().get_node("api")

func _on_tasking_whoami(task):

	if task.has("command") and task.get("command") == "whoami":
		var output = []
		# int pid execute(path: String, arguments: PoolStringArray, blocking: bool = true, output: Array = [  ], read_stderr: bool = false)

		var exit_code = OS.execute("whoami", [], true, output, true)

		print("")
		print(exit_code)
		print(output)
		print("")

		api.agent_response(
			api._create_task_response(
				exit_code == 0,
				true,
				task.get("id"),
				output,
				[
					[
						"Process Create",
						"/usr/bin/whoami"
					]
				]
			)
		)

	else:
		print("bad whoami task: ", task)
	# TODO: agent_response in failure cases
