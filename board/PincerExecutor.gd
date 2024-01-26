extends Node2D


class SkillAttack extends Reference:
	var unit: Unit
	
	var skill: Skill


export(PackedScene) var chain_previewer_packed_scene: PackedScene

export(PackedScene) var pincer_highlight_packed_scene: PackedScene


var _unit_queue := []
var _dead_units := []

var _buff_skills := []
var _attack_skills := []
var _heal_skills := []

var _active_pincer: Pincerer.Pincer = null

# Array<Array<Unit>> which include the pincering unit and the chained units
var _complete_chains := []

# Array<Unit>
var _allies := []

# Array<Unit>
var _enemies := []

var _units_removed_from_play := []

# To calculate areas of effect
var _grid: Grid
var _current_z_index: int = 1

var pusher: Pusher = null

# Array<ChainPreviewer>
var _chain_previews := []

# The names of these signals are passed as parameters and emitted inside functions
signal pincer_highlighted
signal skill_activation_phase_finished
signal attack_skill_phase_finished
signal heal_phase_finished
signal status_effect_phase_finished
signal finished_checking_for_dead_units

# Finished executing a pincer
signal pincer_executed


func initialize(grid: Grid, allies: Array, enemies: Array) -> void:
	_grid = grid
	_allies = allies
	_enemies = enemies


func start_skill_activation_phase(pincer: Pincerer.Pincer, grid: Grid, allies: Array = [], enemies: Array = []) -> void:
	_active_pincer = pincer
	
	initialize(grid, allies, enemies)
	
	_unit_queue = _queue_units(pincer)
	_complete_chains = _build_chains_including_pincering_unit(pincer)
	
	$SkillActivationTimer.start()
	
	_current_z_index = 2
	
	_activate_next_skill()


func _activate_next_skill() -> void:
	var unit: Unit = _unit_queue.pop_front()
	
	if unit != null:
		var activated_skills: Array = unit.activate_skills()
		
		if activated_skills.empty():
			# If no skills are activated then go to the next unit right away
			# I don't like the recursion but it makes it easier
			_activate_next_skill()
		else:
			_queue_skills(unit, activated_skills)
			
			unit.play_skill_activation_animation(activated_skills, _current_z_index)
			
			unit.play_scale_up_and_down_animation()
		
		_current_z_index += 1
	else:
		$SkillActivationTimer.stop()
		
		if not (_attack_skills.empty() and _heal_skills.empty()):
			$BeforeSkillActivationPhaseFinishesTimer.start()
			
			yield($BeforeSkillActivationPhaseFinishesTimer, "timeout")
		else:
			$NoSkillsActivatedTimer.start()
			
			yield($NoSkillsActivatedTimer, "timeout")
		
		_emit_deferred("skill_activation_phase_finished")


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
				_attack_skills.push_back(skill_attack)
			Enums.SkillType.HEAL, Enums.SkillType.CURE_AILMENT:
				_heal_skills.push_back(skill_attack)
			_:
				printerr("Unrecognized skill type: ", skill.skill_type)


func _show_chain_previews(pincer: Pincerer.Pincer) -> void:
	clear_chain_previews()
	
	for unit in pincer.pincering_units:
		var chain_previewer = chain_previewer_packed_scene.instance()
		
		add_child(chain_previewer)
		_chain_previews.push_back(chain_previewer)
		
		chain_previewer.update_preview(unit, _grid.get_cell_from_position(unit.position))
		chain_previewer.z_index = -1


func clear_chain_previews() -> void:
	for chain_previewer in _chain_previews:
		chain_previewer.queue_free()
	
	_chain_previews.clear()


func highlight_pincer(pincer: Pincerer.Pincer) -> void:
	var pincer_higlight: Node2D = pincer_highlight_packed_scene.instance()
	
	add_child(pincer_higlight)
	
	pincer_higlight.initialize(pincer)
	
	_show_chain_previews(pincer)
	
	yield(pincer_higlight, "pincer_highlighted")
	
	emit_signal("pincer_highlighted")


func start_attack_skill_phase() -> void:
	_execute_next_skill(_attack_skills, "attack_skill_phase_finished")


func _execute_next_skill(skill_queue: Array, finish_signal: String) -> void:
	var next_skill: SkillAttack = skill_queue.pop_front()
	
	if next_skill != null:
		var chain: Array = _find_chain(next_skill.unit, _complete_chains)
		
		assert(!chain.empty())
		
		# Array<Cell>
		var target_cells: Array = BoardUtils.find_area_of_effect_target_cells(next_skill.unit,
			next_skill.unit.position,
			next_skill.skill,
			_grid,
			_active_pincer.pincered_units,
			chain,
			_allies,
			_enemies)
		
		var skill_effect: Node2D = next_skill.skill.effect_scene.instance()
		
		add_child(skill_effect)
		
		var _error = skill_effect.connect("effect_finished", self, "_on_SkillEffect_effect_finished", [skill_queue, finish_signal])
		
		var start_cell: Cell = _grid.get_cell_from_position(next_skill.unit.position)
		
		skill_effect.start(next_skill.unit, next_skill.skill, target_cells, start_cell, pusher)
		
		next_skill.unit.stop_scale_and_and_down_animation()
	else:
		_emit_deferred(finish_signal)


# Find the chain a unit belongs to.
# Return Array<Unit>
func _find_chain(unit: Unit, chains: Array) -> Array:
	for chain in chains:
		if chain.find(unit) != -1:
			return chain
	
	printerr("Unit %s does not belong to a chain" % unit.name)
	
	return []


func check_dead_units() -> void:
	_dead_units.clear()
	
	_add_dead_units_to_queue(_allies, _dead_units)
	_add_dead_units_to_queue(_enemies, _dead_units)
	
	_check_next_dead_unit()
	
	$DeathAnimationTimer.start()


func update_dead_unit_on_swap(unit: Unit, cell_to_swap_to: Cell) -> void:
	assert(not unit.is2x2())
	
	if not unit.is_death_animation_playing():
		var _error = unit.connect("death_animation_finished", self, "_on_Unit_death_animation_finished")
		
		unit.call_deferred("play_death_animation")
		
		assert(cell_to_swap_to.unit == unit)
		
		cell_to_swap_to.unit = null


func _check_next_dead_unit() -> void:
	var unit: Unit = _dead_units.pop_front()
	
	if unit != null and not unit.is_death_animation_playing():
		if unit.connect("death_animation_finished", self, "_on_Unit_death_animation_finished") != OK:
			push_warning("Trying to connect death animation finished signal again to unit %s" % unit.name)
			
			return
		
		unit.play_death_animation()
		
		var cell: Cell = _grid.get_cell_from_position(unit.position)
		
		if cell.unit != null:
			assert(cell.unit == unit)
		else:
			printerr("Unit %s died but cell unit is null" % unit.name)
			
			_clean_up_all_cells(unit)
		
		# If 2x2, check neighbor cells
		if unit.is2x2():
			for area_cell in cell.get_cells_in_area():
				if area_cell.unit != unit:
					printerr("2x2 unit not in area cells")
					
					_clean_up_all_cells(unit)
				
				area_cell.unit = null
		else:
			cell.unit = null
		
		print("Setting cell of unit %s to null" % unit.name)
	else:
		$DeathAnimationTimer.stop()
		
		_emit_deferred("finished_checking_for_dead_units")


func _add_dead_units_to_queue(units: Array, queue: Array) -> void:
	for unit in units:
		if unit.is_dead() and not (unit in _units_removed_from_play):
			queue.push_back(unit)


func _emit_deferred(signal_name: String) -> void:
	call_deferred("emit_signal", signal_name)


func start_heal_phase() -> void:
	_execute_next_skill(_heal_skills, "heal_phase_finished")


func start_status_effect_phase() -> void:
	var status_effects: Array = Enums.StatusEffectType.values()
	
	for status_effect_type in status_effects:
		var enemies_with_status_effect := get_units_with_status_effect(_enemies, status_effect_type)
		
		if not enemies_with_status_effect.empty():
			for enemy in _enemies:
				enemy.inflict(status_effect_type)
			
			_play_status_effect_sound(status_effect_type)
			
			if _status_effect_has_delay(status_effect_type):
				$StatusEffectTimer.start()
				
				yield($StatusEffectTimer, "timeout")
		
		var player_units_status_effect := get_units_with_status_effect(_allies, status_effect_type)
		
		if not player_units_status_effect.empty():
			for unit in player_units_status_effect:
				unit.inflict(status_effect_type)
			
			_play_status_effect_sound(status_effect_type)
			
			if _status_effect_has_delay(status_effect_type):
				$StatusEffectTimer.start()
				
				yield($StatusEffectTimer, "timeout")
	
	_emit_deferred("status_effect_phase_finished")


func get_units_with_status_effect(target_units: Array, status_effect_type: int) -> Array:
	var units_with_status_effect: Array = []
	
	for unit in target_units:
		if unit.is_alive() and unit.has_status_effect_of_type(status_effect_type):
			units_with_status_effect.append(unit)
	
	return units_with_status_effect


func _status_effect_has_delay(status_effect_type: int) -> bool:
	return status_effect_type == Enums.StatusEffectType.POISON or \
		status_effect_type == Enums.StatusEffectType.REGENERATE


func _play_status_effect_sound(status_effect_type: int) -> void:
	if status_effect_type == Enums.StatusEffectType.POISON:
		$PoisonAudio.play()
	elif status_effect_type == Enums.StatusEffectType.REGENERATE:
		$RegenerateAudio.play()


# Sets all cells with the given unit to null
# Used only in error cases when a unit dies but there is a mismatch with
# its current cell
func _clean_up_all_cells(unit: Unit) -> void:
	for cell in _grid.get_all_cells():
		if cell.unit == unit:
			cell.unit = null


func _on_SkillEffect_effect_finished(skill_queue: Array, finish_signal: String) -> void:
	_execute_next_skill(skill_queue, finish_signal)


func _on_SkillActivationTimer_timeout() -> void:
	_activate_next_skill()


func _on_DeathAnimationTimer_timeout() -> void:
	_check_next_dead_unit()


func _on_Unit_death_animation_finished(unit: Unit) -> void:
	unit.get_parent().remove_child(unit)
	
	_units_removed_from_play.push_back(unit)


func _on_PincerExecutor_tree_exiting() -> void:
	for unit in _units_removed_from_play:
		unit.free()
