extends Node


class SkillAttack extends Reference:
	var unit: Unit
	
	var skill: Skill


var unit_queue := []

var buff_skills := []
var attack_skills := []
var heal_skills := []

var random: RandomNumberGenerator = RandomNumberGenerator.new()

var active_pincer: Pincerer.Pincer = null

# To calculate areas
var grid: Grid

# Finished executing a pincer
signal pincer_executed


func execute_pincer(pincer: Pincerer.Pincer, _grid: Grid) -> void:
	active_pincer = pincer
	grid = _grid
	
	unit_queue = _queue_units(pincer)
	
	$SkillActivationTimer.start()
	
	_activate_skill()


func _activate_skill() -> void:
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
			for unit in chain:
				units.push_back(unit)
	
	return units


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
		# Find its targets
		# Calculate the damage for each ?
		# Instance its effect scene
		# Connect to a signal that tells you when the animation is finished
		# And in that signal call this method again
		
		emit_signal("pincer_executed")
	else:
		print("no skills activated")
		
		emit_signal("pincer_executed")


func _execute_skill(skill_queue: Array) -> void:
	pass


func _on_SkillActivationTimer_timeout() -> void:
	_activate_skill()
