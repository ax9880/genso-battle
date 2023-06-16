extends Node2D


func _ready():
	for phase in get_children():
		phase.hide()


func _on_Board_enemy_phase_started(current_enemy_phase, enemy_phase_count):
	for phase in get_children():
		phase.hide()
	
	get_child(current_enemy_phase - 1).show()
