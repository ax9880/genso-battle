extends Control

# Chapter data with scene title
# Set by Loader in on_instance(), but exported to be able to test this scene
# locally
export(Resource) var chapter_data: Resource 

export(PackedScene) var text_label_packed_scene: PackedScene

# Next scene
export(String, FILE, "*.tscn") var dialogue_scene_path: String

export(float) var new_character_every_x_seconds: float = 0.0

export(String) var title_suffix: String = ""

onready var text_container: VBoxContainer = $MarginContainer/VBoxContainer/TextVBoxContainer

var _current_page: int = 0
var _current_paragraph: int = 0
var _current_label: Label

var _accumulated_time_seconds: float = 0

# Array<Array>
var _pages: Array

var _is_local: bool = true

var _is_dialogue_skipped: bool = false


func _ready() -> void:
	set_process(false)
	
	_free_container_children()
	
	_read_pages()
	
	if _is_local and not _pages.empty():
		_start_showing_text()


func _process(delta: float) -> void:
	_slowly_make_text_visible(delta, _current_label)


func on_instance(data: Object) -> void:
	assert(data is ChapterData)
	
	chapter_data = data
	
	_is_local = false


func on_fade_out_finished() -> void:
	if not _pages.empty():
		_start_showing_text()


# Reads _pages and splits them into lines
func _read_pages() -> void:
	var file: File = File.new()
	
	var scene_title = chapter_data.title + title_suffix
	
	if file.open("res://text/script_" + scene_title.to_lower() + ".json", File.READ) != OK:
		printerr("Failed to read file for scene %s, skipping script" % scene_title)
		
		_skip_dialogue()
	else:
		var parse_result: JSONParseResult = JSON.parse(file.get_as_text())
		
		file.close()
		
		if parse_result.error == OK:
			var json = parse_result.result
			
			_pages = []
			
			for page_key in json:
				_add_page(page_key["line"])
		else:
			printerr("Failed to load JSON")


func _add_page(key: String) -> void:
	var page: String = tr(key)
	
	var lines: Array = page.split("\n", true) # Allow empty
	
	_pages.push_back(lines)


func _start_showing_text() -> void:
	_set_parameters_from_chapter_data()
	
	_show_next_paragraph()


func _show_next_paragraph() -> void:
	var paragraph: String = _pages[_current_page][_current_paragraph]
	
	if paragraph.empty():
		# If empty, adds an empty label so that it serves as a line break
		_current_label = text_label_packed_scene.instance()
		_current_label.text = ""
		_current_label.percent_visible = 1
		
		text_container.add_child(_current_label)
		
		# Note: Potentially recursive call
		_advance_to_next_paragraph()
	else:
		_current_label = text_label_packed_scene.instance()
		_current_label.text = tr(paragraph)
		_current_label.percent_visible = 0
		
		text_container.add_child(_current_label)
		
		set_process(true)


# Increases percent visible of the given label. When it is >= 1 it is set to 1.0
func _slowly_make_text_visible(delta: float, label: Label) -> void:
	_accumulated_time_seconds += delta
	
	if _accumulated_time_seconds > new_character_every_x_seconds:
		label.visible_characters += 1
		_accumulated_time_seconds = 0
	
	if label.percent_visible >= 1:
		_set_text_fully_visible()


func _input(event: InputEvent) -> void:
	call_deferred("_evaluate_input", event)


func _evaluate_input(event: InputEvent) -> void:
	if not _is_dialogue_skipped:
		if event.is_action_released("ui_select"):
			_on_press_ui_select()
		elif event.is_action_released("ui_cancel"):
			_skip_dialogue()
		elif event is InputEventScreenTouch and event.pressed:
			_on_press_ui_select()


func _on_press_ui_select() -> void:
	if _current_label.percent_visible >= 1:
		_advance_to_next_paragraph()
	else:
		_set_text_fully_visible()


func _set_text_fully_visible() -> void:
	_current_label.percent_visible = 1
	
	set_process(false)


func _advance_to_next_paragraph() -> void:
	_current_paragraph += 1
	
	if _current_paragraph >= _pages[_current_page].size():
		_advance_to_next_page()
	else:
		_show_next_paragraph()


func _advance_to_next_page() -> void:
	_current_page += 1
	_current_paragraph = 0
	
	if _current_page >= _pages.size():
		_skip_dialogue()
	else:
		_free_container_children()
		
		_show_next_paragraph()


# Frees any default or test text containers that you may have added
func _free_container_children() -> void:
	for child in text_container.get_children():
		child.queue_free()


func _skip_dialogue() -> void:
	if not _is_dialogue_skipped:
		_is_dialogue_skipped = true
		
		if Loader.change_scene(dialogue_scene_path, chapter_data) != OK:
			printerr("Failed to change scene")
		
		set_process(false)


func _set_parameters_from_chapter_data() -> void:
	if chapter_data.dialogue_background != null:
		$Background.texture = chapter_data.dialogue_background
	
	if chapter_data.dialogue_audio_stream != null:
		$AudioStreamPlayer.stream = chapter_data.dialogue_audio_stream
		
		$AudioStreamPlayer.play()


func _on_SkipButton_pressed() -> void:
	_skip_dialogue()
