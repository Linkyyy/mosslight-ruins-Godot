extends Node
## Atomic saves with a verified payload and a recoverable previous generation.
var profile_directory: String = "user://"
var save_path: String = "user://journey.json"
var is_test_profile: bool = false
var last_error: String = ""
var recovered_backup: bool = false

func _enter_tree() -> void:
	is_test_profile = "--test-profile" in OS.get_cmdline_user_args()
	if is_test_profile:
		profile_directory = "res://.user_test/profile/"
		DirAccess.make_dir_recursive_absolute(profile_directory)
	save_path = profile_path("journey.json")

func profile_path(filename: String) -> String:
	return profile_directory.path_join(filename)

func write_run(payload: Dictionary) -> bool:
	last_error = ""
	var text: String = JSON.stringify(payload)
	var envelope = {"format":1,"payload":text,"sha256":text.sha256_text()}
	var file = FileAccess.open(save_path + ".tmp", FileAccess.WRITE)
	if file == null:
		last_error = "无法写入存档目录"
		return false
	file.store_string(JSON.stringify(envelope))
	file.flush()
	file.close()
	if FileAccess.file_exists(save_path):
		var copy_error = DirAccess.copy_absolute(save_path, save_path + ".bak")
		if copy_error != OK:
			last_error = "无法备份当前存档"
			return false
	var result = DirAccess.rename_absolute(save_path + ".tmp", save_path)
	if result != OK:
		last_error = "无法完成存档写入"
		return false
	return true

func read_run() -> Dictionary:
	recovered_backup = false
	var current = _read_verified(save_path)
	if not current.is_empty():
		return current
	var backup = _read_verified(save_path + ".bak")
	if not backup.is_empty():
		recovered_backup = true
		return backup
	return {}

func _read_verified(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var parser = JSON.new()
	if parser.parse(FileAccess.get_file_as_string(path)) != OK:
		return {}
	var envelope = parser.data
	if not envelope is Dictionary or not envelope.get("payload") is String:
		return {}
	var text: String = envelope.payload
	if text.sha256_text() != envelope.get("sha256", ""):
		return {}
	if parser.parse(text) != OK:
		return {}
	var payload = parser.data
	return payload if payload is Dictionary else {}

func clear_run() -> void:
	for suffix in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(save_path + suffix):
			DirAccess.remove_absolute(save_path + suffix)
