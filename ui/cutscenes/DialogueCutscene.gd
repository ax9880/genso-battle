extends Control


export(Resource) var chapter_data: Resource 

export(PackedScene) var dialogue_message_container_packed_scene

export(float) var scroll_tween_time_seconds: float = 0.75

# Array of objects with these members:
# speaker: String
# line: String
var lines: Array = []

var current_line: int = 0
var current_dialogue_message_container: Control
var estimated_container_size: float

var is_dialogue_skipped: bool = false

onready var messages_container: VBoxContainer = $MarginContainer/VBoxContainer/ScrollContainer/MessagesVBoxContainer
onready var scroll_container: ScrollContainer = $MarginContainer/VBoxContainer/ScrollContainer


func _ready():
	_free_container_children()
	
	_load_lines_keys()
	
	if not lines.empty():
		_set_parameters_from_chapter_data()
		
		_show_next_line()


func on_instance(data: Object) -> void:
	assert(data is ChapterData)
	
	chapter_data = data


func get_dialogue_json_filename() -> String:
	return "res://text/dialogue_%s.json" % chapter_data.title.to_lower()


func _load_lines_keys() -> void:
	var dialogue_json: String = get_dialogue_json_filename()
	
	var file: File = File.new()
	
	if file.open(dialogue_json, File.READ) != OK:
		printerr("Failed to read file for scene %s, skipping dialogue" % dialogue_json)
		
		_skip_dialogue()
	else:
		var parse_result: JSONParseResult = JSON.parse(file.get_as_text())
		
		file.close()
		
		if parse_result.error == OK:
			lines = parse_result.result
		else:
			printerr("Failed to load JSON")


func _show_next_line() -> void:
	_dim_text_of_last_line()
	
	var dialogue_message = lines[current_line]
	
	current_dialogue_message_container = dialogue_message_container_packed_scene.instance()
	
	messages_container.add_child(current_dialogue_message_container)
	
	current_dialogue_message_container.initialize(dialogue_message)
	current_dialogue_message_container.modulate = Color.transparent
	
	call_deferred("update_scroll")


func _dim_text_of_last_line() -> void:
	var last_dialogue_message_container: Control = messages_container.get_child(messages_container.get_child_count() - 1)
	
	if last_dialogue_message_container != null:
		last_dialogue_message_container.dim_text()


func update_scroll() -> void:
	estimated_container_size += current_dialogue_message_container.rect_size.y
	
	$Tween.interpolate_property(scroll_container, "scroll_vertical",
		scroll_container.scroll_vertical, scroll_container.get_v_scrollbar().max_value,
		scroll_tween_time_seconds,
		Tween.TRANS_SINE)
	
	$Tween.start()
	
	$Tween.interpolate_property(current_dialogue_message_container, "modulate",
		Color.transparent,
		Color.white,
		$Timer.wait_time,
		Tween.TRANS_SINE)
	
	$Tween.start()
	
	$Timer.start()


func _input(event: InputEvent) -> void:
	call_deferred("_evaluate_input", event)


func _evaluate_input(event: InputEvent) -> void:
	if not is_dialogue_skipped:
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
	if not is_dialogue_skipped:
		is_dialogue_skipped = true
		
		if Loader.change_scene(chapter_data.battle_scene_path, chapter_data) != OK:
			printerr("Failed to change scene")
		
		set_process(false)


func _set_parameters_from_chapter_data() -> void:
	if chapter_data.dialogue_background != null:
		$Background.texture = chapter_data.dialogue_background
	
	if chapter_data.dialogue_audio_stream != null:
		$AudioStreamPlayer.stream = chapter_data.dialogue_audio_stream
		
		$AudioStreamPlayer.play()


func _on_Timer_timeout() -> void:
	current_dialogue_message_container.start_showing_text()


func _on_SkipButton_pressed() -> void:
	_skip_dialogue()
