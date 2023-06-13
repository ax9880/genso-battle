extends Node2D

class_name Trap


enum DamageType {
	FIXED,
	PERCENTAGE
}

export(DamageType) var damage_type: int = DamageType.FIXED
export(int) var fixed_damage: int = 0
export(float, 0, 1, 0.1) var percentage_damage: float = 0.1

export(PackedScene) var damage_effect_packed_scene: PackedScene


func activate(unit: Unit) -> void:
	unit.inflict_damage(calculate_damage(unit.get_max_health()))
	
	var damage_effect: Node2D = damage_effect_packed_scene.instance()
	
	# Damage effects frees automatically
	unit.add_child(damage_effect)
	
	$ActivationAudio.play()


func calculate_damage(max_health: int) -> int:
	match(damage_type):
		DamageType.FIXED:
			return fixed_damage
		_:
			return int(max_health * percentage_damage)
