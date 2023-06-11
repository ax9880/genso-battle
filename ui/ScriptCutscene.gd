extends Control


export(Array, Array, String) var pages := []

export(PackedScene) var text_label_packed_scene: PackedScene

onready var text_container: VBoxContainer = $MarginContainer/VBoxContainer/TextVBoxContainer

var current_page: int = 0
var current_paragraph: int = 0
var current_label: Label

var is_text_fully_visible := false

var ratio: float = 2.0


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
	
	is_text_fully_visible = false
	
	set_process(true)


# Increases percent visible of the given label. When it is >= 1 it is set to 1.0
func _slowly_make_text_visible(delta: float, label: Label) -> void:
	if is_text_fully_visible:
		return
	
	label.percent_visible += delta * ratio
	
	if label.percent_visible >= 1:
		_set_text_fully_visible()
		
		set_process(false)


func _input(event: InputEvent) -> void:
	if event.is_action_released("ui_select"):
		_on_press_ui_select()
	elif event.is_action_released("ui_cancel"):
		_skip_dialogue()
	elif event is InputEventScreenTouch:
		if event.pressed:
			_on_press_ui_select()


func _on_press_ui_select() -> void:
	if is_text_fully_visible:
		_advance_to_next_paragraph()
	else:
		_set_text_fully_visible()


func _set_text_fully_visible() -> void:
	current_label.percent_visible = 1
	is_text_fully_visible = true


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
	get_tree().change_scene("res://ui/DialogueCutscene.tscn")


func _on_SkipButton_pressed() -> void:
	_skip_dialogue()
