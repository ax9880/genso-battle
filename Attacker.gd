extends Node2D

class_name Attacker

export(PackedScene) var attack_effect_packed_scene: PackedScene = null

onready var timer: Timer = $Timer

# Array<Attack>
var attack_queue: Array = []
var random := RandomNumberGenerator.new()

signal attack_phase_finished


func _ready() -> void:
	random.randomize()


func start(attacks: Array) -> void:
	attack_queue = attacks
	
	_execute_next_attack()
	
	timer.start()


func _execute_next_attack() -> void:
	var attack = attack_queue.pop_front()
	
	if attack != null:
		_execute_attack(attack)
	else:
		timer.stop()
		
		emit_signal("attack_phase_finished")


func _execute_attack(attack: Attack) -> void:
	for targeted_unit in attack.targeted_units:
		var damage: int = targeted_unit.calculate_damage(attack.attacking_unit.get_stats()) * random.randf_range(0.9, 1.1)
		
		var attack_effect: Node2D = attack_effect_packed_scene.instance()
		add_child(attack_effect)
		
		attack_effect.position = targeted_unit.position
		attack_effect.set_value(damage)
		
		$AudioStreamPlayer.play()
		
		targeted_unit.inflict_damage(damage)
		
		# TODO: shake targeted unit


func _on_Timer_timeout() -> void:
	_execute_next_attack()
