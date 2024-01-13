extends StackBasedMenuScreen


export(PackedScene) var skill_label_container_packed_scene: PackedScene


onready var full_name_label := $MarginContainer/VBoxContainer/FullNameLabel
onready var title_label := $MarginContainer/VBoxContainer/TitleLabel

onready var full_portrait_texture_rect := $MarginContainer/VBoxContainer/HBoxContainer/UnitFullTextureRect

onready var species_label := $MarginContainer/VBoxContainer/HBoxContainer/VBoxContainer/SpeciesLabel

onready var unit_icon := $MarginContainer/VBoxContainer/HBoxContainer/VBoxContainer/HBoxContainer/UnitIcon

onready var unit_stats_container := $MarginContainer/VBoxContainer/HBoxContainer/VBoxContainer/UnitStatsContainer

onready var skills_vbox_container := $MarginContainer/VBoxContainer/MarginContainer/MarginContainer/ScrollContainer/SkillsVBoxContainer

# TODO:
# onready var status_effects_vbox_container := $...


# TODO: If an enemy, don't show the activation rate
func initialize(job: Job, level: int, is_in_battle: bool = false, var can_show_activation_rate: bool = true) -> void:
	for child in skills_vbox_container.get_children():
		child.queue_free()
	
	full_name_label.text = job.job_name
	
	full_portrait_texture_rect.texture = job.full_portrait
	
	unit_icon.initialize(job)
	
	var can_show_remaining_health: bool = is_in_battle
	
	# Don't compare with other job
	unit_stats_container.initialize(job, null, can_show_remaining_health)
	
	var unlocked_skills: Array = job.get_unlocked_skills(level)
	
	for skill in job.skills:
		var skill_label_container: HBoxContainer = skill_label_container_packed_scene.instance()
		
		var is_skill_locked = not skill in unlocked_skills
		
		skill_label_container.initialize(skill, true, is_skill_locked, can_show_activation_rate)
		
		skills_vbox_container.add_child(skill_label_container)
	
	# TODO: If in battle, show status effects?


func on_add_to_tree(data: Object) -> void:
	var job_reference: JobReference = data as JobReference
	
	initialize(job_reference.job, job_reference.level)


func _on_ReturnButton_pressed() -> void:
	go_back()
