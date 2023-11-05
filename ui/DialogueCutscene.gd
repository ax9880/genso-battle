extends Control


export(String, FILE, "*.tscn") var next_scene: String

export(PackedScene) var dialogue_message_container_packed_scene
export(String, MULTILINE) var dialogue_json: String

onready var messages_container: VBoxContainer = $MarginContainer/VBoxContainer/ScrollContainer/MessagesVBoxContainer
onready var scroll_container: ScrollContainer = $MarginContainer/VBoxContainer/ScrollContainer

# Array of objects with these members:
# speaker: String
# line: String
var lines: Array = []

var current_line: int = 0
var current_dialogue_message_container: Control
var estimated_container_size: float


func _ready():
	_free_container_children()
	
	var json: JSONParseResult = JSON.parse(dialogue_json)
	
	assert(typeof(json.result) == TYPE_ARRAY)
	
	if typeof(json.result) == TYPE_ARRAY:
		lines = json.result
	
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
			1.2,
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
	var _error = Loader.change_scene(next_scene)


func _on_Timer_timeout() -> void:
	current_dialogue_message_container.start_showing_text()


func _on_SkipButton_pressed() -> void:
	_skip_dialogue()
