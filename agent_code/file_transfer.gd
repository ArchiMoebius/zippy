extends Object

class_name FileTransfer

enum DIRECTION {UPLOAD, DOWNLOAD}
enum STATUS {BEGIN, TRANSFER, COMPLETE, ERROR}

export(STATUS) var state = STATUS.BEGIN

var api
var task_id
var file_id
var file_path
var direction
var file_handle
var file_size = 0
var chunk_size = 4096
var chunk_count = 0
var next_chunk_please = false

var completed = false
var file_id_requested = false

func debug():
	print("TaskID: %s\nFileId: %s\nFilePath: %s\n" % [task_id, file_id, file_path])

func _init(taskId, filePath, fileDirection, fileAPI):
	task_id = taskId
	file_path = filePath
	direction = fileDirection
	api = fileAPI
	file_id = ""

func process():
	print("FileTransfer Process: ", file_path, "\n", task_id,  "\n",file_id,  "\n",file_id_requested,  "\n",next_chunk_please)

	if not file_id_requested:
		var status = "error"
		var user_output = ""

		completed = true
		file_id_requested = true

		file_handle = File.new()
		file_size = 0

		print("\nDownload _process: ", file_path)

		# TODO: bail if we can't read the file and return this status / info

		if direction == DIRECTION.DOWNLOAD:
			file_handle.open(file_path , File.READ)

		if direction == DIRECTION.UPLOAD:
			file_handle.open(file_path , File.WRITE)

		if file_handle.is_open():
			
			file_path = file_handle.get_path_absolute()

			if direction == DIRECTION.DOWNLOAD:
				file_size = file_handle.get_len()
				chunk_count = int(file_size / chunk_size) + 1 # one based chunk counting...   \-:
				user_output = "File size: %d\nFullpath: %s" % [file_size, file_path]

			if direction == DIRECTION.UPLOAD:
				pass

			status = "success"
			completed = false
			state = STATUS.BEGIN
		else:
			state = STATUS.ERROR
			user_output = "Error code: %d\nFile: %s" % [file_handle.get_error(), file_path]

		api.agent_response(
			api.create_task_response(
				true,
				completed,
				task_id,
				"",
				[],
				[],
				[
					api.create_file_response(
						task_id,
						file_path,
						"",
						false,
						chunk_count,
						chunk_size,
						user_output,
						status
					)
				]
			)
		)

	if next_chunk_please:
		state = STATUS.TRANSFER
		next_chunk_please = false

		if direction == DIRECTION.DOWNLOAD:
			_process_download_chunk()

		if direction == DIRECTION.UPLOAD:
			# TODO: implement
			pass

func process_next_chunk(fileId):

	if fileId:
		file_id = fileId

	next_chunk_please = true

func _process_download_chunk():

	if not file_handle.is_open():
		print("_process_download_chunk failed - file_handle for %s is closed..." % file_path)
		return

	var position = file_handle.get_position()

	if position < file_size:
		completed = false

		var chunk_num = int(position/chunk_size) + 1
		var next_chunk_size = chunk_size
		
		if chunk_num >= int(file_size / chunk_size) + 1:
			completed = true
			state = STATUS.COMPLETE

		if position + chunk_size > file_size:
			next_chunk_size = file_size - position

		api.agent_response(
			api.create_task_response(
				true,
				completed,
				task_id,
				"",
				[],
				[],
				[],
				[
					api.create_file_response_chunk(
						task_id,
						file_id,
						chunk_num,
						file_handle.get_buffer(next_chunk_size)
					)
				]
			)
		)
	else:
		file_handle.close()
		state = STATUS.COMPLETE
