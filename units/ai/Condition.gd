extends Node


# At what HP percentage this condition is true
export(float, 0.1, 1, 0.1) var hp_percentage: float = 1.0

# Whether this condition should only activate once
export(bool) var is_one_shot: bool = false

# At which specific enemy turn this condition is true
export(int) var turn_offset: int = 0

# This condition repeats every X turns
# turn + turn_x * counter
export(int, 0, 20, 1) var turn_steps: int = 1

# Set after a one-shot condition is activated and the corresponding action
# is performed
var is_activated: bool = false

var counter: int = 1


func is_true(current_hp_percentage: float, current_turn: int) -> bool:
	if current_hp_percentage > hp_percentage:
		return false
	
	if is_one_shot and is_activated:
		return false
	
	if (turn_offset + counter * turn_steps) != current_turn:
		return false
	
	counter += 1
	
	return true
