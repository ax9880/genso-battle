extends Resource

class_name StartingStats


enum Attribute {
	ATTRIBUTE_1 = 0,
	
	ATTRIBUTE_2 = 1
}

enum WeaponType {
	SWORD = 0,
	
	SPEAR = 1,
	
	GUN = 2,
	
	STAFF = 3
}

enum StatusAilmentType {
	POISON = 0,
	
	SLEEP = 1,
	
	PARALYZE = 2,
	
	CONFUSE = 3,
	
	DEMORALIZE = 4
}

# https://terrabattle.fandom.com/wiki/Skills
enum AreaOfEffect {
	# Affects pincered units
	NONE = 0,
	
	# Passively equipped
	EQUIP = 1,
	
	# Affects pincered units
	PINCER = 2,
	
	AREA_X = 3,
	
	CROSS_X = 4,
	
	SELF = 5,
	
	HORIZONTAL_X = 6,
	
	VERTICAL_X = 7,
	
	ROWS_X = 8,
	
	COLUMNS_X = 9
	
	# Border, outer columns/rows, corners, diamond
}

enum SkillTier {
	FIRST = 0,
	
	SECOND = 1,
	
	THIRD = 2
}

enum SkillType {
	BUFF = 0,
	
	DEBUFF = 1,
	
	ATTACK = 2,
	
	HEAL = 3,
	
	COUNTER = 4
}

export var health: int

export var attack: int
export var spiritual_attack: int
export var defense: int
export var spiritual_defense: int

# General status ailment vulnerability. The greater it is the
# more vulnerable to status ailments. If it's zero then the unit
# is immune (besides exceptions in status_ailment_vulnerabilities)
export(float, 0, 5, 0.1) var status_ailment_vulnerability: float

# Dictionary<StatusAilmentType (as int? String?), float>
# Vulnerabilities to specific status ailments
export var status_ailment_vulnerabilities: Dictionary

# Same attribute resistance. If it's > 1 then attacks with same attribute
# should heal the unit
export(float, 0, 2, 0.1) var same_attribute_resistance: float

export(Attribute) var attribute: int
export(WeaponType) var weapon_type: int
