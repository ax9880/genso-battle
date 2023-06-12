extends HBoxContainer


export(float) var new_character_every_x_seconds: float = 0

onready var name_label := $VBoxContainer/NameLabel
onready var message_label := $MarginContainer/MarginContainer/MessageLabel
onready var character_icon := $VBoxContainer/TextureRect
onready var nine_patch := $MarginContainer/NinePatchRect

var accumulated_time_seconds: float = 0

signal text_fully_visible


func _ready() -> void:
	set_process(false)


func _process(delta: float) -> void:
	_slowly_make_text_visible(delta, message_label)


# texture
# name
# nine patch texture ?
# Make a generic one and make character specific ones
# Dialogue: who says it, expression ?, and what they are saying
func initialize(dialogue_message) -> void:
	name_label.text = tr(dialogue_message.speaker)
	message_label.text = tr(dialogue_message.line)
	
	# TODO: Set icon and nine patch rect texture depending on speaker
	
	message_label.percent_visible = 0
	accumulated_time_seconds = 0


func start_showing_text() -> void:
	set_process(true)


func _slowly_make_text_visible(delta: float, label: Label) -> void:
	accumulated_time_seconds += delta
	
	if accumulated_time_seconds > new_character_every_x_seconds:
		label.visible_characters += 1
		accumulated_time_seconds = 0
	
	if label.percent_visible >= 1:
		set_text_fully_visible()


func is_text_fully_visible() -> bool:
	return is_equal_approx(message_label.percent_visible, 1.0)


func set_text_fully_visible() -> void:
	message_label.percent_visible = 1
	
	emit_signal("text_fully_visible")
	
	set_process(false)
