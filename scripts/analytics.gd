extends Node

const POSTHOG_API_KEY = "phc_oLHHUynQgDP5hudfGNy9PWAcxq4prtbBbQWpxPV27vAD"
const POSTHOG_URL = "https://eu.i.posthog.com/capture/"
const PLAYER_ID_FILE = "user://player_id.save"

var distinct_id: String = ""
var session_start: float = 0.0

func _ready() -> void:
	distinct_id = _load_or_create_player_id()

func _load_or_create_player_id() -> String:
	if FileAccess.file_exists(PLAYER_ID_FILE):
		var file = FileAccess.open(PLAYER_ID_FILE, FileAccess.READ)
		if file:
			var id = file.get_line().strip_edges()
			if id != "":
				return id
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	var new_id = "player-%08x-%08x" % [rng.randi(), rng.randi()]
	var file = FileAccess.open(PLAYER_ID_FILE, FileAccess.WRITE)
	if file:
		file.store_line(new_id)
	return new_id

func begin_session() -> void:
	session_start = Time.get_unix_time_from_system()

func _session_seconds() -> int:
	if session_start == 0.0:
		return 0
	return int(Time.get_unix_time_from_system() - session_start)

func track(event: String, properties: Dictionary = {}) -> void:
	if not Globals.user_tracking:
		return
	var props = {
		"$lib": "godot-planetx",
		"session_seconds": _session_seconds(),
	}
	props.merge(properties)

	var body = {
		"api_key": POSTHOG_API_KEY,
		"event": event,
		"distinct_id": distinct_id,
		"properties": props,
	}

	var http = HTTPRequest.new()
	add_child(http)
	http.request_completed.connect(func(_r, _c, _h, _b): http.queue_free())
	http.request(POSTHOG_URL, ["Content-Type: application/json"], HTTPClient.METHOD_POST, JSON.stringify(body))
