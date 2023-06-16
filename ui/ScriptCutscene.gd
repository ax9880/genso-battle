extends Control

export(String, FILE, "*.tscn") var next_scene: String

export(Array, Array, String) var pages := []

export(PackedScene) var text_label_packed_scene: PackedScene

export(float) var new_character_every_x_seconds: float = 0.0

onready var text_container: VBoxContainer = $MarginContainer/VBoxContainer/TextVBoxContainer

var current_page: int = 0
var current_paragraph: int = 0
var current_label: Label

var accumulated_time_seconds: float = 0


func _ready():
	_free_container_children()
	
	_show_next_paragraph()


func _process(delta: float) -> void:
	_slowly_make_text_visible(delta, current_label)


func _show_next_paragraph() -> void:
	var paragraph: String = pages[current_page][current_paragraph]
	
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


func _free_container_children() -> void:
	for child in text_container.get_children():
		child.queue_free()


func _skip_dialogue() -> void:
	var _error = get_tree().change_scene(next_scene)


func _on_SkipButton_pressed() -> void:
	_skip_dialogue()
