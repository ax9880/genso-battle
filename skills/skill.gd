extends Resource

class_name Skill

# Localizable string
export(String) var skill_name: String = ""
export(Enums.SkillType) var skill_type = Enums.SkillType.ATTACK

export(Enums.AreaOfEffect) var area_of_effect = Enums.AreaOfEffect.NONE
export(int, 1, 10, 1) var area_of_effect_size: int = 1
export(float, 0, 1, 0.1) var activation_rate: float = 0.3

# True if the skill pushes away affected enemies
export(bool) var is_pusher: bool = false

# Primary effect
export(float, 0, 3, 0.5) var primary_power: float = 1
export(Enums.WeaponType) var primary_weapon_type: int = Enums.WeaponType.SWORD

# Primary attribute, only used if weapon type is staff (elemental / magic)
export(Enums.Attribute) var primary_attribute: int = Enums.Attribute.NONE

# Note: Unused
export(float, 0, 3, 0.5) var secondary_power: float = 0.0
export(Enums.WeaponType) var secondary_weapon_type: int = Enums.WeaponType.GUN
export(Enums.Attribute) var secondary_attribute: int = Enums.Attribute.NONE

# If >0, can absorb damage from primary attack, if attack deals damage >0
export(float, 0, 1, 0.1) var absorb_rate: float = 0

# Max HP healed. Also applies to absorbed HP
export(int, 0, 9000, 100) var max_heal: int = 700

# Status effects that this skill applies on allies or
# inflicts on the enemy
# Array<StatusEffect>
export(Array, Resource) var status_effects: Array = []

# Not applied to buffs.
export(float, 0, 1, 0.1) var status_effect_infliction_rate: float = 0.3

# Status effects that this skill removes or cures
export(Array, Enums.StatusEffectType) var cured_status_effects: Array = []

export(PackedScene) var effect_scene: PackedScene = null

# Delayed skills are charged in one turn and activated in the next turn.
# Used only by enemies
export(bool) var is_delayed: bool = false


func is_physical() -> bool:
	return primary_weapon_type != Enums.WeaponType.STAFF


func is_attack() -> bool:
	return skill_type == Enums.SkillType.ATTACK


func is_healing() -> bool:
	return skill_type == Enums.SkillType.HEAL


func is_buff() -> bool:
	return skill_type == Enums.SkillType.BUFF


func has_status_effects() -> bool:
	return not status_effects.empty()


func can_cure_status_effects() -> bool:
	return not cured_status_effects.empty()


func is_enemy_targeted() -> bool:
	return is_attack() or skill_type == Enums.SkillType.DEBUFF or skill_type == Enums.SkillType.COUNTER


func is_targeted_individually() -> bool:
	return area_of_effect in Enums.AREAS_OF_EFFECT_WITH_INDIVIDUAL_TARGETING

