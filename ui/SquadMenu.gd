extends Control


export(PackedScene) var unit_item_packed_scene: PackedScene

onready var list_container: VBoxContainer = $MarginContainer/VBoxContainer/ScrollContainer/VBoxContainer

func _ready():
	var save_data: SaveData = GameData.save_data
	
	for child in list_container.get_children():
		child.queue_free()
	
	for index in save_data.active_units:
		var job: Job = save_data.jobs[index]
		
		var unit_item: Control = unit_item_packed_scene.instance()
		
		list_container.add_child(unit_item)
		
		unit_item.initialize(job)
		
		unit_item.connect("change_button_clicked", self, "_on_UnitItem_change_button_clicked", [job, index])
		unit_item.connect("view_button_clicked", self, "_on_UnitItem_view_button_clicked", [job, index])


func _on_UnitItem_change_button_clicked(job: Job, index: int) -> void:
	# TODO: navigate
	pass


func _on_UnitItem_view_button_clicked(job: Job, index: int) -> void:
	# TODO: Show unit view
	# And reuse this screen for viewing enemy stats during battle
	print("view")


func _on_ReturnButton_pressed() -> void:
	var _error = get_tree().change_scene("res://ui/PreBattleMenu.tscn")
