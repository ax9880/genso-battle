extends StackBasedMenuScreen

export(PackedScene) var unit_item_packed_scene: PackedScene

export(String, FILE, "*.tscn") var change_unit_item_menu_scene: String

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
		
		unit_item.initialize(job)
		
		unit_item.connect("change_button_clicked", self, "_on_UnitItem_change_button_clicked", [job])
		unit_item.connect("view_button_clicked", self, "_on_UnitItem_view_button_clicked", [job])
	
	# TODO: Show empty spaces to show that player can have up to six units
	$MarginContainer/VBoxContainer/ReturnButton.disabled = save_data.active_units.size() < SaveData.MIN_SQUAD_SIZE


func _on_UnitItem_change_button_clicked(job: Job) -> void:
	navigate(change_unit_item_menu_scene, job)


func _on_UnitItem_view_button_clicked(job: Job) -> void:
	# TODO: Show unit view
	# And reuse this screen for viewing enemy stats during battle
	print("view")


func _on_ReturnButton_pressed() -> void:
	go_back()


func _on_AddUnitButton_pressed() -> void:
	_on_UnitItem_change_button_clicked(null)
