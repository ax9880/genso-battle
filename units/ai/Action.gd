class_name Action
extends Node


enum Behavior {
	MOVE,
	USE_SKILL,
	PINCER,
	WAIT
}

export(Behavior) var behavior: int

export(Resource) var skill: Resource

export(Enums.Preference) var preference: int = Enums.Preference.DEAL_DAMAGE

# Specific cell to move to, if possible
# x: [0, 5]
# y: [0, 7]
export(float, -1, 5, 1) var cell_x_to_move_to: float = -1
export(float, -1, 7, 1) var cell_y_to_move_to: float = -1

# If unit can move when using a skill, or if it should use it from its current
# position. Can only be used when skill and cell to move to are not null
export(bool) var can_move_when_using_skill: bool = true

# Weight of this action, affects how often this action is chosen if there
# are multiple available actions
export(int, 1, 10, 1) var weight: int = 1

# Translation key
export(String) var text: String

export(bool) var can_ignore_weights: bool = false


func can_activate(current_hp_percentage: float, current_turn: int, can_use_turn_counter: bool = true) -> bool:
	var is_all_conditions_true: bool = true
	
	# If there are no children this is always activated
	for condition in get_children():
		is_all_conditions_true = is_all_conditions_true && condition.is_true(current_hp_percentage, current_turn, can_use_turn_counter)
	
	return is_all_conditions_true


func on_use() -> void:
	for condition in get_children():
		if condition.is_one_shot:
			condition.is_activated = true


func reset_turn_counter() -> void:
	for condition in get_children():
		condition.reset_turn_counter()


func has_valid_cell() -> bool:
	return cell_x_to_move_to >= 0 and cell_y_to_move_to >= 0


func get_cell_position() -> Vector2:
	assert(has_valid_cell())
	
	return Vector2(cell_x_to_move_to, cell_y_to_move_to)
