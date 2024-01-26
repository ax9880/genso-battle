extends HBoxContainer


const _ICONS: Dictionary = {
	"YACHIE": "res://assets/player/yachie.png",
	"SAKI": "res://assets/player/saki.png",
	"YUUMA": "res://assets/player/yuuma.png",
	"HAWK_SPIRIT": "res://assets/player/eagle_1.png"
}

export(float) var new_character_every_x_seconds: float = 0

export(Color) var dim_color: Color

onready var name_label := $VBoxContainer/NameLabel
onready var message_label := $MarginContainer/MarginContainer/MessageLabel
onready var character_icon := $VBoxContainer/TextureRect
onready var nine_patch := $MarginContainer/NinePatchRect

var _accumulated_time_seconds: float = 0

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
	var speaker: String = dialogue_message.speaker
	
	name_label.text = tr(speaker)
	message_label.text = tr(dialogue_message.line)
	
	if _ICONS.has(speaker):
		$VBoxContainer/TextureRect.texture = load(_ICONS[speaker])
	
	message_label.percent_visible = 0
	_accumulated_time_seconds = 0
	
	$DialogueAudio.play()


func start_showing_text() -> void:
	if message_label.percent_visible < 1.0:
		set_process(true)


func _slowly_make_text_visible(delta: float, label: Label) -> void:
	_accumulated_time_seconds += delta
	
	if _accumulated_time_seconds > new_character_every_x_seconds:
		label.visible_characters += 1
		_accumulated_time_seconds = 0
	
	if label.percent_visible >= 1.0:
		set_text_fully_visible()


func is_text_fully_visible() -> bool:
	return is_equal_approx(message_label.percent_visible, 1.0)


func set_text_fully_visible() -> void:
	message_label.percent_visible = 1
	
	emit_signal("text_fully_visible")
	
	set_process(false)


func dim_text() -> void:
	modulate = dim_color
