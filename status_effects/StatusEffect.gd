extends Resource

# The effect is different from the skill
# This class is just what should happen every turn, e.g. lose health to poison
# or regenerate health
# Alternatively this logic could go in the unit or $Job scene
class_name StatusEffect

# Status effect type: poison, sleep, paralyze, confuse, demoralize,
# buffs, or debuffs
export(Enums.StatusEffectType) var status_effect_type: int = Enums.StatusEffectType.NONE

# Max duration in turns
export(int, 0, 5, 1) var duration_turns: int = 3

# Custom icon. If it is null then skill labels use default icons
export(Texture) var icon = null

# Effect scene must have a stop() method that stops the effect
# and automatically frees the node.
# If it is null then no effect scene is instanced.
export(PackedScene) var effect_scene: PackedScene = null

# How much damage this status effect inflicts or heals per turn. It depends on
# the stats of the unit that inflicted this status effect, at the moment they did so
var base_damage: int = 0

var turn_count: int = -1


func initialize(inflicting_unit_stats: StartingStats) -> void:
	calculate_base_damage(inflicting_unit_stats)


func calculate_base_damage(_inflicting_unit_stats: StartingStats) -> void:
	pass


# Implement this method to modify stats. For general stat buffs/debuffs
# see StatsModifier.
func modify_stats(_base_stats: StartingStats, _modified_stats: StartingStats) -> void:
	pass


# Implement this method if the modifier causes or heals damage over time.
func calculate_damage(_affected_unit_stats: StartingStats) -> int:
	return 0


func update() -> void:
	if turn_count == -1:
		turn_count = duration_turns
	
	turn_count -= 1


func is_done() -> bool:
	return turn_count <= 0


func is_buff() -> bool:
	return status_effect_type == Enums.StatusEffectType.BUFF or status_effect_type == Enums.StatusEffectType.REGENERATE


func get_description() -> String:
	var turns_left_description: String = tr("TURNS_LEFT") % turn_count
	
	return "%s, %s" % [tr(Enums.status_effect_type_to_string(status_effect_type)), turns_left_description]
