extends Node2D


class SkillAttack extends Reference:
	var unit: Unit
	
	var skill: Skill


var unit_queue := []

var buff_skills := []
var attack_skills := []
var heal_skills := []

var random: RandomNumberGenerator = RandomNumberGenerator.new()

var active_pincer: Pincerer.Pincer = null

# Array<Array<Unit>> which include the pincering unit and the chained units
var complete_chains := []
var allies := []
var enemies := []

# To calculate areas
var grid: Grid

# Finished executing a pincer
signal pincer_executed


func execute_pincer(pincer: Pincerer.Pincer, _grid: Grid, _allies: Array = [], _enemies: Array = []) -> void:
	active_pincer = pincer
	grid = _grid
	allies = _allies
	enemies = _enemies
	
	unit_queue = _queue_units(pincer)
	complete_chains = _build_chains_including_pincering_unit(pincer)
	
	$SkillActivationTimer.start()
	
	_activate_next_skill()


func _activate_next_skill() -> void:
	var unit: Unit = unit_queue.pop_front()
	
	if unit != null:
		var activated_skills: Array = unit.activate_skills(random)
		
		# Add skill to each queue according to its skill type
		_queue_skills(unit, activated_skills)
		
		unit.play_skill_activation_animation(activated_skills)
	else:
		# activation done
		$SkillActivationTimer.stop()
		
		_start_attack_skill_phase()


# Queue units to activate their skills one by one
func _queue_units(pincer: Pincerer.Pincer) -> Array:
	# Array<Unit>
	var units := []
	
	# Leading units first
	for pincering_unit in pincer.pincering_units:
		units.push_back(pincering_unit)
	
	# Chained units second
	# Same order as attack
	
	for pincering_unit in pincer.pincering_units:
		for chain in pincer.chain_families[pincering_unit]:
			units.append_array(chain)
	
	return units


# Returns Array<Array<Unit>>
func _build_chains_including_pincering_unit(pincer: Pincerer.Pincer) -> Array:
	var chains = []
	
	for pincering_unit in pincer.pincering_units:
		var complete_chain := []
		
		complete_chain.push_back(pincering_unit)
		
		for chain in pincer.chain_families[pincering_unit]:
			complete_chain.append_array(chain)
		
		chains.push_back(complete_chain)
	
	return chains


func _queue_skills(unit: Unit, activated_skills: Array) -> void:
	for skill in activated_skills:
		var skill_attack: SkillAttack = SkillAttack.new()
		
		skill_attack.unit = unit
		skill_attack.skill = skill
		
		match(skill.skill_type):
			Enums.SkillType.ATTACK:
				attack_skills.push_back(skill_attack)
			Enums.SkillType.HEAL, Enums.SkillType.CURE_AILMENT:
				heal_skills.push_back(skill_attack)
			_:
				printerr("Unrecognized skill type: ", skill.skill_type)


func _start_attack_skill_phase() -> void:
	var next_skill_attack: SkillAttack = attack_skills.pop_front()
	
	if next_skill_attack != null:
		var chain: Array = _find_chain(next_skill_attack.unit, complete_chains)
		
		# FIXME: Check. Can chain be empty?
		#assert(!chain.empty())
		
		# Array<CellArea2D>
		var target_cells: Array = _find_area_of_effect_target_cells(next_skill_attack.unit,
			next_skill_attack.skill,
			active_pincer.pincered_units,
			chain)
		
		# Instance its effect scene
		# Connect to a signal that tells you when the animation is finished
		# And in that signal call this method again
		var skill_effect: Node2D = next_skill_attack.skill.skill_effect_scene.instance()
		
		add_child(skill_effect)
		
		skill_effect.connect("effect_finished", self, "_on_SkillEffect_effect_finished")
		
		skill_effect.execute(next_skill_attack.unit, next_skill_attack.skill, target_cells)
	else:
		print("no skills activated")
		
		emit_signal("pincer_executed")


# Find the chain a unit belongs to.
# Return Array<Unit>
func _find_chain(unit: Unit, chains: Array) -> Array:
	for chain in chains:
		if chain.find(unit) != -1:
			return chain
	
	printerr("Unit %s does not belong to a chain" % unit.name)
	
	return []


func _on_SkillEffect_effect_finished() -> void:
	_activate_next_skill()



func _on_SkillActivationTimer_timeout() -> void:
	_activate_next_skill()


# Filter cells to leave only the ones with null units or with targeted units that are
# either allies or enemies depending on the skill type
func _filter_cells(unit: Unit, skill: Skill, targeted_cells: CellArea2D) -> Array:
	# If the unit is 2x2 it will be in more than one cell, so don't add it twice
	
	# Array<CellArea2D>
	var filtered_cells := []
	
	if skill.is_healing():
		for cell in targeted_cells:
			if cell.unit == null or cell.unit.is_ally(unit.faction):
				if filtered_cells.find(cell) == -1:
					filtered_cells.push_back(cell)
	else:
		for cell in targeted_cells:
			if cell.unit == null or cell.unit.is_enemy(unit.faction):
				if filtered_cells.find(cell) == -1:
					filtered_cells.push_back(cell)
	
	return filtered_cells


# Returns Array<CellArea2D>
func _find_area_of_effect_target_cells(var unit: Unit,
		var skill: Skill,
		var pincered_units: Array = [],
		var chain: Array = [] # Including the pincering unit that started the chain
	) -> Array:
	
	var area_of_effect: int = skill.area_of_effect
	var cell: CellArea2D = grid.get_cell_from_position(unit.position)
	
	match(area_of_effect):
		Enums.AreaOfEffect.NONE, Enums.AreaOfEffect.PINCER:
			return _units_to_cells(pincered_units)
		Enums.AreaOfEffect.SELF:
			return _units_to_cells([unit])
		Enums.AreaOfEffect.CHAIN:
			return _units_to_cells(chain)
		Enums.AreaOfEffect.HORIZONTAL_X:
			var targets := []
			
			# TODO: If unit is 2x2 then you have to do this for each cell it occupies
			# and then the cells that it occupies are filtered out
			
			for x in range(cell.coordinates.x - skill.area_of_effect_size, cell.coordinates.x + skill.area_of_effect_size):
				var candidate_cell_coordinates := Vector2(x, cell.coordinates.y)
				
				if grid._is_in_range(candidate_cell_coordinates):
					targets.push_back(grid.get_cell_from_coordinates(candidate_cell_coordinates))
			
			return targets
		Enums.AreaOfEffect.VERTICAL_X:
			var targets := []
			
			for y in range(cell.coordinates.y - skill.area_of_effect_size, cell.coordinates.y + skill.area_of_effect_size):
				var candidate_cell_coordinates := Vector2(cell.coordinates.x, y)
				
				if grid._is_in_range(candidate_cell_coordinates):
					targets.push_back(grid.get_cell_from_coordinates(candidate_cell_coordinates))
			
			return targets
		Enums.AreaOfEffect.CROSS_X:
			#var horizontal_targets: Array = find_area_of_effect_target_cells()
			#var vertical_targets =
			# join them without duplicates
			
			return []
		Enums.AreaOfEffect.AREA_X:
			
			return []
		Enums.AreaOfEffect.ALL:
			var all_units := []
			
			all_units.append(allies)
			all_units.append(enemies)
			
			return _units_to_cells(all_units)
		_:
			return []


func _units_to_cells(units: Array) -> Array:
	var cells := []
	
	# If a unit is 2x2 then add all the cells that it occupies
	for unit in units:
		cells.push_back(grid.get_cell_from_position(unit.position))
	
	return cells
	
