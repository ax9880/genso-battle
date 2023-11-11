extends Node2D


class SkillAttack extends Reference:
	var unit: Unit
	
	var skill: Skill


export(PackedScene) var chain_previewer_packed_scene: PackedScene

export(PackedScene) var pincer_highlight_packed_scene: PackedScene


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
var current_z_index: int = 1

var pusher: Pusher = null

# Array<ChainPreviewer>
var chain_previews := []

# The names of these signals are passed as parameters and emitted inside functions
signal skill_activation_phase_finished
signal attack_skill_phase_finished
signal heal_phase_finished
signal finished_checking_for_dead_units

# Finished executing a pincer
signal pincer_executed


func initialize(_grid: Grid, _allies: Array, _enemies: Array) -> void:
	grid = _grid
	allies = _allies
	enemies = _enemies


func start_skill_activation_phase(pincer: Pincerer.Pincer, _grid: Grid, _allies: Array = [], _enemies: Array = []) -> void:
	active_pincer = pincer
	
	initialize(_grid, _allies, _enemies)
	
	unit_queue = _queue_units(pincer)
	complete_chains = _build_chains_including_pincering_unit(pincer)
	_show_chain_previews(pincer)
	
	# yield?
	highlight_pincer(pincer)
	
	$SkillActivationTimer.start()
	
	current_z_index = 2
	
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
			
			unit.play_skill_activation_animation(activated_skills, current_z_index)
			
			unit.play_scale_and_and_down_animation()
		
		current_z_index += 1
	else:
		$SkillActivationTimer.stop()
		
		if not (attack_skills.empty() and heal_skills.empty()):
			yield(get_tree().create_timer(1), "timeout")
		
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


func _show_chain_previews(pincer: Pincerer.Pincer) -> void:
	clear_chain_previews()
	
	for unit in pincer.pincering_units:
		var chain_previewer = chain_previewer_packed_scene.instance()
		
		add_child(chain_previewer)
		chain_previews.push_back(chain_previewer)
		
		chain_previewer.update_preview(unit, grid.get_cell_from_position(unit.position))
		chain_previewer.z_index = -1


func clear_chain_previews() -> void:
	for chain_previewer in chain_previews:
		chain_previewer.queue_free()
	
	chain_previews.clear()


func highlight_pincer(pincer: Pincerer.Pincer) -> void:
	var pincer_higlight: Node2D = pincer_highlight_packed_scene.instance()
	
	add_child(pincer_higlight)
	
	pincer_higlight.initialize(pincer)


func start_attack_skill_phase() -> void:
	_execute_next_skill(attack_skills, "attack_skill_phase_finished")


func _execute_next_skill(skill_queue: Array, finish_signal: String) -> void:
	var next_skill: SkillAttack = skill_queue.pop_front()
	
	if next_skill != null:
		var chain: Array = _find_chain(next_skill.unit, complete_chains)
		
		assert(!chain.empty())
		
		# Array<Cell>
		var target_cells: Array = BoardUtils.find_area_of_effect_target_cells(next_skill.unit,
			next_skill.unit.position,
			next_skill.skill,
			grid,
			active_pincer.pincered_units,
			chain,
			allies,
			enemies)
		
		var skill_effect: Node2D = next_skill.skill.effect_scene.instance()
		
		add_child(skill_effect)
		
		var _error = skill_effect.connect("effect_finished", self, "_on_SkillEffect_effect_finished", [skill_queue, finish_signal])
		
		var start_cell: Cell = grid.get_cell_from_position(next_skill.unit.position)
		
		skill_effect.start(next_skill.unit, next_skill.skill, target_cells, start_cell, pusher)
		
		next_skill.unit.stop_scale_and_and_down_animation()
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
	dead_units.clear()
	
	_add_dead_units_to_queue(allies, dead_units)
	_add_dead_units_to_queue(enemies, dead_units)
	
	_check_next_dead_unit()
	
	$DeathAnimationTimer.start()


func _check_next_dead_unit() -> void:
	var unit: Unit = dead_units.pop_front()
	
	if unit != null and not unit.is_death_animation_playing():
		var _error = unit.connect("death_animation_finished", self, "_on_Unit_death_animation_finished")
		
		unit.play_death_animation()
		
		# If 2x2, check neighbor cells
		var cell: Cell = grid.get_cell_from_position(unit.position)
		
		if cell.unit != null:
			assert(cell.unit == unit)
		else:
			printerr("Unit %s died but cell unit is null" % unit.name)
		
		
		if unit.is2x2():
			for area_cell in cell.get_cells_in_area():
				assert(area_cell.unit == unit)
				
				area_cell.unit = null
		else:
			cell.unit = null
		
		print("Setting cell of unit %s to null" % unit.name)
	else:
		$DeathAnimationTimer.stop()
		
		call_deferred("emit_signal", "finished_checking_for_dead_units")


func _add_dead_units_to_queue(units: Array, queue: Array) -> void:
	for unit in units:
		if unit.is_dead() and not (unit in units_removed_from_play):
			queue.push_back(unit)


func start_heal_phase() -> void:
	_execute_next_skill(heal_skills, "heal_phase_finished")


func start_status_effect_phase() -> void:
	emit_signal("pincer_executed")


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
