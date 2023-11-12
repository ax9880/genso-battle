extends Resource

class_name StartingStats


export var health: int = 0

export var attack: int = 0
export var spiritual_attack: int = 0
export var defense: int = 0
export var spiritual_defense: int = 0

# General status ailment vulnerability. The greater it is the
# more vulnerable to status ailments. If it's zero then the unit
# is immune (besides exceptions in status_ailment_vulnerabilities)
export(float, 0, 5, 0.1) var status_ailment_vulnerability: float = 0.0

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


# TODO: Erase, not used anymore
func to_dictionary() -> Dictionary:
	var dicttionary := {
	  "health": health,
	  "attack": attack,
	  "spiritual_attack": spiritual_attack,
	  "defense": defense,
	  "spiritual_defense": spiritual_defense,
	  "status_ailment_vulnerability": status_ailment_vulnerability,
	  "status_ailment_vulnerabilities": status_ailment_vulnerabilities,
	  "same_attribute_resistance": same_attribute_resistance,
	  "attribute": attribute,
	  "weapon_type": weapon_type,
	  "max_turn_counter": max_turn_counter,
	  "movement_range": movement_range,
	}
	
	return dicttionary


func from_dictionary(dictionary: Dictionary) -> void:
	health = dictionary.health
	attack = dictionary.attack
	spiritual_attack = dictionary.spiritual_attack
	defense = dictionary.defense
	spiritual_defense = dictionary.spiritual_defense

	status_ailment_vulnerability = dictionary.status_ailment_vulnerability
	status_ailment_vulnerabilities = dictionary.status_ailment_vulnerabilities

	same_attribute_resistance = dictionary.same_attribute_resistance

	attribute = dictionary.attribute
	weapon_type = dictionary.weapon_type
	
	max_turn_counter = dictionary.max_turn_counter
	movement_range = dictionary.movement_range
