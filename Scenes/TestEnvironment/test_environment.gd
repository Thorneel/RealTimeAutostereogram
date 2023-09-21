extends Node3D

@onready var ball:ThrowingBall = $Ball
@onready var player:CharacterBody3D = $Player

var initial_player_position:Vector3
var initial_player_rotation:Vector3

# Called when the node enters the scene tree for the first time.
func _ready():
	Events.connect("reset_player_position", Callable(self, "_on_reset_player_position"))
	initial_player_position = player.get_position()
	initial_player_rotation = player.get_rotation()
	
	ball.set_radius(1.)
	ball.set_mass(100.)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass


func _on_reset_player_position():
	player.set_position(initial_player_position)
	player.set_rotation(initial_player_rotation)
