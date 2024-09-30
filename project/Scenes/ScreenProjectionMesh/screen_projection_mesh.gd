class_name ScreenProjectionMesh
extends MeshInstance3D


const DEFAULT_STATIC_NOISE = false
const DEFAULT_WALL_EYED = true


var mat:Material = get_mesh().get_material()
var noise_img:NoiseTexture2D = mat.get_shader_parameter("noise_img")
var noise:Noise = noise_img.get_noise()
var random:RandomNumberGenerator = RandomNumberGenerator.new()
var static_noise = DEFAULT_STATIC_NOISE


# Called when the node enters the scene tree for the first time.
func _ready():
	Events.connect("toggle_autostereogram", Callable(self, "_on_toggle_autostereogram"))
	Events.connect("toggle_image_overlay", Callable(self, "_on_toggle_image_overlay"))
	Events.connect("toggle_static_noise", Callable(self, "_on_toggle_static_noise"))
	Events.connect("set_eye_distance", Callable(self, "_on_set_eye_distance"))
	Events.connect("toggle_wall_eyed", Callable(self, "_on_toggle_wall_eyed"))
	static_noise = Config.get_static_noise(static_noise)
	mat.set_shader_parameter("show_reticle", !static_noise)
	mat.set_shader_parameter("wall_eyed", Config.get_wall_eyed(DEFAULT_WALL_EYED))



# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	if (!get_tree().paused) and !static_noise:
		_change_noise()


func _change_noise():
	noise.seed = random.randi()


## SIGNALS ##

func _on_toggle_autostereogram():
	visible = !visible;


func _on_toggle_image_overlay():
	var current_value:bool = mat.get_shader_parameter("show_screen")
	mat.set_shader_parameter("show_screen", !current_value)


func _on_set_eye_distance(eye_distance:float):
	mat.set_shader_parameter("eye_distance_in_pixels", eye_distance)

func _on_toggle_static_noise():
	static_noise = !static_noise
	mat.set_shader_parameter("display_reticle", !static_noise)
	Config.save_static_noise(static_noise)

func _on_toggle_wall_eyed(wall_eyed:bool):
	mat.set_shader_parameter("wall_eyed", wall_eyed)
	Config.save_wall_eyed(wall_eyed)
