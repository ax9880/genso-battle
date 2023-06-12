extends Resource

class_name Skill

# Localizable string
export(String) var skill_name: String = ""
export(Enums.SkillType) var skill_type = Enums.SkillType.ATTACK

export(Enums.AreaOfEffect) var area_of_effect = Enums.AreaOfEffect.NONE
export(int, 0, 10, 1) var area_of_effect_size: int = 1
export(float, 0, 1, 0.1) var activation_rate: float = 0.3

# True if the skill pushes away affected enemies
export(bool) var is_pusher: bool = false

# Primary effect
export(float, 0, 3, 0.5) var primary_power: float = 1
export(Enums.WeaponType) var primary_weapon_type: int = Enums.WeaponType.SWORD

# Primary attribute, only used if weapon type is staff (elemental / magic)
export(Enums.Attribute) var primary_attribute: int = Enums.Attribute.NONE

export(float, 0, 3, 0.5) var secondary_power: float = 0.0
export(Enums.WeaponType) var secondary_weapon_type: int = Enums.WeaponType.GUN
export(Enums.Attribute) var secondary_attribute: int = Enums.Attribute.NONE

# If >0, can absorb damage from primary attack, if attack deals damage >0
export(float, 0, 1, 0.1) var absorb_rate: float = 0

# Max HP healed. Also applies to absorbed HP
export(int, 0, 9000, 100) var max_heal: int = 700

export(Enums.StatusEffectType) var status_effect: int = Enums.StatusEffectType.NONE

# If it's zero then it does not inflict a status effect
export(int, 0, 5, 1) var status_effect_duration_turns: int = 0

export(PackedScene) var effect_scene: PackedScene = null


func get_description() -> String:
	# TODO: Generate description based on attributes
	# Skill name, activation rate, area
	# ...
	return ""


func is_physical() -> bool:
	return primary_weapon_type != Enums.WeaponType.STAFF


func is_attack() -> bool:
	return skill_type == Enums.SkillType.ATTACK


func is_healing() -> bool:
	return skill_type == Enums.SkillType.HEAL or \
			skill_type == Enums.SkillType.CURE_AILMENT


func is_buff() -> bool:
	return skill_type == Enums.SkillType.BUFF


func is_enemy_targeted() -> bool:
	return is_attack() or skill_type == Enums.SkillType.DEBUFF or skill_type == Enums.SkillType.COUNTER


func is_targeted_individually() -> bool:
	return area_of_effect in Enums.AREAS_OF_EFFECT_WITH_INDIVIDUAL_TARGETING
