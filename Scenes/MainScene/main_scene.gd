extends Node


@onready var menu:Control = $Menu
@onready var test_environment:Node3D = $TestEnvironment


func _unhandled_input(_event):
	
	if Input.is_action_just_pressed("toggle_autostereogram"):
		Events.emit_signal("toggle_autostereogram")
	
	if Input.is_action_just_pressed("toggle_screen_in_autostereogram"):
		Events.emit_signal("toggle_image_overlay")
	
	if Input.is_action_just_pressed("menu"):
		menu.toggle()


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass
