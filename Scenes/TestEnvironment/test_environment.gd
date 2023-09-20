extends Node3D

@onready var ball:ThrowingBall = $Ball


# Called when the node enters the scene tree for the first time.
func _ready():
	ball.set_radius(1.)
	ball.set_mass(100.)
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass

