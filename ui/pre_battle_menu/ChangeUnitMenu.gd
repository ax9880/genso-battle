extends StackBasedMenuScreen


export(PackedScene) var unit_item_container_packed_scene: PackedScene

export(String, FILE, "*.tscn") var view_unit_menu_scene: String

onready var list_container: VBoxContainer = $MarginContainer/VBoxContainer/ScrollContainer/MarginContainer/VBoxContainer


var active_job_reference: JobReference = null


func _show_units() -> void:
	for child in list_container.get_children():
		child.queue_free()
	
	var save_data: SaveData = GameData.save_data
	
	var active_job_references := []
	
	for index in save_data.active_units:
		active_job_references.push_back(save_data.job_references[index])
	
	for job_reference in save_data.job_references:
		if not job_reference in active_job_references:
			var unit_item_container: Control = unit_item_container_packed_scene.instance()
			
			list_container.add_child(unit_item_container)
			
			# false: not draggable
			unit_item_container.initialize(job_reference, false, active_job_reference)
			
			unit_item_container.set_change_button_as_choose_button()
			
			if unit_item_container.connect("change_button_clicked", self, "_on_UnitItemContainer_change_button_clicked", [job_reference]) != OK:
				printerr("Error connecting signal")
			
			if unit_item_container.connect("unit_double_clicked", self, "_on_UnitItemContainer_unit_double_clicked", [job_reference]) != OK:
				printerr("Failed to connect signal")


func on_add_to_tree(data: Object) -> void:
	# Data can be null when returning from unit view menu, so don't reassign
	# active job_reference in that case
	if data == null:
		if active_job_reference == null:
			$MarginContainer/VBoxContainer/RemoveButton.disabled = true
	else:
		active_job_reference = data as JobReference
	
	_show_units()


func on_load() -> void:
	.on_load()
	
	$MarginContainer/VBoxContainer/ReturnButton.grab_focus()


func _on_UnitItemContainer_change_button_clicked(new_job_reference: JobReference) -> void:
	var save_data: SaveData = GameData.save_data
	
	save_data.swap_job_references(active_job_reference, new_job_reference)
	
	go_back()


func _on_UnitItemContainer_unit_double_clicked(job_reference: JobReference) -> void:
	navigate(view_unit_menu_scene, job_reference)


func _on_RemoveButton_pressed() -> void:
	var save_data: SaveData = GameData.save_data
	
	save_data.remove_job_reference(active_job_reference)
	
	go_back()


func _on_ReturnButton_pressed() -> void:
	go_back()
