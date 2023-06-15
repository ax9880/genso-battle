extends OptionButton


const CLICK_MODE_INDEX: int = 0
const HOLD_MODE_INDEX: int = 1

signal drag_mode_changed(drag_mode)


func _ready() -> void:
	# TODO: Store and load this parameter
	# TODO: update the option shown depending on the parameter
	#var save_data: SaveData = GameData.load_data()
	pass


func _on_DragModeOptionButton_item_selected(index: int) -> void:
	var drag_mode: int = 0
	
	if index == CLICK_MODE_INDEX:
		emit_signal("drag_mode_changed", Enums.DragMode.CLICK)
	else:
		emit_signal("drag_mode_changed", Enums.DragMode.HOLD)
