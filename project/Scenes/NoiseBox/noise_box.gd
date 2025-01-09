extends Node3D

@onready var front_mesh:MeshInstance3D = $Front
@onready var front_material:StandardMaterial3D = front_mesh.get_active_material(0)
@onready var front_texture:Texture2D = front_material.albedo_texture
@onready var noise:Noise = front_texture.get_noise()

func get_noise() -> Noise:
	return noise
