extends Node2D

# Dictionary<StatusEffectType, PackedScene>
var status_effects := {}

# Dictionary<StatusEffectType, int>
# TODO: Use class to group PackedScene and int
var status_effects_counter := {}


func add(status_effect_type: int, effect_scene: PackedScene) -> void:
	if not status_effects.has(status_effect_type):
		var effect: Node2D = effect_scene.instance()
		
		add_child(effect)
		
		status_effects[status_effect_type] = effect
		status_effects_counter[status_effect_type] = 1
	else:
		status_effects_counter[status_effect_type] += 1


func remove(status_effect_type: int) -> void:
	status_effects_counter[status_effect_type] -= 1
	
	if status_effects_counter[status_effect_type] == 0:
		var effect: Node2D = status_effects.get(status_effect_type)
	
		if effect != null:
			effect.stop()
		
		if not status_effects.erase(status_effect_type):
			print("Tried to erase unexisting status effect")
