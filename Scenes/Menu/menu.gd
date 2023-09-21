extends Control


const EYE_DISTANCE_MIN:float = 20.
const EYE_DISTANCE_MAX:float = 512.

#const DEFAULT_CONFIG_FILE_PATH:String = ""
const CONFIG_FILE_NAME:String = "config.cfg"
const CONFIG_MAIN_SETTING_STRING = "main_setting"
const CONFIG_EYE_DISTANCE_STRING:String = "eye_distance"


@onready var tab_container:TabContainer = $TabContainer
@onready var confirm_quit:ConfirmationDialog = $QuitConfirmationDialog

@onready var eye_distance_progress_bar:ProgressBar = $TabContainer/Settings/MarginContainer/SettingContainer/HBoxContainer/VBoxContainer/EyeDistanceProgressBar
@onready var eye_distance_scroll_bar:HScrollBar = $TabContainer/Settings/MarginContainer/SettingContainer/HBoxContainer/VBoxContainer/EyeDistanceScrollBar
@onready var eye_distance_value_label:Label = $TabContainer/Settings/MarginContainer/SettingContainer/HBoxContainer/EyeDistanceValueLabel


var config:ConfigFile = ConfigFile.new()
var config_file_path:String = CONFIG_FILE_NAME

var eye_distance:float = 160.


## INITIALIZATION ##

# Called when the node enters the scene tree for the first time.
func _ready():
	_initialize_config()
	_initialize_values()


## Config

func _initialize_config():
	var err = config.load(config_file_path)
	if (ERR_FILE_NOT_FOUND == err):
		var err2 = config.save(config_file_path)
		if (err2 != OK):
			print("Error while creating file: " + str(err2))
	elif (OK == err):
		_load_config_values()
	else:
		print("Error while loading file: " + str(err))


func _load_config_values():
	var new_eye_distance = config.get_value(CONFIG_MAIN_SETTING_STRING, 
			CONFIG_EYE_DISTANCE_STRING)
	if (new_eye_distance is float 
			and new_eye_distance > EYE_DISTANCE_MIN 
			and new_eye_distance < EYE_DISTANCE_MAX):
		eye_distance = new_eye_distance


## Initial values

func _initialize_values():
	eye_distance_progress_bar.min_value = EYE_DISTANCE_MIN
	eye_distance_progress_bar.max_value = EYE_DISTANCE_MAX
	eye_distance_scroll_bar.min_value = EYE_DISTANCE_MIN
	eye_distance_scroll_bar.max_value = EYE_DISTANCE_MAX
	_change_eye_distance(eye_distance)



## PROCESSES ##

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass


## PUBLIC ##

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


## PRIVATE ##

func _save_config():
	var err = config.save(config_file_path)
	if (err != OK):
		print("Error while saving config: " + str(err))


func _change_eye_distance(new_eye_distance:float):
	if (new_eye_distance <= EYE_DISTANCE_MAX and new_eye_distance >= EYE_DISTANCE_MIN):
		eye_distance = new_eye_distance
		Events.emit_signal("set_eye_distance", eye_distance)
	
	eye_distance_progress_bar.set_value(eye_distance)
	eye_distance_scroll_bar.set_value(eye_distance)
	eye_distance_value_label.set_text(str(eye_distance))
	
	config.set_value(CONFIG_MAIN_SETTING_STRING, 
			CONFIG_EYE_DISTANCE_STRING, eye_distance)
	_save_config()


## SIGNALS ##

func _on_return_button_pressed():
	hide()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	get_tree().paused = false


func _on_quit_button_pressed():
	confirm_quit.show()


func _on_quit_confirmation_dialog_confirmed():
	get_tree().quit()


## Eye distance signals

func _on_minus_10_button_pressed():
	var new_eye_distance = max(eye_distance - 10., EYE_DISTANCE_MIN)
	_change_eye_distance(new_eye_distance)


func _on_minus_1_button_pressed():
	var new_eye_distance = max(eye_distance - 1., EYE_DISTANCE_MIN)
	_change_eye_distance(new_eye_distance)


func _on_plus_1_button_pressed():
	var new_eye_distance = min(eye_distance + 1., EYE_DISTANCE_MAX)
	_change_eye_distance(new_eye_distance)


func _on_plus_10_button_pressed():
	var new_eye_distance = min(eye_distance + 10., EYE_DISTANCE_MAX)
	_change_eye_distance(new_eye_distance)


func _on_eye_distance_scroll_bar_value_changed(new_eye_distance):
	_change_eye_distance(new_eye_distance)
