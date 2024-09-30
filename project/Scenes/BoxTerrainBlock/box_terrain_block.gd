extends MeshInstance3D

@onready var static_body:StaticBody3D = $StaticBody3D
@onready var collision_shape:CollisionShape3D = $StaticBody3D/CollisionShape3D


# Called when the node enters the scene tree for the first time.
func _ready():
	collision_shape.shape.size = mesh.size
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass
