extends VBoxContainer

onready var health_number_label: Label = $HBoxContainer3/HealthNumber

onready var attack_number_label: Label = $HBoxContainer/AttackNumber
onready var defense_number_label: Label = $HBoxContainer/DefenseNumber
onready var spiritual_attack_number_label: Label = $HBoxContainer2/SpiritualAttackNumber
onready var spiritual_defense_number_label: Label = $HBoxContainer2/SpiritualDefenseNumber


func initialize(base_stats: StartingStats, compare_stats: StartingStats, can_show_remaining_health: bool = false) -> void:
	# TODO: Add label translations
	
	if compare_stats != null:
		if not can_show_remaining_health:
			_show_compared_number(health_number_label, base_stats.health, compare_stats.health)
		
		_show_compared_number(attack_number_label, base_stats.attack, compare_stats.attack)
		_show_compared_number(defense_number_label, base_stats.defense, compare_stats.defense)
		
		_show_compared_number(spiritual_attack_number_label, base_stats.spiritual_attack, compare_stats.spiritual_attack)
		_show_compared_number(spiritual_defense_number_label, base_stats.spiritual_defense, compare_stats.spiritual_defense)
	else:
		_show_number(health_number_label, base_stats.health)
		
		_show_number(attack_number_label, base_stats.attack)
		_show_number(defense_number_label, base_stats.defense)
		
		_show_number(spiritual_attack_number_label, base_stats.spiritual_attack)
		_show_number(spiritual_defense_number_label, base_stats.spiritual_defense)
	
	if can_show_remaining_health and compare_stats != null:
		_show_remaining_health(base_stats, compare_stats)


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
	health_number_label.text = "%d/%d" % [current_stats.health, base_stats.health]
