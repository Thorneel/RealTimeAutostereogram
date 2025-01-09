extends Node



#const DEFAULT_CONFIG_FILE_PATH:String = ""
const CONFIG_FILE_NAME:String = "config.cfg"
const CONFIG_MAIN_SETTING_STRING = "main_setting"
const CONFIG_EYE_DISTANCE_STRING:String = "eye_distance"
const CONFIG_STATIC_NOISE_STRING:String = "static_noise"
const CONFIG_WALL_EYED_STRING:String = "wall_eyed"

var config:ConfigFile = ConfigFile.new()
var config_file_path:String = CONFIG_FILE_NAME
var _was_file_already_there:bool = false


# Called when the node enters the scene tree for the first time.
func _ready():
	_initialize_config()


## GENERAL

func _initialize_config():
	var err = config.load(config_file_path)
	if (ERR_FILE_NOT_FOUND == err):
		var err2 = config.save(config_file_path)
		if (err2 != OK):
			print("Error while creating file: " + str(err2))
	elif (OK == err):
		_was_file_already_there = true
	else:
		print("Error while loading file: " + str(err))


func _save():
	var err = config.save(config_file_path)
	if (err != OK):
		print("Error while saving config: " + str(err))


# EYE DISTANCE

func get_eye_distance(default_eye_distance:float):
	if _was_file_already_there:
		return config.get_value(CONFIG_MAIN_SETTING_STRING, 
				CONFIG_EYE_DISTANCE_STRING)
	else:
		save_eye_distance(default_eye_distance)
		return default_eye_distance


func save_eye_distance(eye_distance:float):
	config.set_value(CONFIG_MAIN_SETTING_STRING, CONFIG_EYE_DISTANCE_STRING, eye_distance)
	_save()


# STATIC NOISE

func get_static_noise(default_static_noise:bool):
	if _was_file_already_there:
		var new_static_noise = config.get_value(CONFIG_MAIN_SETTING_STRING, 
				CONFIG_STATIC_NOISE_STRING)
		return new_static_noise
	else:
		save_static_noise(default_static_noise)
		return save_static_noise


func save_static_noise(static_noise:bool):
	config.set_value(CONFIG_MAIN_SETTING_STRING, CONFIG_STATIC_NOISE_STRING, static_noise)
	_save()


# WALL_EYED

func get_wall_eyed(default_wall_eyed:bool):
	if _was_file_already_there:
		var new_wall_eyed = config.get_value(CONFIG_MAIN_SETTING_STRING, 
				CONFIG_WALL_EYED_STRING)
		return new_wall_eyed
	else:
		save_wall_eyed(default_wall_eyed)
		return save_wall_eyed


func save_wall_eyed(wall_eyed:bool):
	config.set_value(CONFIG_MAIN_SETTING_STRING, CONFIG_WALL_EYED_STRING, wall_eyed)
	_save()
	
