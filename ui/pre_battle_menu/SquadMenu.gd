extends StackBasedMenuScreen

export(PackedScene) var unit_item_packed_scene: PackedScene

export(String, FILE, "*.tscn") var change_unit_item_menu_scene: String
export(String, FILE, "*.tscn") var view_unit_menu_scene: String

onready var list_container: VBoxContainer = $MarginContainer/VBoxContainer/ScrollContainer/MarginContainer/VBoxContainer
onready var scene_container: MarginContainer = $MarginContainer

onready var return_button: Button = $MarginContainer/VBoxContainer/ReturnButton

var change_unit_menu: Control

var changed_job_reference: JobReference = null
var index_of_changed_job_reference: int = -1
var unit_item_to_highlight: Control = null
var number_of_units_before_change: int = -1


func _ready() -> void:
	var save_data: SaveData = GameData.save_data
	
	number_of_units_before_change = save_data.active_units.size()
	
	_show_active_units()


func on_load() -> void:
	.on_load()
	
	return_button.grab_focus()
	
	_highlight_changed_unit()


func on_add_to_tree(data: Object) -> void:
	.on_add_to_tree(data)
	
	_show_active_units()


func _show_active_units() -> void:
	print("Showing active units")
	
	var save_data: SaveData = GameData.save_data
	
	for child in list_container.get_children():
		child.queue_free()
	
	if save_data.active_units.size() < SaveData.MAX_SQUAD_SIZE:
		$MarginContainer/VBoxContainer/AddUnitButton.show()
	else:
		$MarginContainer/VBoxContainer/AddUnitButton.hide()
	
	# store job reference and index in active units (0 - 6)
	# when showing active units
	# check if active_units[index of changed job] != job reference
	# if so then the unit was changed and you should highlight it
	# and set the parameters back to null and -1
	
	for i in range(save_data.active_units.size()):
		var index: int = save_data.active_units[i]
		
		var job_reference: JobReference = save_data.job_references[index]
		
		var unit_item: Control = unit_item_packed_scene.instance()
		
		list_container.add_child(unit_item)
		
		unit_item.initialize(job_reference, true) # Is draggable
		
		if unit_item.connect("change_button_clicked", self, "_on_UnitItem_change_button_clicked", [job_reference, i]) != OK:
			printerr("Failed to connect signal")
		
		if unit_item.connect("unit_dropped_on_unit", self, "_on_UnitItem_unit_dropped_on_unit") != OK:
			printerr("Failed to connect signal")
			
		if unit_item.connect("unit_double_clicked", self, "_on_UnitItem_unit_double_clicked", [job_reference]) != OK:
			printerr("Failed to connect signal")
		
		if changed_job_reference != null && index_of_changed_job_reference != -1:
			if index_of_changed_job_reference == i and changed_job_reference != job_reference:
				unit_item_to_highlight = unit_item
	
	
	# TODO: Show empty spaces to show that player can have up to six units
	$MarginContainer/VBoxContainer/ReturnButton.disabled = save_data.active_units.size() < SaveData.MIN_SQUAD_SIZE


func _on_UnitItem_change_button_clicked(job_reference: JobReference, container_index: int) -> void:
	changed_job_reference = job_reference
	index_of_changed_job_reference = container_index
	
	var save_data: SaveData = GameData.save_data
	
	number_of_units_before_change = save_data.active_units.size()
	
	navigate(change_unit_item_menu_scene, job_reference)


func _on_UnitItem_unit_dropped_on_unit(target_unit_item: Control, dropped_unit_item: Control) -> void:
	var target_unit_item_position: int = _get_index_of_child(list_container, target_unit_item)
	var dropped_unit_item_position: int = _get_index_of_child(list_container, dropped_unit_item)
	
	assert(target_unit_item_position != -1)
	assert(dropped_unit_item_position != -1)
	
	list_container.move_child(dropped_unit_item, target_unit_item_position)
	list_container.move_child(target_unit_item, dropped_unit_item_position)
	
	var save_data: SaveData = GameData.save_data
	
	save_data.swap_job_references(target_unit_item.job_reference, dropped_unit_item.job_reference)
	
	$PlaceSound.play()


func _get_index_of_child(parent_node: Node, child_node: Node) -> int:
	var index: int = 0
	
	for child in parent_node.get_children():
		if child == child_node:
			return index
		
		index += 1
	
	return -1


func _highlight_changed_unit() -> void:
	var save_data: SaveData = GameData.save_data
	
	var number_of_units_after_change: int = save_data.active_units.size()
	
	if unit_item_to_highlight != null:
		if number_of_units_before_change > number_of_units_after_change:
			print("Unit removed")
		else:
			unit_item_to_highlight.highlight()
		
		unit_item_to_highlight = null
		
		changed_job_reference = null
		index_of_changed_job_reference = -1
		number_of_units_before_change = number_of_units_after_change
	else:
		# If a unit was added, highlight the last child
		if number_of_units_before_change < number_of_units_after_change:
			assert(list_container.get_child_count() > 0)
			
			list_container.get_child(list_container.get_child_count() - 1).highlight()


func _on_ReturnButton_pressed() -> void:
	go_back()


func _on_AddUnitButton_pressed() -> void:
	_on_UnitItem_change_button_clicked(null, -1)


func _on_UnitItem_unit_double_clicked(job_reference: JobReference) -> void:
	navigate(view_unit_menu_scene, job_reference)
