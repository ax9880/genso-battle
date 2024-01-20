extends Node

const WEAPON_ADVANTAGE: float = 3.0
const WEAPON_DISADVANTAGE: float = 1.0


export(NodePath) var target_unit_path: NodePath
export(NodePath) var status_effect_node2d_path: NodePath

onready var status_effect_node2d: Node2D = get_node(status_effect_node2d_path)
onready var target_unit: Unit = get_node(target_unit_path)

var random := RandomNumberGenerator.new()


func _ready() -> void:
	random.randomize()


# Applies a skill, inflicts/heals damage, adds/removes status effects and stats modifiers
func apply_skill(unit: Unit,
		skill: Skill,
		on_damage_absorbed_callback: FuncRef,
		status_effects: Array) -> void:
	if (skill.is_attack() or skill.is_healing()) and skill.primary_power > 0:
		var damage := calculate_damage(unit.get_stats(), target_unit.get_stats(), skill.primary_power, skill.primary_weapon_type, skill.primary_attribute)
		
		damage = int(damage * random.randf_range(0.9, 1.1))
		
		if skill.is_healing():
			damage = -damage * 3
		
		var absorbed_damage = int(skill.absorb_rate * damage)
		
		on_damage_absorbed_callback.call_func(absorbed_damage)
		
		target_unit.inflict_damage(damage)
	
	var has_modified_stats: bool = false
	
	# If it has status effect, try to apply it
	# Skill can cause damage AND inflict status effect, so it can't be if-else
	if skill.has_status_effects() and _can_inflict_status_effects(skill):
		for status_effect_resource in skill.status_effects:
			var status_effect: StatusEffect = status_effect_resource.duplicate()
			
			if status_effect.is_buff() or _can_apply_status_effect(target_unit.get_stats(), status_effect):
				has_modified_stats = true
				
				status_effect.initialize(unit.get_stats())
				
				# TODO: Update status effect icons
				status_effects.append(status_effect)
				
				print("Applied %s to %s" % [status_effect.status_effect_type, unit.name])
				
				status_effect_node2d.add(status_effect.status_effect_type, status_effect.effect_scene)
			else:
				print("%s resisted %s" % [name, status_effect.status_effect_type])
	
	if skill.can_cure_status_effects():
		var status_effects_to_remove := []
		
		for status_effect in status_effects:
			if status_effect.status_effect_type in skill.cured_status_effects:
				status_effects_to_remove.append(status_effect)
		
		for status_effect in status_effects_to_remove:
			remove_status_effect(status_effects, status_effect)
		
		if not status_effects_to_remove.empty():
			has_modified_stats = true
	
	if has_modified_stats:
		target_unit.recalculate_stats()


func calculate_damage(attacker_stats: StartingStats,
			defender_stats: StartingStats,
			power: float,
			weapon_type: int,
			attribute: int) -> int:
	var damage: float = 0
	
	if weapon_type == Enums.WeaponType.STAFF:
		damage = 1.8 * power * attacker_stats.attack * attacker_stats.attack / float(defender_stats.defense)
		
		damage = damage * (1 - _get_attribute_resistance(defender_stats, attribute, defender_stats.attribute))
	else:
		damage = 1.57 * power * attacker_stats.attack * attacker_stats.attack / float(defender_stats.defense)
		
		damage = damage * _get_weapon_type_advantage(weapon_type, defender_stats.weapon_type)
	
	return int(damage)


func inflict(status_effect_type: int, status_effects: Array) -> void:
	var accumulated_damage: int = 0
	
	for status_effect in status_effects:
		if status_effect.status_effect_type == status_effect_type:
			accumulated_damage += status_effect.calculate_damage(target_unit.get_stats())
			
			status_effect.update()
	
	target_unit.inflict_damage(accumulated_damage)
	
	var status_effects_to_remove := []
	
	for status_effect in status_effects:
		if status_effect.status_effect_type == status_effect_type and status_effect.is_done():
			status_effects_to_remove.append(status_effect)
	
	for status_effect in status_effects_to_remove:
		remove_status_effect(status_effects, status_effect)
	
	if not status_effects_to_remove.empty():
		target_unit.recalculate_stats()


func remove_status_effect(status_effects: Array, status_effect: StatusEffect) -> void:
	var index: int = status_effects.find(status_effect)
	
	if index != -1:
		status_effects.remove(index)
		
		status_effect_node2d.remove(status_effect.status_effect_type)


func _get_weapon_type_advantage(attacker_weapon_type: int, defender_weapon_type: int) -> float:
	var disadvantaged_weapon_type = Enums.WEAPON_RELATIONSHIPS.get(attacker_weapon_type)
	
	if disadvantaged_weapon_type == defender_weapon_type:
		return WEAPON_ADVANTAGE
	else:
		return WEAPON_DISADVANTAGE


func _get_attribute_resistance(defender_stats: StartingStats, attacker_attribute, defender_attribute) -> float:
	if attacker_attribute == defender_attribute:
		return defender_stats.same_attribute_resistance
	else:
		var disadvantaged_attribute = Enums.ATTRIBUTE_RELATIONSHIPS.get(attacker_attribute)
		
		if disadvantaged_attribute != null and disadvantaged_attribute == defender_attribute:
			# Vulnerable
			return -1.0
		else:
			# TODO: Use elemental resistance dictionary
			
			# No resistance
			return 0.0


func _can_inflict_status_effects(skill: Skill) -> bool:
	return random.randf() < skill.status_effect_infliction_rate


func _can_apply_status_effect(stats: StartingStats, status_effect: StatusEffect) -> bool:
	assert(not status_effect.status_effect_type == Enums.StatusEffectType.BUFF)
	assert(not status_effect.status_effect_type == Enums.StatusEffectType.REGENERATE)
	
	var vulnerability: float = stats.get_vulnerability(status_effect.status_effect_type)
	
	return random.randf() < vulnerability

