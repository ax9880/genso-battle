extends Node

enum Attribute {
	# Non-elemental (e.g. healing)
	NONE,
	
	# Attribute 1, opposes attribute 2
	ATTRIBUTE_1,
	
	# Attribute 2, opposes attribute 1
	ATTRIBUTE_2
}

# dict[winning attribute] = losing attribute
const ATTRIBUTE_RELATIONSHIPS: Dictionary = {
	Attribute.ATTRIBUTE_1: Attribute.ATTRIBUTE_2,
	Attribute.ATTRIBUTE_2: Attribute.ATTRIBUTE_1
}

enum WeaponType {
	# Sword
	SWORD,
	
	# Guns
	GUN,
	
	# Spears, polearms
	SPEAR,
	
	# Elemental
	STAFF
}

# {Weapon type: weapon type it has an advantage over}
const WEAPON_RELATIONSHIPS: Dictionary = {
	# Sword beats gun
	# Gun beats spear
	# Spear beats sword
	WeaponType.SWORD: WeaponType.GUN,
	WeaponType.GUN: WeaponType.SPEAR,
	WeaponType.SPEAR: WeaponType.SWORD,
}

const WEAPON_TYPE_TEXTURES: Dictionary = {
	WeaponType.SWORD: "res://assets/ui/sword.png",
	WeaponType.SPEAR: "res://assets/ui/spear.png",
	WeaponType.GUN: "res://assets/ui/gun.png",
	WeaponType.STAFF: "res://assets/ui/staff.png"
}

enum StatusEffectType {
	NONE,
	
	POISON,
	
	SLEEP,
	
	PARALYZE,
	
	CONFUSE,
	
	DEMORALIZE
}

# https://terrabattle.fandom.com/wiki/Skills
enum AreaOfEffect {
	# Affects pincered units but for weapon skills only activates when the unit initiates a pincer attack
	NONE,
	
	# Passively equipped
	EQUIP,
	
	# Affects pincered units. Activates whether unit leads or is part of a chain
	PINCER,
	
	AREA_X,
	
	CROSS_X,
	
	SELF,
	
	HORIZONTAL_X,
	
	VERTICAL_X,
	
	ROWS_X,
	
	COLUMNS_X,
	
	# Affects units in the chain
	CHAIN,
	
	ALL
	
	# Border, outer columns/rows, corners, diamond
}

const AREAS_OF_EFFECT_WITH_INDIVIDUAL_TARGETING := [
	AreaOfEffect.NONE,
	AreaOfEffect.EQUIP,
	AreaOfEffect.PINCER,
	AreaOfEffect.SELF,
	AreaOfEffect.CHAIN,
	AreaOfEffect.ALL
]

enum SkillTier {
	FIRST = 0,
	
	SECOND = 1,
	
	THIRD = 2
}

enum SkillType {
	ATTACK,
	
	HEAL,
	
	# Cures specific status effect(s)
	CURE_AILMENT,
	
	BUFF,
	
	DEBUFF,
	
	COUNTER
}

enum DragMode {
	CLICK,
	HOLD
}
