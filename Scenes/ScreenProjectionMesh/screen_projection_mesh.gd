extends MeshInstance3D


var mat:Material = get_mesh().get_material()
var noise_img:NoiseTexture2D = mat.get_shader_parameter("noise_img")
var noise:Noise = noise_img.get_noise()
var random:RandomNumberGenerator = RandomNumberGenerator.new()

var proportion:float = 1.;
var is_proportion_descending:bool = true
const prop_step:float = 0.66


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	_change_noise()


func _change_noise():
	noise.seed = random.randi()


func toggle_screen():
	var current_value:bool = mat.get_shader_parameter("show_screen")
	mat.set_shader_parameter("show_screen", !current_value)
