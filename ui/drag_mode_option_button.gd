extends OptionButton


const CLICK_MODE_INDEX: int = 0
const HOLD_MODE_INDEX: int = 1

signal drag_mode_changed(drag_mode)


func _ready() -> void:
	var save_data: SaveData = GameData.save_data
	
	if save_data.drag_mode == Enums.DragMode.CLICK:
		select(CLICK_MODE_INDEX)
	else:
		select(HOLD_MODE_INDEX)


func _on_DragModeOptionButton_item_selected(index: int) -> void:
	_play_sound()
	
	if index == CLICK_MODE_INDEX:
		emit_signal("drag_mode_changed", Enums.DragMode.CLICK)
	else:
		emit_signal("drag_mode_changed", Enums.DragMode.HOLD)


func _on_DragModeOptionButton_pressed() -> void:
	_play_sound()


func _play_sound() -> void:
	$AudioStreamPlayer.play()
