extends Node

enum Attribute {
	# Non-elemental
	NONE,
	
	# Attribute 1, opposes attribute 2
	ATTRIBUTE_1,
	
	# Attribute 2, opposes attribute 1
	ATTRIBUTE_2
}

enum WeaponType {
	# Sword
	SWORD,
	
	# Spears, polearms
	SPEAR,
	
	# Guns
	GUN,
	
	# Elemental
	STAFF
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
	CHAIN
	
	# Border, outer columns/rows, corners, diamond
}

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
