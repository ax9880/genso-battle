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
	
	_filter_attacks(attacks)
	
	_execute_next_attack()
	
	timer.start()


func _filter_attacks(attacks: Array) -> void:
	for attack in attacks:
		var filtered_targeted_units: Array = []
		
		for targeted_unit in attack.targeted_units:
			if not targeted_unit.is_dead():
				filtered_targeted_units.push_back(targeted_unit)
		
		attack.targeted_units = filtered_targeted_units


func _execute_next_attack() -> void:
	var attack = attack_queue.pop_front()
	
	if attack != null:
		_execute_attack(attack)
	else:
		timer.stop()
		
		emit_signal("attack_phase_finished")


func _execute_attack(attack: Attack) -> void:
	match(attack.pincering_unit.get_stats().weapon_type):
		Enums.WeaponType.SWORD:
			$SwordAudio.play()
		Enums.WeaponType.GUN:
			$GunAudio.play()
		Enums.WeaponType.SPEAR:
			$SpearAudio.play()
		Enums.WeaponType.STAFF:
			$StaffAudio.play()
	
	for targeted_unit in attack.targeted_units:
		var damage: int = targeted_unit.calculate_attack_damage(attack.attacking_unit.get_stats(), attack.pincering_unit.get_stats()) * random.randf_range(0.9, 1.1)
		
		var attack_effect: Node2D = attack_effect_packed_scene.instance()
		add_child(attack_effect)
		
		attack_effect.position = targeted_unit.position
		
		targeted_unit.inflict_damage(damage)


func _on_Timer_timeout() -> void:
	_execute_next_attack()
