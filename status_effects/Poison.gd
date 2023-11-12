extends StatusEffect

class_name Poison


var random := RandomNumberGenerator.new()


func calculate_base_damage(inflicting_unit_stats: StartingStats) -> void:
	base_damage = inflicting_unit_stats.spiritual_attack * 1.5


func can_stack(other: StatusEffect) -> bool:
	return false


func can_replace(other: StatusEffect) -> bool:
	return base_damage > other.base_damage


func calculate_damage(_affected_unit_stats: StartingStats) -> int:
	return int(float(base_damage) * random.randf_range(0.9, 1.1))


func get_type() -> int:
	return Enums.StatusEffectType.POISON
