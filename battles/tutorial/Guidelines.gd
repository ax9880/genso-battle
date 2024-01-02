extends Node2D

export(NodePath) var units_node_path: NodePath

onready var units: Node2D = get_node(units_node_path)

var current_phase := 0


func _ready():
	$Phase4/CanvasLayer.hide()
	
	for phase in get_children():
		phase.hide()


func _on_Board_enemy_phase_started(current_enemy_phase, enemy_phase_count):
	for phase in get_children():
		phase.hide()
		
		$Phase4/CanvasLayer.hide()
	
	current_phase = current_enemy_phase
	
	get_child(current_enemy_phase - 1).show()


func _on_Board_player_turn_started() -> void:
	if current_phase == 4:
		$Phase4/CanvasLayer.show()
		
		for i in range(1, units.get_child_count()):
			units.get_child(i).disable_selection_area()


func _on_GiveUpButton_pressed() -> void:
	$Phase4/CanvasLayer.hide()
