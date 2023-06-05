extends Node2D

class_name Attacker

export(PackedScene) var attack_effect_packed_scene: PackedScene = null

onready var timer: Timer = $Timer

var attack_queue: Array = []

signal attacks_done

var random := RandomNumberGenerator.new()


func _ready() -> void:
	random.randomize()


func start_attacks(queue: Array) -> void:
	attack_queue = queue
	
	_execute_next_attack()
	
	timer.start()


func _execute_next_attack() -> void:
	var attack = attack_queue.pop_front()
	
	if attack != null:
		_exec_attack(attack)
	else:
		timer.stop()
		
		emit_signal("attacks_done")


func _exec_attack(attack: Attack) -> void:
	for targeted_unit in attack.targeted_units:
		#var damage: int = targeted_unit.calculate_damage(attack.attacking_unit.get_stats(), attack.pincering_unit.get_stats())
		
		var damage: int = targeted_unit.calculate_damage(attack.attacking_unit.get_stats()) * random.randf_range(0.9, 1.1)
		
		var attack_effect: Node2D = attack_effect_packed_scene.instance()
		add_child(attack_effect)
		
		attack_effect.position = targeted_unit.position
		attack_effect.set_value(damage)
		
		$AudioStreamPlayer.play()
		
		targeted_unit.inflict_damage(damage)
		
		# TODO: shake targeted unit
		# TODO: check when unit dies
		# TODO: play death animation


func _on_Timer_timeout() -> void:
	_execute_next_attack()
