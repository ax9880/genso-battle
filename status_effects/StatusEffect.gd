extends Resource

# The effect is different from the skill
# This class is just what should happen every turn, e.g. lose health to poison
# or regenerate health
# Alternatively this logic could go in the unit or $Job scene
class_name StatusEffect


# Status effect type: poison, sleep, paralyze, confuse, demoralize
export(Enums.StatusEffectType) var status_effect_type: int = Enums.StatusEffectType.NONE

# Max duration in turns
export(int, 0, 5, 1) var duration_turns: int = 0

export(PackedScene) var effect_scene: PackedScene = null


# How much damage this status effect inflicts or heals per turn. It depends on
# the stats of the unit that inflicted this status effect, at the moment they did so
var base_damage: int = 0

var _turn_count: int = 0

var status_effect_scene_path: String = ""


func initialize(inflicting_unit_stats: StartingStats, max_turn_count: int, _status_effect_scene_path: String) -> void:
	_turn_count = max_turn_count
	
	status_effect_scene_path = _status_effect_scene_path
	
	calculate_base_damage(inflicting_unit_stats)


func can_stack(_other: StatusEffect) -> bool:
	return false


func can_replace(_other: StatusEffect) -> bool:
	return false


# Add damage, reset turn counter, etc
func stack(_other: StatusEffect) -> void:
	pass


func calculate_damage(_affected_unit_stats: StartingStats) -> int:
	return 0


func update() -> void:
	_turn_count -= 1


func is_done() -> bool:
	return _turn_count <= 0


func get_type() -> int:
	return Enums.StatusEffectType.NONE


func calculate_base_damage(_inflicting_unit_stats: StartingStats) -> void:
	printerr("Implement me")


# If status effect causes damage
# Which is different from a buff or debuff...
# Pass unit to call inflict_damage() and get how much damage...? But
# then I get a circular reference Unit > Status Effect > Unit
# Return how much damage so unit can do that?
func inflict(stats: StartingStats) -> void:
	# inflict damage if poison
	# heal if regeneration
	# show effect. Reuse skill effect? But this resource shouldn't do that
	# This resource should only have the logic to heal or inflict damage
	# Regenerate -> RegenerationStatusEffectSkill
	# Poison -> PoisonStatusEffectSkill
	pass

# for status_effect in status_effects:
#  status_effect.inflict(self)
#  status_effect.inflict($Job) ?
#   unit.inflict_damage() -> shake, update HP bar, show numbers
# 
# In unit:
#  var damage: int = status_effect.calculate_damage(current_stats)
#  if damage != 0:
#   status_effect.show()
#   inflict_damage(damage)
