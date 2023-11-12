extends StatusEffect

class_name Poison


var random := RandomNumberGenerator.new()


func calculate_base_damage(inflicting_unit_stats: StartingStats) -> void:
	random.randomize()
	
	base_damage = int(inflicting_unit_stats.spiritual_attack * 1.5)


func calculate_damage(_affected_unit_stats: StartingStats) -> int:
	return int(float(base_damage) * random.randf_range(0.9, 1.1))
