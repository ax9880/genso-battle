extends Resource

class_name Modifier


# Max duration in turns
export(int, 0, 5, 1) var duration_turns: int = 0

# Custom icon. If it's null then skill labels use default icons according
# to weapon type or skill type
export(Texture) var icon = null


var turn_count: int = duration_turns


func initialize(_inflicting_unit_stats: StartingStats) -> void:
	pass


# Implement this method to modify stats. This is used for special cases
# so that units can be immune to certain status effects that modify stats. For
# general stat buffs/debuffs see StatsModifier.
func modify_stats(_base_stats: StartingStats, _modified_stats: StartingStats) -> void:
	pass


func update() -> void:
	turn_count -= 1


func is_done() -> bool:
	return turn_count <= 0
