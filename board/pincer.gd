extends Reference
class_name Pincer


# Array<Unit>
var pincering_units: Array

# Array<Unit>
var pincered_units: Array

# Dictionary<Unit, Array<Array<Unit>>>
# Where chain_families[unit] consists of all the chains for the given unit (a chain family)
# And where a chain family consists of lists of chained units (chain). The index of each chain
# is its chain level. The chain does include the pincering units.
var chain_families: Dictionary

var pincer_orientation: int = Enums.PincerOrientation.HORIZONTAL

# Start position and end position so the pincer highlight
# uses these positions and it works correctly for 2x2 units
var start_position: Vector2
var end_position: Vector2


# Size of the pincer (amount of units involved, including pincering and pincered units)
func size() -> int:
	var size_modifier: int = 0
	
	for unit in pincered_units:
		if unit.is2x2():
			size_modifier += 1
	
	return pincering_units.size() + pincered_units.size() + size_modifier


# A pincer is valid if at least one pincered unit is alive, and all the
# pincering units are alive.
# Pincered units can be killed by skills before the pincer is executed.
# Pincering units can be killed by traps.
func is_valid() -> bool:
	var is_any_pincered_unit_alive: bool = false
	
	for unit in pincered_units:
		is_any_pincered_unit_alive = is_any_pincered_unit_alive or unit.is_alive()
	
	var is_pincering_units_alive: bool = true
	
	for unit in pincering_units:
		is_pincering_units_alive = is_pincering_units_alive and unit.is_alive()
	
	return is_any_pincered_unit_alive and is_pincering_units_alive
