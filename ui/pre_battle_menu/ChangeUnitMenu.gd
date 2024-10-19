extends StackBasedMenuScreen


export(PackedScene) var unit_item_container_packed_scene: PackedScene

export(String, FILE, "*.tscn") var view_unit_menu_scene: String

var _active_job: Job = null

onready var _list_container: VBoxContainer = $MarginContainer/VBoxContainer/ScrollContainer/MarginContainer/VBoxContainer


func _show_units() -> void:
	for child in _list_container.get_children():
		child.queue_free()
	
	var save_data: SaveData = GameData.save_data
	
	var active_jobs := []
	
	for index in save_data.active_units:
		active_jobs.push_back(save_data.jobs[index])
	
	for job in save_data.jobs:
		if not job in active_jobs:
			var unit_item_container: Control = unit_item_container_packed_scene.instance()
			
			_list_container.add_child(unit_item_container)
			
			# false: not draggable
			unit_item_container.initialize(job, false, _active_job)
			
			unit_item_container.set_change_button_as_choose_button()
			
			if unit_item_container.connect("change_button_clicked", self, "_on_UnitItemContainer_change_button_clicked", [job]) != OK:
				printerr("Error connecting signal")
			
			if unit_item_container.connect("unit_double_clicked", self, "_on_UnitItemContainer_unit_double_clicked", [job]) != OK:
				printerr("Failed to connect signal")


func on_add_to_tree(data: Object) -> void:
	# Data can be null when returning from unit view menu, so don't reassign
	# active job in that case
	if data == null:
		if _active_job == null:
			$MarginContainer/VBoxContainer/RemoveButton.disabled = true
	else:
		_active_job = data as Job
	
	_show_units()


func on_load() -> void:
	.on_load()
	
	$MarginContainer/VBoxContainer/ReturnButton.grab_focus()


func _on_UnitItemContainer_change_button_clicked(new_job: Job) -> void:
	var save_data: SaveData = GameData.save_data
	
	save_data.swap_jobs(_active_job, new_job)
	
	go_back()


func _on_UnitItemContainer_unit_double_clicked(job: Job) -> void:
	navigate(view_unit_menu_scene, job)


func _on_RemoveButton_pressed() -> void:
	var save_data: SaveData = GameData.save_data
	
	save_data.remove_job(_active_job)
	
	go_back()


func _on_ReturnButton_pressed() -> void:
	go_back()
