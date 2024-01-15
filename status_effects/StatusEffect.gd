extends Modifier

# The effect is different from the skill
# This class is just what should happen every turn, e.g. lose health to poison
# or regenerate health
# Alternatively this logic could go in the unit or $Job scene
class_name StatusEffect


# Status effect type: poison, sleep, paralyze, confuse, demoralize
export(Enums.StatusEffectType) var status_effect_type: int = Enums.StatusEffectType.NONE

export(PackedScene) var effect_scene: PackedScene = null

# How much damage this status effect inflicts or heals per turn. It depends on
# the stats of the unit that inflicted this status effect, at the moment they did so
var base_damage: int = 0


func initialize(inflicting_unit_stats: StartingStats) -> void:
	calculate_base_damage(inflicting_unit_stats)


func calculate_damage(_affected_unit_stats: StartingStats) -> int:
	return 0


func calculate_base_damage(_inflicting_unit_stats: StartingStats) -> void:
	pass

