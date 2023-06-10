extends Node2D


class SkillAttack extends Reference:
	var unit: Unit
	
	var skill: Skill


var unit_queue := []
var dead_units := []

var buff_skills := []
var attack_skills := []
var heal_skills := []

var active_pincer: Pincerer.Pincer = null

# Array<Array<Unit>> which include the pincering unit and the chained units
var complete_chains := []

# Array<Unit>
var allies := []

# Array<Unit>
var enemies := []

var units_removed_from_play := []

# To calculate areas of effect
var grid: Grid

# Finished executing a pincer
signal skill_activation_phase_finished
signal attack_skill_phase_finished
signal heal_phase_finished
signal finished_checking_for_dead_units

signal pincer_executed


func start_skill_activation_phase(pincer: Pincerer.Pincer, _grid: Grid, _allies: Array = [], _enemies: Array = []) -> void:
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
	
	# TODO
	#var activated_skills: Array = unit.activate_skills()
	#while(unit != null and not activated_skills.empty()):
		#unit = unit_queue.pop_front()
		#activated_skills = unit.activate_skills()
	
	if unit != null:
		var activated_skills: Array = unit.activate_skills()
		
		if activated_skills.empty():
			# If no skills are activated then go to the next unit right away
			# I don't like the recursion but it makes it easier
			_activate_next_skill()
		else:
			_queue_skills(unit, activated_skills)
			
			unit.play_skill_activation_animation(activated_skills)
	else:
		$SkillActivationTimer.stop()
		
		emit_signal("skill_activation_phase_finished")


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


# Add skill to each queue according to its skill type
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


func start_attack_skill_phase() -> void:
	_execute_next_skill(attack_skills, "attack_skill_phase_finished")


func _execute_next_skill(skill_queue: Array, finish_signal: String) -> void:
	var next_skill: SkillAttack = skill_queue.pop_front()
	
	if next_skill != null:
		var chain: Array = _find_chain(next_skill.unit, complete_chains)
		
		assert(!chain.empty())
		
		# Array<Cell>
		var target_cells: Array = _find_area_of_effect_target_cells(next_skill.unit,
			next_skill.skill,
			active_pincer.pincered_units,
			chain)
		
		var filtered_cells: Array = _filter_cells(next_skill.unit, next_skill.skill, target_cells)
		
		var skill_effect: Node2D = next_skill.skill.effect_scene.instance()
		
		add_child(skill_effect)
		
		var _error = skill_effect.connect("effect_finished", self, "_on_SkillEffect_effect_finished", [skill_queue, finish_signal])
		
		skill_effect.start(next_skill.unit, next_skill.skill, filtered_cells)
	else:
		emit_signal(finish_signal)


# Find the chain a unit belongs to.
# Return Array<Unit>
func _find_chain(unit: Unit, chains: Array) -> Array:
	for chain in chains:
		if chain.find(unit) != -1:
			return chain
	
	printerr("Unit %s does not belong to a chain" % unit.name)
	
	return []


func check_dead_units() -> void:
	_add_dead_units_to_queue(allies, dead_units)
	_add_dead_units_to_queue(enemies, dead_units)
	
	_check_next_dead_unit()
	
	$DeathAnimationTimer.start()


func _check_next_dead_unit() -> void:
	var unit: Unit = dead_units.pop_front()
	
	if unit != null:
		var _error = unit.connect("death_animation_finished", self, "_on_Unit_death_animation_finished")
		
		unit.play_death_animation()
		
		# If 2x2, check neighbor cells
		var cell: Cell = grid.get_cell_from_position(unit.position)
		cell.unit = null
	else:
		$DeathAnimationTimer.stop()
		
		emit_signal("finished_checking_for_dead_units")


func _add_dead_units_to_queue(units: Array, queue: Array) -> void:
	for unit in units:
		if unit.is_dead():
			queue.push_back(unit)


func start_heal_phase() -> void:
	_execute_next_skill(heal_skills, "heal_phase_finished")


func start_status_effect_phase() -> void:
	emit_signal("pincer_executed")


# Filter cells to leave only the ones with null units or with targeted units that are
# either allies or enemies depending on the skill type
func _filter_cells(unit: Unit, skill: Skill, targeted_cells: Array) -> Array:
	# If the unit is 2x2 it will be in more than one cell, so don't add it twice
	
	# Array<Cell>
	var filtered_cells := []
	
	if skill.is_enemy_targeted():
		for cell in targeted_cells:
			if cell.unit == null or cell.unit.is_enemy(unit.faction):
				if filtered_cells.find(cell) == -1:
					filtered_cells.push_back(cell)
	else:
		for cell in targeted_cells:
			if cell.unit == null or cell.unit.is_ally(unit.faction):
				if filtered_cells.find(cell) == -1:
					filtered_cells.push_back(cell)
	
	return filtered_cells


# Returns Array<Cell>
func _find_area_of_effect_target_cells(var unit: Unit,
		var skill: Skill,
		var pincered_units: Array = [],
		var chain: Array = [] # Including the pincering unit that started the chain
	) -> Array:
	
	var cell: Cell = grid.get_cell_from_position(unit.position)
	
	match(skill.area_of_effect):
		Enums.AreaOfEffect.NONE, Enums.AreaOfEffect.PINCER:
			return _units_to_cells(pincered_units)
		Enums.AreaOfEffect.AREA_X:
			var targets := []
			
			for x in range(cell.coordinates.x - skill.area_of_effect_size, cell.coordinates.x + skill.area_of_effect_size + 1):
				for y in range(cell.coordinates.y - skill.area_of_effect_size, cell.coordinates.y + skill.area_of_effect_size + 1):
					var candidate_cell_coordinates := Vector2(x, y)
					
					if grid._is_in_range(candidate_cell_coordinates):
						targets.push_back(grid.get_cell_from_coordinates(candidate_cell_coordinates))
			
			return targets
		Enums.AreaOfEffect.CROSS_X:
			var targets := []
			
			targets.append_array(_find_horizontal_x_cells(cell, skill.area_of_effect_size))
			targets.append_array(_find_vertical_x_cells(cell, skill.area_of_effect_size))
			
			return targets
		Enums.AreaOfEffect.SELF:
			return _units_to_cells([unit])
		Enums.AreaOfEffect.HORIZONTAL_X:
			# TODO: If unit is 2x2 then you have to do this for each cell it occupies
			# and then the cells that it occupies are filtered out
			
			return _find_horizontal_x_cells(cell, skill.area_of_effect_size)
		Enums.AreaOfEffect.VERTICAL_X:

			return _find_vertical_x_cells(cell, skill.area_of_effect_size)
		Enums.AreaOfEffect.ROWS_X:
			var targets := []
			
			var start: int
			var area_of_effect_size_halved := int(float(skill.area_of_effect_size) / 2.0)
			
			if skill.area_of_effect_size % 2 == 0:
				start = int(cell.coordinates.y) - area_of_effect_size_halved + 1
			else:
				start = int(cell.coordinates.y) - area_of_effect_size_halved
			
			var end: int = int(cell.coordinates.y) + area_of_effect_size_halved
			
			assert(start <= end)
			
			for x in range(grid.width):
				for y in range(start, end + 1):
					var candidate_cell_coordinates := Vector2(x, y)
					
					if grid._is_in_range(candidate_cell_coordinates):
						targets.push_back(grid.get_cell_from_coordinates(candidate_cell_coordinates))
			
			return targets
		Enums.AreaOfEffect.COLUMNS_X:
			var targets := []
			
			var start: int
			var area_of_effect_size_halved := int(float(skill.area_of_effect_size) / 2.0)
			
			if skill.area_of_effect_size % 2 == 0:
				start = int(cell.coordinates.x) - area_of_effect_size_halved + 1
			else:
				start = int(cell.coordinates.x) - area_of_effect_size_halved
			
			var end: int = int(cell.coordinates.x) + area_of_effect_size_halved
			
			assert(start <= end)
			
			for x in range(start, end + 1):
				for y in range(grid.height):
					var candidate_cell_coordinates := Vector2(x, y)
					
					if grid._is_in_range(candidate_cell_coordinates):
						targets.push_back(grid.get_cell_from_coordinates(candidate_cell_coordinates))
			
			return targets
		Enums.AreaOfEffect.CHAIN:
			return _units_to_cells(chain)
		Enums.AreaOfEffect.ALL:
			var all_units := []
			
			all_units.append_array(allies)
			all_units.append_array(enemies)
			
			return _units_to_cells(all_units)
		_:
			printerr("Area of effect is not implemented, can't find area: ", skill.area_of_effect)
			return []


func _find_horizontal_x_cells(start_cell: Cell, area_of_effect_size: int) -> Array:
	var targets := []
	
	for x in range(start_cell.coordinates.x - area_of_effect_size, start_cell.coordinates.x + area_of_effect_size + 1):
		var candidate_cell_coordinates := Vector2(x, start_cell.coordinates.y)
		
		if grid._is_in_range(candidate_cell_coordinates):
			targets.push_back(grid.get_cell_from_coordinates(candidate_cell_coordinates))
	
	return targets


func _find_vertical_x_cells(start_cell: Cell, area_of_effect_size: int) -> Array:
	var targets := []
	
	for y in range(start_cell.coordinates.y - area_of_effect_size, start_cell.coordinates.y + area_of_effect_size + 1):
		var candidate_cell_coordinates := Vector2(start_cell.coordinates.x, y)
		
		if grid._is_in_range(candidate_cell_coordinates):
			targets.push_back(grid.get_cell_from_coordinates(candidate_cell_coordinates))
	
	return targets


func _units_to_cells(units: Array) -> Array:
	var cells := []
	
	# If a unit is 2x2 then add all the cells that it occupies
	for unit in units:
		cells.push_back(grid.get_cell_from_position(unit.position))
	
	return cells


func _on_SkillEffect_effect_finished(skill_queue: Array, finish_signal: String) -> void:
	_execute_next_skill(skill_queue, finish_signal)


func _on_SkillActivationTimer_timeout() -> void:
	_activate_next_skill()


func _on_DeathAnimationTimer_timeout() -> void:
	_check_next_dead_unit()


func _on_Unit_death_animation_finished(unit: Unit) -> void:
	unit.get_parent().remove_child(unit)
	
	units_removed_from_play.push_back(unit)


func _on_PincerExecutor_tree_exiting() -> void:
	for unit in units_removed_from_play:
		unit.free()
