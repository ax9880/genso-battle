extends StackBasedMenuScreen


export(PackedScene) var unit_item_packed_scene: PackedScene


onready var list_container: VBoxContainer = $MarginContainer/VBoxContainer/ScrollContainer/MarginContainer/VBoxContainer


var active_job: Job = null


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
			var unit_item: Control = unit_item_packed_scene.instance()
			
			list_container.add_child(unit_item)
			
			# false: not draggable
			unit_item.initialize(job, false, active_job)
			
			unit_item.hide_view_button()
			unit_item.hide_change_button()
			
			var _error = unit_item.connect("unit_selected", self, "_on_UnitItemContainer_unit_selected", [job])


func on_add_to_tree(data: Object) -> void:
	active_job = data as Job
	
	if active_job == null:
		$MarginContainer/VBoxContainer/RemoveButton.disabled = true
	
	_show_units()
	
	_show_active_unit()


func on_load() -> void:
	.on_load()
	
	# TODO: Hide RemoveButton if active job is null, or move that to SquadMenu
	# TODO: Pass data when node is added to tree so that it has time to
	# set up the UI before the fade out finishes
	
	$MarginContainer/VBoxContainer/ReturnButton.grab_focus()


func _on_UnitItemContainer_unit_selected(new_job: Job) -> void:
	var save_data: SaveData = GameData.save_data
	
	save_data.swap_jobs(active_job, new_job)
	
	go_back()


func _on_RemoveButton_pressed() -> void:
	if active_job != null:
		var save_data: SaveData = GameData.save_data
		
		var index: int = save_data.jobs.find(active_job)
		
		assert(index != -1)
		
		save_data.active_units.erase(index)
	
	go_back()


func _on_ReturnButton_pressed() -> void:
	go_back()
