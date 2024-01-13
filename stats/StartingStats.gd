extends Resource

class_name StartingStats


export var health: int = 0

export var attack: int = 0
export var spiritual_attack: int = 0
export var defense: int = 0
export var spiritual_defense: int = 0

# General status ailment vulnerability. The greater it is the
# more vulnerable to status ailments. If it's zero then the unit
# is immune (besides exceptions in status_ailment_vulnerabilities).
# If it's greater than 1 then that status effect should cause extra damage
export(float, 0, 5, 0.1) var status_ailment_vulnerability: float = 1.0

# Dictionary<StatusAilmentType (String), float>
# Vulnerabilities to specific status ailments
# 0: immune. 1: completely vulnerable
export var status_ailment_vulnerabilities: Dictionary = {}

# Same attribute resistance. If it's > 1 then attacks with same attribute
# should heal the unit
export(float, 0, 2, 0.1) var same_attribute_resistance: float = 0.0

# Attribute of unit
export(Enums.Attribute) var attribute: int = Enums.Attribute.NONE

# Weapon type of unit
export(Enums.WeaponType) var weapon_type: int = Enums.WeaponType.SWORD

# Max turn counter (only applies to AI-controlled characters)
export(int, 0, 10, 1) var max_turn_counter: int = 3

# How many cells this unit can move (only applies to AI-controlled characters)
export(int, 0, 15, 1) var movement_range: int = 5


func is_physical() -> bool:
	return weapon_type != Enums.WeaponType.STAFF
