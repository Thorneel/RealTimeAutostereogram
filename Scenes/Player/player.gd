extends CharacterBody3D


const SPEED = 5.0
const JUMP_VELOCITY = 4.5

const MIN_THROW_FORCE = 10.
const MAX_THROW_FORCE = 100.
const THROW_FORCE_INCREASE_FACTOR = 20.


@onready var camera = $Camera3D
## The mesh on which the autostereogram is projected
@onready var proj_mesh:MeshInstance3D = $Camera3D/ScreenProjectionMesh
@onready var shoot_beam_mesh:MeshInstance3D = $Camera3D/ShootBeamMesh

var ball_scene = preload("res://Scenes/Ball/ball.tscn")
@onready var ball:RigidBody3D = $Camera3D/Weapon/Ball
@onready var ball_anim_player:AnimationPlayer = $Camera3D/Weapon/BallAnimationPlayer

@onready var launch_point:Node3D = $Camera3D/launch_point


# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

var is_mouse_captured:bool
var is_shooting:bool = false
var throw_force = MIN_THROW_FORCE



func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	is_mouse_captured = true
	ball.toggle_physics()


func _unhandled_input(event):
	if Input.is_action_just_pressed("mouse_mode"):
		if (Input.mouse_mode == Input.MOUSE_MODE_CAPTURED):
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			is_mouse_captured = false
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			is_mouse_captured = true
	
	if is_mouse_captured and event is InputEventMouseMotion:
		rotate_y(-event.relative.x * .005)
		camera.rotate_x(-event.relative.y * .005)
		camera.rotation.x = clamp(camera.rotation.x, -PI/2, PI/2)
	
	if Input.is_action_just_pressed("toggle_autostereogram"):
		proj_mesh.visible = !proj_mesh.visible;
	
	if Input.is_action_just_pressed("toggle_screen_in_autostereogram"):
		proj_mesh.toggle_screen()
	
	if Input.is_action_just_pressed("shoot"):
		start_shooting()
	
	if Input.is_action_just_released("shoot"):
		stop_shooting()
	
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


func launch_ball():
	ball_anim_player.play("after_throwing")
	var new_ball:ThrowingBall = ball_scene.instantiate()
	get_parent().add_child(new_ball)
#	new_ball.global_position = launch_point.global_position
	new_ball.global_transform = launch_point.global_transform
	launch_point.get_global_transform()
	new_ball.throw(throw_force)
	#TODO add correct impulse
#	new_ball.apply_central_impulse(Vector3(10., 10., 10.))


func toggle_laser():
	shoot_beam_mesh.visible = !shoot_beam_mesh.visible;


func use():
	pass
