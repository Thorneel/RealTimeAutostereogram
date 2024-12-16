extends SubViewport

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_on_set_eye_distance(Config.get_eye_distance(Constants.DEFAULT_EYE_DISTANCE))
	Events.connect("set_eye_distance", Callable(self, "_on_set_eye_distance"))
	set_new_size_y()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if size.y != DisplayServer.window_get_size().y:
		set_new_size_y()


func set_new_size_y() -> void:
	var old_height:int = size.y
	var window_height:int = DisplayServer.window_get_size().y
	size.y = DisplayServer.window_get_size().y


func _on_set_eye_distance(eye_distance:float):
	size.x = roundi(eye_distance)
	
