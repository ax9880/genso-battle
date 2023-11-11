extends StackBasedMenuScreen


export(PackedScene) var unit_item_container_packed_scene: PackedScene

export(String, FILE, "*.tscn") var view_unit_menu_scene: String

onready var list_container: VBoxContainer = $MarginContainer/VBoxContainer/ScrollContainer/MarginContainer/VBoxContainer


var active_job: Job = null


# TODO: Show active unit so that player can compare it?
func _show_active_unit() -> void:
	pass


func _show_units() -> void:
	for child in list_container.get_children():
		child.queue_free()
	
	var save_data: SaveData = GameData.save_data
	
	var active_jobs := []
	
	for index in save_data.active_units:
		active_jobs.push_back(save_data.jobs[index])
	
	for job in save_data.jobs:
		if not job in active_jobs:
			var unit_item_container: Control = unit_item_container_packed_scene.instance()
			
			list_container.add_child(unit_item_container)
			
			# false: not draggable
			unit_item_container.initialize(job, false, active_job)
			
			unit_item_container.set_change_button_as_choose_button()
			
			if unit_item_container.connect("change_button_clicked", self, "_on_UnitItemContainer_change_button_clicked", [job]) != OK:
				printerr("Error connecting signal")
			
			if unit_item_container.connect("unit_double_clicked", self, "_on_UnitItemContainer_unit_double_clicked", [job]) != OK:
				printerr("Failed to connect signal")


func on_add_to_tree(data: Object) -> void:
	# Data can be null when returning from unit view menu, so don't reassign
	# active job in that case
	if data == null:
		if active_job == null:
			$MarginContainer/VBoxContainer/RemoveButton.disabled = true
	else:
		active_job = data as Job
	
	_show_units()
	
	_show_active_unit()


func on_load() -> void:
	.on_load()
	
	# TODO: Hide RemoveButton if active job is null, or move that to SquadMenu
	# TODO: Pass data when node is added to tree so that it has time to
	# set up the UI before the fade out finishes
	
	$MarginContainer/VBoxContainer/ReturnButton.grab_focus()


func _on_UnitItemContainer_change_button_clicked(new_job: Job) -> void:
	var save_data: SaveData = GameData.save_data
	
	save_data.swap_jobs(active_job, new_job)
	
	go_back()


func _on_UnitItemContainer_unit_double_clicked(job: Job) -> void:
	navigate(view_unit_menu_scene, job)


func _on_RemoveButton_pressed() -> void:
	if active_job != null:
		var save_data: SaveData = GameData.save_data
		
		var index: int = save_data.jobs.find(active_job)
		
		assert(index != -1)
		
		save_data.active_units.erase(index)
	
	go_back()


func _on_ReturnButton_pressed() -> void:
	go_back()
