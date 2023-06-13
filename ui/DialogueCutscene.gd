extends Control


export(PackedScene) var dialogue_message_container_packed_scene

onready var messages_container: VBoxContainer = $MarginContainer/VBoxContainer/ScrollContainer/MessagesVBoxContainer
onready var scroll_container: ScrollContainer = $MarginContainer/VBoxContainer/ScrollContainer

# TODO: Load from a JSON?
var lines: Array = [
	{"speaker": "YACHIE", "line": "Hello, I am Yachie."},
	{"speaker": "SAKI", "line": "Howdy, Yachie, I am Saki. How have you been?"},
	{"speaker": "YACHIE", "line": "Eh, been better. Have you seen Yuuma around?\n\nShe owes me 10000 yen."},
	{"speaker": "YUUMA", "line": "What's up gamers?"},
	{"speaker": "SAKI", "line": "There she is."},
	{"speaker": "YACHIE", "line": "Yuuma, I want my money back."},
	{"speaker": "YUUMA", "line": "Sorry Yachie, I ate it."},
]

var current_line: int = 0
var current_dialogue_message_container: Control
var estimated_container_size: float


# Called when the node enters the scene tree for the first time.
func _ready():
	_free_container_children()
	
	_show_next_line()


func _show_next_line() -> void:
	var dialogue_message = lines[current_line]
	
	current_dialogue_message_container = dialogue_message_container_packed_scene.instance()
	
	messages_container.add_child(current_dialogue_message_container)
	
	current_dialogue_message_container.initialize(dialogue_message)
	
	call_deferred("update_scroll")


func update_scroll() -> void:
	estimated_container_size += current_dialogue_message_container.rect_size.y
	
	if estimated_container_size > scroll_container.rect_size.y:
		$Tween.interpolate_property(scroll_container, "scroll_vertical",
			scroll_container.scroll_vertical, scroll_container.get_v_scrollbar().max_value,
			1.0,
			Tween.TRANS_SINE)
		
		$Tween.start()
		
		$Timer.start()
	else:
		current_dialogue_message_container.start_showing_text()


func _input(event: InputEvent) -> void:
	if event.is_action_released("ui_select"):
		_on_press_ui_select()
	elif event.is_action_released("ui_cancel"):
		_skip_dialogue()
	elif event is InputEventScreenTouch:
		if event.pressed:
			_on_press_ui_select()


func _on_press_ui_select() -> void:
	if current_dialogue_message_container.is_text_fully_visible():
		_advance_to_next_line()
	else:
		current_dialogue_message_container.set_text_fully_visible()


func _advance_to_next_line() -> void:
	current_line += 1
	
	if current_line >= lines.size():
		_skip_dialogue()
	else:
		_show_next_line()


func _free_container_children() -> void:
	for child in messages_container.get_children():
		child.queue_free()


func _skip_dialogue() -> void:
	var _error = get_tree().change_scene("res://ui/PreBattleMenu.tscn")


func _on_Timer_timeout() -> void:
	current_dialogue_message_container.start_showing_text()


func _on_SkipButton_pressed() -> void:
	_skip_dialogue()
