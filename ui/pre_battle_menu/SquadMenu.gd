extends StackBasedMenuScreen

export(PackedScene) var unit_item_packed_scene: PackedScene

export(String, FILE, "*.tscn") var change_unit_item_menu_scene: String
export(String, FILE, "*.tscn") var view_unit_menu_scene: String

onready var list_container: VBoxContainer = $MarginContainer/VBoxContainer/ScrollContainer/MarginContainer/VBoxContainer
onready var scene_container: MarginContainer = $MarginContainer

onready var return_button: Button = $MarginContainer/VBoxContainer/ReturnButton

var change_unit_menu: Control


func _ready():
	_show_active_units()


func on_load() -> void:
	.on_load()
	
	return_button.grab_focus()
	
	_show_active_units()


func on_add_to_tree(data: Object) -> void:
	.on_add_to_tree(data)
	
	_show_active_units()


func _show_active_units() -> void:
	var save_data: SaveData = GameData.save_data
	
	for child in list_container.get_children():
		child.queue_free()
	
	if save_data.active_units.size() < SaveData.MAX_SQUAD_SIZE:
		$MarginContainer/VBoxContainer/AddUnitButton.show()
	else:
		$MarginContainer/VBoxContainer/AddUnitButton.hide()
	
	for index in save_data.active_units:
		var job: Job = save_data.jobs[index]
		
		var unit_item: Control = unit_item_packed_scene.instance()
		
		list_container.add_child(unit_item)
		
		unit_item.initialize(job, true) # Is draggable
		
		if unit_item.connect("change_button_clicked", self, "_on_UnitItem_change_button_clicked", [job]) != OK:
			printerr("Failed to connect signal")
		
		if unit_item.connect("unit_dropped_on_unit", self, "_on_UnitItem_unit_dropped_on_unit") != OK:
			printerr("Failed to connect signal")
			
		if unit_item.connect("unit_double_clicked", self, "_on_UnitItem_unit_double_clicked", [job]) != OK:
			printerr("Failed to connect signal")
	
	# TODO: Show empty spaces to show that player can have up to six units
	$MarginContainer/VBoxContainer/ReturnButton.disabled = save_data.active_units.size() < SaveData.MIN_SQUAD_SIZE


func _on_UnitItem_change_button_clicked(job: Job) -> void:
	# TODO: When changing, compare available units to active unit
	# Green stat: Better (show difference? There might not be enough space)
	# Red stat: Worse
	# White stat: Same
	
	# TODO: Make it so you can't remove the three leaders (unless you complete the game?)
	
	# When you return, highlight the changed unit and play a sound
	navigate(change_unit_item_menu_scene, job)


func _on_UnitItem_unit_dropped_on_unit(target_unit_item: Control, dropped_unit_item: Control) -> void:
	var target_unit_item_position: int = _get_index_of_child(list_container, target_unit_item)
	var dropped_unit_item_position: int = _get_index_of_child(list_container, dropped_unit_item)
	
	assert(target_unit_item_position != -1)
	assert(dropped_unit_item_position != -1)
	
	list_container.move_child(dropped_unit_item, target_unit_item_position)
	list_container.move_child(target_unit_item, dropped_unit_item_position)
	
	var save_data: SaveData = GameData.save_data
	
	save_data.swap_jobs(target_unit_item.job, dropped_unit_item.job)
	
	$PlaceSound.play()


func _get_index_of_child(parent_node: Node, child_node: Node) -> int:
	var index: int = 0
	
	for child in parent_node.get_children():
		if child == child_node:
			return index
		
		index += 1
	
	return -1


func _on_ReturnButton_pressed() -> void:
	go_back()


func _on_AddUnitButton_pressed() -> void:
	_on_UnitItem_change_button_clicked(null)


func _on_UnitItem_unit_double_clicked(job: Job) -> void:
	navigate(view_unit_menu_scene, job)
