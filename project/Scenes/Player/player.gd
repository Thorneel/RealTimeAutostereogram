extends CharacterBody3D


const SPEED = 5.0
const JUMP_VELOCITY = 4.5

const PUSH_FORCE_FACTOR = 10.

const MIN_THROW_FORCE = 2.
const MAX_THROW_FORCE = 20.
const THROW_FORCE_INCREASE_FACTOR = 5.


@onready var camera = $Camera3D
## The mesh on which the autostereogram is projected
@onready var proj_mesh:MeshInstance3D = $Camera3D/ScreenProjectionMesh
@onready var shoot_beam_mesh:MeshInstance3D = $Camera3D/ShootBeamMesh

var ball_scene = preload("res://Scenes/Ball/ball.tscn")
@onready var ball:RigidBody3D = $Camera3D/Weapon/Ball
@onready var ball_anim_player:AnimationPlayer = $Camera3D/Weapon/BallAnimationPlayer

@onready var launch_point:Node3D = $Camera3D/launch_point

@onready var remote_transfor_for_noise_camera:RemoteTransform3D = $Camera3D/RemoteTransformForNoiseCamera


# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

var is_mouse_captured:bool
var is_shooting:bool = false
var throw_force = MIN_THROW_FORCE


func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	is_mouse_captured = true
	proj_mesh.give_remote_transform_for_noise_cameras(remote_transfor_for_noise_camera)
	ball.toggle_physics()


func _unhandled_input(event):
	if (event is InputEventMouseMotion):
		if is_mouse_captured:
			rotate_y(-event.relative.x * .005)
			camera.rotate_x(-event.relative.y * .005)
			camera.rotation.x = clamp(camera.rotation.x, -PI/2, PI/2)
	
	elif (event is InputEventMouseButton):
		if Input.is_action_just_pressed("shoot"):
			start_shooting()
		
		if Input.is_action_just_released("shoot"):
			stop_shooting()
		
		if Input.is_action_just_pressed("alt_shoot"):
			launch_ball(true)
		
	elif (event is InputEventKey):
		if Input.is_action_just_pressed("laser"):
			toggle_laser()
		
		if Input.is_action_just_pressed("use"):
			use()


func _physics_process(delta):
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Handle Jump.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir = Input.get_vector("left", "right", "forwards", "backwards")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)
	
	# after calling move_and_slide()
	for i in get_slide_collision_count():
		var c = get_slide_collision(i)
		var collider = c.get_collider()
		if collider.has_method("apply_central_impulse"):
			collider.apply_central_impulse(-c.get_normal() * PUSH_FORCE_FACTOR)
			
	
	if (is_shooting):
		throw_force += delta * THROW_FORCE_INCREASE_FACTOR
	else:
		if input_dir != Vector2.ZERO and is_on_floor():
			ball_anim_player.play("move")
		else:
			ball_anim_player.play("RESET")
	
	move_and_slide()
	
#	# TODO remove after testing
#	if (is_shooting):
#		launch_ball()


func start_shooting():
	# FIXME why doesn't the second anim play
#	ball_anim_player.play("prepare_throw")
#	ball_anim_player.queue("hold_throw")
	ball_anim_player.play("hold_throw")
	throw_force = MIN_THROW_FORCE
	is_shooting = true


func stop_shooting():
	launch_ball()
	is_shooting = false


func launch_ball(big:bool = false):
	ball_anim_player.play("after_throwing")
	var new_ball:ThrowingBall = ball_scene.instantiate()
	new_ball.set_linear_velocity(get_real_velocity())
	get_parent().add_child(new_ball)
	new_ball.set_global_transform(launch_point.get_global_transform())
	if (big):
		new_ball.set_radius(0.3)
		new_ball.set_mass(10.)
	
	new_ball.ignore_body_until_out(self)
	new_ball.throw(throw_force)


func toggle_laser():
	shoot_beam_mesh.visible = !shoot_beam_mesh.visible;


func use():
	pass
