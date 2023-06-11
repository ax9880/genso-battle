extends Control


#export(Array, Resource) var lines: Array
#export(Array, PackedScene) var scenes

#var scenes: Dictionary
export(PackedScene) var dialogue_message_container_packed_scene

onready var messages_container: VBoxContainer = $MarginContainer/VBoxContainer/ScrollContainer/MessagesVBoxContainer
onready var scroll_container: ScrollContainer = $MarginContainer/VBoxContainer/ScrollContainer

# TODO: Load from a JSON?
var lines: Array = [
	{"speaker": "YACHIE", "line": "Hello, I am Yachie"},
	{"speaker": "SAKI", "line": "Hello, Yachie, I am Saki. How are you in this fine day?"},
	{"speaker": "YACHIE", "line": "Eh, been better. Have you seen Yuuma around?\n\nShe owes me 10 bucks"},
	{"speaker": "YUUMA", "line": "What's up gamers?"},
	{"speaker": "SAKI", "line": "There she is."},
	{"speaker": "YACHIE", "line": "Yuuma, I want my money back."},
	{"speaker": "YUUMA", "line": "Money is fleeting, Yachie. How about we go watch a movie instead."},
]

var current_line: int = 0
var current_dialogue_message_container: Control


# Called when the node enters the scene tree for the first time.
func _ready():
	_free_container_children()
	
	_show_next_line()


func _show_next_line() -> void:
	var dialogue_message = lines[current_line]
	
	current_dialogue_message_container = dialogue_message_container_packed_scene.instance()
	
	messages_container.add_child(current_dialogue_message_container)
	
	current_dialogue_message_container.initialize(dialogue_message)
	
	# https://ask.godotengine.org/65100/scrollcontainer-autoscroll
	yield(get_tree(), "idle_frame")
	
	if scroll_container.scroll_vertical != scroll_container.get_v_scrollbar().max_value:
		$Tween.interpolate_property(scroll_container, "scroll_vertical",
			scroll_container.scroll_vertical, scroll_container.get_v_scrollbar().max_value,
			1.0,
			Tween.TRANS_SINE)
		
		$Tween.start()
		
		yield($Tween, "tween_all_completed")
	
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
	get_tree().change_scene("res://ui/PreBattleMenu.tscn")
