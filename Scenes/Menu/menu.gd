extends Control


@onready var tab_container:TabContainer = $TabContainer
@onready var confirm_quit:ConfirmationDialog = $QuitConfirmationDialog


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func toggle():
	if (is_visible()):
		hide()
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		get_tree().paused = false
	else:
		tab_container.set_current_tab(0)
		show()
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		get_tree().paused = true


func _on_return_button_pressed():
	hide()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	get_tree().paused = false


func _on_quit_button_pressed():
	confirm_quit.show()


func _on_quit_confirmation_dialog_confirmed():
	get_tree().quit()
