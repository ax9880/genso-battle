extends Node

const _UNIT_DATA_SECTION: String = "unit_data"
const _SETTINGS_SECTION: String = "settings"

const _JOB_REFERENCES_KEY: String = "job_references"

var save_data: SaveData
var config_file = ConfigFile.new()


func _ready() -> void:
	load_data()


# Loads data into globals
func load_data():
	if save_data != null:
		return
	
	var file: File = File.new()
	
	if file.file_exists(_get_config_file_path()):
		if _load_config_file() != OK:
			push_error("Failed to load save data")
			
			_load_data_from_default_resource()
		else:
			_load_data_from_configs_file()
	else:
		_load_data_from_default_resource()


# Returns Error
func _load_config_file():
	if OS.is_debug_build():
		return config_file.load(_get_config_file_path())
	else:
		return config_file.load_encrypted_pass(_get_config_file_path(), "password")


func _load_data_from_configs_file() -> void:
	save_data = SaveData.new()
	
	var unit_data: Array = config_file.get_value(_UNIT_DATA_SECTION, _JOB_REFERENCES_KEY, null)
	
	for job_reference_dictionary in unit_data:
		var job_reference := JobReference.new()
		
		job_reference.from_dictionary(job_reference_dictionary)
		
		save_data.job.push_back(job_reference)
	
	save_data.active_units = config_file.get_value(_UNIT_DATA_SECTION, "active_units", save_data.active_units)
	
	save_data.music_volume = config_file.get_value(_SETTINGS_SECTION, "music_volume", 1.0)
	save_data.sound_effects_volume = config_file.get_value(_SETTINGS_SECTION, "sound_effects_volume", 1.0)
	save_data.locale = config_file.get_value(_SETTINGS_SECTION, "locale", "")


func _load_data_from_default_resource() -> void:
	var default_save_data: SaveData = load("res://DefaultSaveData.tres")
	
	save_data = default_save_data.duplicate()


func save() -> void:
	var jobs_references := []
	
	# Save jobs references as an array of dictionaries. Preserve the order
	# so that active_units can point to the correct units.
	for job_reference in save_data.jobs_references:
		jobs_references.push_back(job_reference.to_dictionary())
	
	config_file.set_value(_UNIT_DATA_SECTION, _JOB_REFERENCES_KEY, jobs_references)
	config_file.set_value(_UNIT_DATA_SECTION, "active_units", save_data.active_units)
	
	config_file.set_value(_SETTINGS_SECTION, "music_volume", save_data.music_volume)
	config_file.set_value(_SETTINGS_SECTION, "sound_effects_volume", save_data.sound_effects_volume)
	config_file.set_value(_SETTINGS_SECTION, "locale", save_data.locale)
	
	_save_config_file()


func _save_config_file() -> void:
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
