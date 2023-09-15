class_name ThrowingBall
extends RigidBody3D


@onready var collision_shape:CollisionShape3D = $CollisionShape3D
@onready var mesh:MeshInstance3D = $MeshInstance3D


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass


func set_radius(radius:float):
	collision_shape.shape.radius = radius
	mesh.mesh.radius = radius
	mesh.mesh.height = radius * 2.


func toggle_physics():
	collision_shape.disabled = !collision_shape.disabled


func throw(force:float):
	var throw_vector:Vector3 = global_transform.basis.z * -1. * force
	
	apply_central_impulse(throw_vector)
