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


# TODO: Initialize with a Unit object? That way you get all the data you need
func initialize(job_reference: JobReference) -> void:
	for child in skills_vbox_container.get_children():
		child.queue_free()
	
	var job: Job = job_reference.job
	
	full_name_label.text = job.job_name
	
	full_portrait_texture_rect.texture = job.full_portrait
	
	unit_icon.initialize(job)
	
	# No compare job_reference, don't show remaining health
	unit_stats_container.initialize(job, null)
	
	# TODO: Use level in JobReference to know which skills are unlocked
	for s in job.skills:
		var skill: Skill = s
		
		var skill_label_container: HBoxContainer = skill_label_container_packed_scene.instance()
		
		# TODO: If an enemy, don't show the activation rate
		skill_label_container.initialize(skill, true)
		
		skills_vbox_container.add_child(skill_label_container)


func on_add_to_tree(data: Object) -> void:
	var job_reference: JobReference = data as JobReference
	
	initialize(job_reference)


func _on_ReturnButton_pressed() -> void:
	go_back()
