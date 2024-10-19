extends VBoxContainer


export(Color) var advantage_color: Color
export(Color) var disadvantage_color: Color


onready var _health_number_label: Label = $HBoxContainer3/HealthNumber

onready var _attack_number_label: Label = $HBoxContainer/AttackNumber
onready var _defense_number_label: Label = $HBoxContainer/DefenseNumber
onready var _spiritual_attack_number_label: Label = $HBoxContainer2/SpiritualAttackNumber
onready var _spiritual_defense_number_label: Label = $HBoxContainer2/SpiritualDefenseNumber


func initialize(base_stats: Stats, compare_stats: Stats) -> void:
	# TODO: Add label translations
	
	if compare_stats != null:
		_show_compared_number(_health_number_label, base_stats.health, compare_stats.health)
		
		_show_compared_number(_attack_number_label, base_stats.attack, compare_stats.attack)
		_show_compared_number(_defense_number_label, base_stats.defense, compare_stats.defense)
		
		_show_compared_number(_spiritual_attack_number_label, base_stats.spiritual_attack, compare_stats.spiritual_attack)
		_show_compared_number(_spiritual_defense_number_label, base_stats.spiritual_defense, compare_stats.spiritual_defense)
	else:
		_show_number(_health_number_label, base_stats.health)
		
		_show_number(_attack_number_label, base_stats.attack)
		_show_number(_defense_number_label, base_stats.defense)
		
		_show_number(_spiritual_attack_number_label, base_stats.spiritual_attack)
		_show_number(_spiritual_defense_number_label, base_stats.spiritual_defense)


func initialize_in_battle(base_stats: Stats, current_stats: Stats) -> void:
	_show_remaining_health(base_stats, current_stats)
	
	_show_compared_number(_attack_number_label, current_stats.attack, base_stats.attack)
	_show_compared_number(_defense_number_label, current_stats.defense, base_stats.defense)
	
	_show_compared_number(_spiritual_attack_number_label, current_stats.spiritual_attack, base_stats.spiritual_attack)
	_show_compared_number(_spiritual_defense_number_label, current_stats.spiritual_defense, base_stats.spiritual_defense)


func _show_number(label: Label, job_stat: int) -> void:
	label.text = str(job_stat)


func _show_compared_number(label: Label, job_stat: int, compare_job_stat: int) -> void:
	var difference: int = job_stat - compare_job_stat
	
	if difference > 0:
		label.add_color_override("font_color", advantage_color)
		
		label.text = "%d (%+d)" % [job_stat, difference]
	elif difference < 0:
		label.add_color_override("font_color", disadvantage_color)
		
		label.text = "%d (%+d)" % [job_stat, difference]
	else:
		_show_number(label, job_stat)


func _show_remaining_health(base_stats: Stats, current_stats: Stats) -> void:
	_health_number_label.text = "%d/%d" % [current_stats.health, base_stats.health]
