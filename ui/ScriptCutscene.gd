extends Control

export(String, FILE, "*.tscn") var next_scene: String

# Scene title as saved in the script sheet or CSV
export(String) var scene_title: String 

export(PackedScene) var text_label_packed_scene: PackedScene

export(float) var new_character_every_x_seconds: float = 0.0

onready var text_container: VBoxContainer = $MarginContainer/VBoxContainer/TextVBoxContainer

var current_page: int = 0
var current_paragraph: int = 0
var current_label: Label

var accumulated_time_seconds: float = 0

# Array<Array>
var pages: Array


func _ready():
	_read_pages()
	
	_free_container_children()
	
	_show_next_paragraph()


func _process(delta: float) -> void:
	_slowly_make_text_visible(delta, current_label)


# Reads pages and splits them into lines
func _read_pages() -> void:
	var file: File = File.new()
	
	if file.open("res://text/script_" + scene_title.to_lower() + ".json", File.READ) != OK:
		printerr("Failed to read file")
		
		_skip_dialogue()
	else:
		var parse_result: JSONParseResult = JSON.parse(file.get_as_text())
		
		file.close()
		
		if parse_result.error == OK:
			var json = parse_result.result
			
			pages = []
			
			for page_key in json:
				_add_page(page_key["line"])
		else:
			printerr("Failed to load JSON")


func _add_page(key: String) -> void:
	var page: String = tr(key)
	
	var lines: Array = page.split("\n", true) # Allow empty
	
	pages.push_back(lines)


func _show_next_paragraph() -> void:
	var paragraph: String = pages[current_page][current_paragraph]
	
	if paragraph.empty():
		# If empty, adds an empty label so that it serves as a line break
		current_label = text_label_packed_scene.instance()
		current_label.text = ""
		current_label.percent_visible = 1
		
		text_container.add_child(current_label)
		
		# Note: Potentially recursive call
		_advance_to_next_paragraph()
	else:
		current_label = text_label_packed_scene.instance()
		current_label.text = tr(paragraph)
		current_label.percent_visible = 0
		
		text_container.add_child(current_label)
		
		set_process(true)


# Increases percent visible of the given label. When it is >= 1 it is set to 1.0
func _slowly_make_text_visible(delta: float, label: Label) -> void:
	accumulated_time_seconds += delta
	
	if accumulated_time_seconds > new_character_every_x_seconds:
		label.visible_characters += 1
		accumulated_time_seconds = 0
	
	if label.percent_visible >= 1:
		_set_text_fully_visible()


func _input(event: InputEvent) -> void:
	if event.is_action_released("ui_select"):
		_on_press_ui_select()
	elif event.is_action_released("ui_cancel"):
		_skip_dialogue()
	elif event is InputEventScreenTouch:
		if event.pressed:
			_on_press_ui_select()


func _on_press_ui_select() -> void:
	if current_label.percent_visible >= 1:
		_advance_to_next_paragraph()
	else:
		_set_text_fully_visible()


func _set_text_fully_visible() -> void:
	current_label.percent_visible = 1
	
	set_process(false)


func _advance_to_next_paragraph() -> void:
	current_paragraph += 1
	
	if current_paragraph >= pages[current_page].size():
		_advance_to_next_page()
	else:
		_show_next_paragraph()


func _advance_to_next_page() -> void:
	current_page += 1
	current_paragraph = 0
	
	if current_page >= pages.size():
		_skip_dialogue()
	else:
		_free_container_children()
		
		_show_next_paragraph()


# Frees any default or test text containers that you may have added
func _free_container_children() -> void:
	for child in text_container.get_children():
		child.queue_free()


func _skip_dialogue() -> void:
	var _error = Loader.change_scene(next_scene)


func _on_SkipButton_pressed() -> void:
	_skip_dialogue()
