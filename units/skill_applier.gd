extends Node


const WEAPON_ADVANTAGE: float = 2.0
const WEAPON_DISADVANTAGE: float = 0.8

const PHYSICAL_DAMAGE_MODIFIER: float = 1.57
const STAFF_DAMAGE_MODIFIER: float = 1.57


export(NodePath) var target_unit_path: NodePath
export(NodePath) var status_effect_node2d_path: NodePath

var _random := RandomNumberGenerator.new()

onready var _status_effect_node2d: Node2D = get_node(status_effect_node2d_path)
onready var _target_unit: Unit = get_node(target_unit_path)


func _ready() -> void:
	_random.randomize()


# Applies a skill, inflicts/heals damage, adds/removes status effects and stats modifiers
func apply_skill(unit: Unit,
		skill: Skill,
		on_damage_absorbed_callback: FuncRef,
		status_effects: Array) -> void:
	if (skill.is_attack() or skill.is_healing()) and skill.primary_power > 0:
		var damage := calculate_damage(unit.get_stats(), _target_unit.get_stats(), skill.primary_power, skill.primary_weapon_type, skill.primary_attribute)
		
		damage = int(damage * _random.randf_range(0.9, 1.1))
		
		if skill.is_healing():
			damage = -damage * 3
		
		var absorbed_damage = int(skill.absorb_rate * damage)
		
		on_damage_absorbed_callback.call_func(absorbed_damage)
		
		_target_unit.inflict_damage(damage)
		
		if damage > 0:
			_target_unit.on_attacked()
	
	var has_modified_stats: bool = false
	
	# If it has status effect, try to apply it
	# Skill can cause damage AND inflict status effect, so it can't be if-else
	if skill.has_status_effects() and _can_inflict_status_effects(skill):
		for status_effect_resource in skill.status_effects:
			var status_effect: StatusEffect = status_effect_resource.duplicate()
			
			if status_effect.is_buff() or _can_apply_status_effect(_target_unit.get_stats(), status_effect):
				has_modified_stats = true
				
				status_effect.initialize(unit.get_stats())
				
				status_effects.append(status_effect)
				
				print("Applied %s to %s" % [status_effect.status_effect_type, _target_unit.name])
				
				_status_effect_node2d.add(status_effect.status_effect_type, status_effect.effect_scene)
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
		_target_unit.recalculate_stats()


func calculate_damage(attacker_stats: Stats,
			defender_stats: Stats,
			power: float,
			weapon_type: int,
			attribute: int) -> int:
	var damage: float = 0
	
	if weapon_type == Enums.WeaponType.STAFF:
		damage = STAFF_DAMAGE_MODIFIER * power * attacker_stats.attack * attacker_stats.attack / float(defender_stats.defense)
		
		damage = damage * (1 - _get_attribute_resistance(defender_stats, attribute, defender_stats.attribute))
	else:
		damage = PHYSICAL_DAMAGE_MODIFIER * power * attacker_stats.attack * attacker_stats.attack / float(defender_stats.defense)
		
		damage = damage * _get_weapon_type_advantage(weapon_type, defender_stats.weapon_type)
	
	return int(damage)


func inflict(status_effect_type: int, status_effects: Array) -> void:
	var accumulated_damage: int = 0
	
	for status_effect in status_effects:
		if status_effect.status_effect_type == status_effect_type:
			accumulated_damage += status_effect.calculate_damage(_target_unit.get_stats())
			
			status_effect.update()
	
	_target_unit.inflict_damage(accumulated_damage)
	
	var status_effects_to_remove := []
	
	for status_effect in status_effects:
		if status_effect.status_effect_type == status_effect_type and status_effect.is_done():
			status_effects_to_remove.append(status_effect)
	
	for status_effect in status_effects_to_remove:
		remove_status_effect(status_effects, status_effect)
	
	if not status_effects_to_remove.empty():
		_target_unit.recalculate_stats()


func remove_status_effect(status_effects: Array, status_effect: StatusEffect) -> void:
	var index: int = status_effects.find(status_effect)
	
	if index != -1:
		status_effects.remove(index)
		
		_status_effect_node2d.remove(status_effect.status_effect_type)


func _get_weapon_type_advantage(attacker_weapon_type: int, defender_weapon_type: int) -> float:
	if attacker_weapon_type == defender_weapon_type or attacker_weapon_type == Enums.WeaponType.STAFF:
		return 1.0
	
	var disadvantaged_weapon_type = Enums.WEAPON_RELATIONSHIPS.get(attacker_weapon_type)
	
	if disadvantaged_weapon_type == defender_weapon_type:
		return WEAPON_ADVANTAGE
	else:
		return WEAPON_DISADVANTAGE


func _get_attribute_resistance(defender_stats: Stats, attacker_attribute, defender_attribute) -> float:
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
	return _random.randf() < skill.status_effect_infliction_rate


func _can_apply_status_effect(stats: Stats, status_effect: StatusEffect) -> bool:
	assert(not status_effect.status_effect_type == Enums.StatusEffectType.BUFF)
	assert(not status_effect.status_effect_type == Enums.StatusEffectType.REGENERATE)
	
	var vulnerability: float = stats.get_vulnerability(status_effect.status_effect_type)
	
	return _random.randf() < vulnerability

