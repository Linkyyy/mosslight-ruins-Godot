extends SceneTree
## Export actual engine notices and the original icon for native distribution.
func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute("res://assets/licenses")
	DirAccess.make_dir_recursive_absolute("res://builds")
	var license_file = FileAccess.open("res://assets/licenses/Godot-MIT.txt",FileAccess.WRITE)
	license_file.store_string(Engine.get_license_text())
	license_file.close()
	var notices = FileAccess.open("res://assets/licenses/Godot-ThirdParty.txt",FileAccess.WRITE)
	notices.store_string("Godot Engine third-party notices\n\n")
	notices.store_string(JSON.stringify(Engine.get_copyright_info(),"\t"))
	notices.store_string("\n\nLicense texts\n\n")
	notices.store_string(JSON.stringify(Engine.get_license_info(),"\t"))
	notices.close()
	var icon_image = load("res://icon.svg").get_image()
	if icon_image == null or icon_image.save_png("res://builds/icon.png") != OK:
		push_error("Could not prepare distribution icon")
		quit(1)
		return
	quit()
