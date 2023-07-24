extends MeshInstance3D


var mat:Material = get_mesh().get_material()
var noise_img_1:NoiseTexture2D = mat.get_shader_parameter("noise_img_1")
var noise_img_2:NoiseTexture2D = mat.get_shader_parameter("noise_img_2")
var noise_1:Noise = noise_img_1.get_noise()
var noise_2:Noise = noise_img_2.get_noise()
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
	pass


func _change_noise():
	if is_proportion_descending:
		proportion -= prop_step
		if proportion <= 0.:
			proportion = 0.
			is_proportion_descending = false
			noise_1.seed = random.randi()
	else:
		proportion += prop_step
		if proportion >= 1.:
			proportion = 1.
			is_proportion_descending = true
			noise_2.seed = random.randi()
	mat.set_shader_parameter("noise_img_1_proportion", proportion)


func toggle_screen():
	var current_value:bool = mat.get_shader_parameter("show_screen")
	mat.set_shader_parameter("show_screen", !current_value)
