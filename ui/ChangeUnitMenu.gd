extends Control


export(PackedScene) var unit_item_packed_scene: PackedScene


onready var list_container: VBoxContainer = $MarginContainer/VBoxContainer/ScrollContainer/VBoxContainer


signal job_changed(new_job)
signal job_removed()
signal return_pressed


func _ready() -> void:
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
			
			unit_item.initialize(job)
			
			# TODO: Hide other button
			unit_item.connect("change_button_clicked", self, "_on_UnitItemContainer_change_button_clicked", [job])


func _on_UnitItemContainer_change_button_clicked(job: Job) -> void:
	emit_signal("job_changed", job)


func _on_RemoveButton_pressed() -> void:
	emit_signal("job_removed")


func _on_ReturnButton_pressed() -> void:
	emit_signal("return_pressed")
