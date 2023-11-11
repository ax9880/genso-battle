extends VBoxContainer


# TODO: Pass current stats OR show when a stat is buffed or debuffed...?
# If the stat is buffed, show it blue with an arrow pointing up next to it
# If the stat is debuffed, show it purple with an arrow pointing down 
# i.e. if current stat greater or less than base stat
func initialize(job: Job, compare_job: Job, can_show_remaining_health: bool = false, current_stats: StartingStats = null) -> void:
	# TODO: Add label translations
	
	if compare_job != null:
		_show_compared_number($HBoxContainer3/HealthNumber, job.stats.health, compare_job.stats.health)
		
		_show_compared_number($HBoxContainer/AttackNumber, job.stats.attack, compare_job.stats.attack)
		_show_compared_number($HBoxContainer/DefenseNumber, job.stats.defense, compare_job.stats.defense)
		
		_show_compared_number($HBoxContainer2/SpiritualAttackNumber, job.stats.spiritual_attack, compare_job.stats.spiritual_attack)
		_show_compared_number($HBoxContainer2/SpiritualDefenseNumber, job.stats.spiritual_defense, compare_job.stats.spiritual_defense)
	else:
		_show_number($HBoxContainer3/HealthNumber, job.stats.health)
		
		_show_number($HBoxContainer/AttackNumber, job.stats.attack)
		_show_number($HBoxContainer/DefenseNumber, job.stats.defense)
		
		_show_number($HBoxContainer2/SpiritualAttackNumber, job.stats.spiritual_attack)
		_show_number($HBoxContainer2/SpiritualDefenseNumber, job.stats.spiritual_defense)
	
	if can_show_remaining_health:
		_show_remaining_health(job.stats, current_stats)


func _show_number(label: Label, job_stat: int) -> void:
	label.text = str(job_stat)


func _show_compared_number(label: Label, job_stat: int, compare_job_stat: int) -> void:
	var difference: int = job_stat - compare_job_stat
	
	if difference > 0:
		label.add_color_override("font_color", Color("#9bd547"))
		
		label.text = "%d (%+d)" % [job_stat, difference]
	elif difference < 0:
		label.add_color_override("font_color", Color("#ff4f4f"))
		
		label.text = "%d (%+d)" % [job_stat, difference]
	else:
		_show_number(label, job_stat)


func _show_remaining_health(base_stats: StartingStats, current_stats: StartingStats) -> void:
	$HBoxContainer3/HealthNumber.text = "%d/%d" % [current_stats.health, base_stats.health]
