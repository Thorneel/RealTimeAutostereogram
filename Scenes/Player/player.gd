extends CharacterBody3D


const SPEED = 5.0
const JUMP_VELOCITY = 4.5

@onready var camera = $Camera3D
## The mesh on which the autostereogram is projected
@onready var proj_mesh:MeshInstance3D = $Camera3D/ScreenProjectionMesh
@onready var shoot_beam_mesh:MeshInstance3D = $Camera3D/ShootBeamMesh

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

var is_mouse_captured:bool


func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	is_mouse_captured = true


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
		shoot_beam_mesh.visible = !shoot_beam_mesh.visible;


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

	move_and_slide()
