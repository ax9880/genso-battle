extends Node

var save_data: SaveData
var config_file = ConfigFile.new()


func _ready() -> void:
	load_data()


# Loads data into globals
func load_data():
	var file: File = File.new()
	
	if file.file_exists(_get_config_file_path()):
		if _load_configs_file() != OK:
			push_error("Failed to load save data")
			
			_load_data_from_default_resource()
		else:
			_load_data_from_configs_file()
	else:
		_load_data_from_default_resource()


# Returns Error
func _load_configs_file():
	if OS.is_debug_build():
		return config_file.load(_get_config_file_path())
	else:
		return config_file.load_encrypted_pass(_get_config_file_path(), "password")


func _load_data_from_configs_file() -> void:
	save_data = SaveData.new()
	
	var unit_data: Array = config_file.get_value("unit_data", "jobs", null)
	
	for job_dictionary in unit_data:
		var job := Job.new()
		
		job.from_dictionary(job_dictionary)
		
		save_data.jobs.push_back(job)
	
	save_data.active_units = config_file.get_value("unit_data", "active_units", save_data.active_units)
	
	save_data.music_volume = config_file.get_value("settings", "music_volume", 1.0)
	save_data.sound_effects_volume = config_file.get_value("settings", "sound_effects_volume", 1.0)
	save_data.locale = config_file.get_value("settings", "locale", "")


func _load_data_from_default_resource() -> void:
	var default_save_data: SaveData = load("res://DefaultSaveData.tres")
	
	save_data = default_save_data.duplicate()
	
	save_data.jobs.clear()
	
	for default_job in default_save_data.jobs:
		var job = default_job.duplicate()
		
		job.stats = default_job.stats.duplicate()
		
		save_data.jobs.push_back(job)


func save_data() -> void:
	var jobs := []
	
	# Save jobs an array of dictionaries
	for job in save_data.jobs:
		jobs.push_back(job.to_dictionary())
	
	config_file.set_value("unit_data", "jobs", jobs)
	config_file.set_value("unit_data", "active_units", save_data.active_units)
	
	config_file.set_value("settings", "music_volume", save_data.music_volume)
	config_file.set_value("settings", "sound_effects_volume", save_data.sound_effects_volume)
	config_file.set_value("settings", "locale", save_data.locale)
	
	_save()


func _save() -> void:
	if OS.is_debug_build():
		if config_file.save(_get_config_file_path()) != OK:
			push_error("Failed to save data")
	else:
		if config_file.save_encrypted_pass(_get_config_file_path(), "password") != OK:
			push_error("Failed to save data")


func _get_config_file_path() -> String:
	if OS.get_name() == "HTML5":
		return "user://" + _build_config_file_path()
	else:
		return _build_config_file_path()


func _build_config_file_path() -> String:
	if OS.is_debug_build():
		return "save-data-debug.sav"
	else:
		return "save-data.sav"
