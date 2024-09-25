extends Node


@onready var menu:Control = $Menu
@onready var test_environment:Node3D = $TestEnvironment

var test_env_scene = preload("res://Scenes/TestEnvironment/test_environment.tscn")


func _unhandled_input(_event):
	
	if Input.is_action_just_pressed("toggle_autostereogram"):
		Events.emit_signal("toggle_autostereogram")
	
	if Input.is_action_just_pressed("toggle_screen_in_autostereogram"):
		Events.emit_signal("toggle_image_overlay")
	
	if Input.is_action_just_pressed("toggle_static_noise"):
		Events.emit_signal("toggle_static_noise")
	
	if Input.is_action_just_pressed("menu"):
		menu.toggle()


# Called when the node enters the scene tree for the first time.
func _ready():
	Events.connect("reset_environment", Callable(self, "_on_reset_environment"))
	
	menu.toggle()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass


func _on_reset_environment():
	remove_child(test_environment)
	test_environment = test_env_scene.instantiate()
	add_child(test_environment)
	
