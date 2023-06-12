extends Control


export(PackedScene) var unit_item_packed_scene: PackedScene
export(PackedScene) var change_unit_menu_packed_scene: PackedScene

onready var list_container: VBoxContainer = $MarginContainer/VBoxContainer/ScrollContainer/VBoxContainer
onready var scene_container: MarginContainer = $MarginContainer

var change_unit_menu: Control


func _ready():
	_show_active_units()


func _show_active_units() -> void:
	var save_data: SaveData = GameData.save_data
	
	for child in list_container.get_children():
		child.queue_free()
	
	if save_data.active_units.size() < 6:
		$MarginContainer/VBoxContainer/AddUnitButton.show()
	else:
		$MarginContainer/VBoxContainer/AddUnitButton.hide()
	
	for index in save_data.active_units:
		var job: Job = save_data.jobs[index]
		
		var unit_item: Control = unit_item_packed_scene.instance()
		
		list_container.add_child(unit_item)
		
		unit_item.initialize(job)
		
		unit_item.connect("change_button_clicked", self, "_on_UnitItem_change_button_clicked", [job, index])
		unit_item.connect("view_button_clicked", self, "_on_UnitItem_view_button_clicked", [job, index])
	
	$MarginContainer/VBoxContainer/ReturnButton.disabled = save_data.active_units.size() < 2


func _on_UnitItem_change_button_clicked(job: Job, index: int) -> void:
	change_unit_menu = change_unit_menu_packed_scene.instance()
	
	scene_container.hide()
	
	add_child(change_unit_menu)
	
	change_unit_menu.connect("job_changed", self, "_on_ChangeUnitMenu_job_changed", [job])
	change_unit_menu.connect("job_removed", self, "_on_ChangeUnitMenu_job_removed", [job])
	change_unit_menu.connect("return_pressed", self, "_on_ChangeUnitMenu_return_pressed")


func _on_UnitItem_view_button_clicked(job: Job, index: int) -> void:	
	# TODO: Show unit view
	# And reuse this screen for viewing enemy stats during battle
	print("view")


func _pop_change_unit_menu() -> void:
	_show_active_units()
	
	change_unit_menu.queue_free()
	scene_container.show()


func _on_ReturnButton_pressed() -> void:
	var _error = get_tree().change_scene("res://ui/PreBattleMenu.tscn")


func _on_ChangeUnitMenu_job_changed(new_job: Job, old_job: Job) -> void:
	var save_data: SaveData = GameData.save_data
	
	var index_of_old_job: int = save_data.jobs.find(old_job)
	
	assert(index_of_old_job != -1)
	
	#var index_of_new_job
	var index: int = save_data.active_units.find(index_of_old_job)
	
	assert(index != -1)
	
	var index_of_new_job: int = save_data.jobs.find(new_job)
	
	assert(index_of_new_job != -1)
	
	save_data.active_units[index] = index_of_new_job
	
	_pop_change_unit_menu()


func _on_ChangeUnitMenu_job_removed(job: Job) -> void:
	var save_data: SaveData = GameData.save_data
	
	var index: int = save_data.jobs.find(job)
	
	assert(index != -1)
	
	save_data.active_units.erase(index)
	
	_pop_change_unit_menu()


func _on_ChangeUnitMenu_return_pressed() -> void:
	_pop_change_unit_menu()


func _on_AddUnitButton_pressed() -> void:
	pass # Replace with function body.
