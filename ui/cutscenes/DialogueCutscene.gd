extends Control


export(String, FILE, "*.tscn") var next_scene: String

export(PackedScene) var dialogue_message_container_packed_scene
export(String) var scene_title: String

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
	
	_load_lines_keys()
	
	_show_next_line()


func _load_lines_keys() -> void:
	var dialogue_json: String = "res://text/dialogue_%s.json" % scene_title.to_lower()
	
	var file: File = File.new()
	
	if file.open(dialogue_json, File.READ) != OK:
		printerr("Failed to read file")
		
		# FIXME: Can't skip dialogue in _ready() because loading screen
		# may not be ready yet
		#_skip_dialogue()
	else:
		var parse_result: JSONParseResult = JSON.parse(file.get_as_text())
		
		file.close()
		
		if parse_result.error == OK:
			lines = parse_result.result
		else:
			printerr("Failed to load JSON")


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
