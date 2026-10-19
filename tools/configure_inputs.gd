extends Node
## Write native InputMap defaults into project.godot for editor visibility.
func _ready() -> void:
	for action in Controls.ACTIONS:
		ProjectSettings.set_setting("input/"+action,{"deadzone":.2,"events":InputMap.action_get_events(action)})
	var result = ProjectSettings.save()
	print("InputMap saved: "+str(result==OK))
	get_tree().quit(0 if result==OK else 1)
