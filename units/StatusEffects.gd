extends Node2D

# Dictionary<StatusEffectType, PackedScene>
# This class uses a dictionary so that there is only one effect per type, in
# case unit has multiple status effects of the same type.
var _status_effects := {}

# Dictionary<StatusEffectType, int>
# Where int is the number of status effects with the same type.
var _status_effects_counter := {}


func add(status_effect_type: int, effect_scene: PackedScene) -> void:
	if effect_scene != null and not _status_effects.has(status_effect_type):
		var effect: Node2D = effect_scene.instance()
		
		add_child(effect)
		
		_status_effects[status_effect_type] = effect
		_status_effects_counter[status_effect_type] = 1
	else:
		_status_effects_counter[status_effect_type] += 1


func remove(status_effect_type: int) -> void:
	if _status_effects_counter.has(status_effect_type):
		_status_effects_counter[status_effect_type] -= 1
		
		if _status_effects_counter[status_effect_type] == 0:
			var effect: Node2D = _status_effects.get(status_effect_type)
			
			if effect != null:
				effect.stop()
			
			if not _status_effects.erase(status_effect_type):
				print("Tried to erase unexisting status effect")
