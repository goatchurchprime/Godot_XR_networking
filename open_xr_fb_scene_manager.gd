extends OpenXRFbSceneManager



@onready var scene_manager: OpenXRFbSceneManager = self

func _ready():
	scene_manager.openxr_fb_scene_data_missing.connect(_scene_data_missing)
	scene_manager.openxr_fb_scene_capture_completed.connect(_scene_capture_completed)

func _scene_data_missing() -> void:
	print("_scene_data_missing")
	scene_manager.request_scene_capture()

func _scene_capture_completed(success: bool) -> void:
	print("_scene_capture_completed ", success)
	if success == false:
		return

	# Recreate scene anchors since the user may have changed them.
	if scene_manager.are_scene_anchors_created():
		scene_manager.remove_scene_anchors()
		scene_manager.create_scene_anchors()
