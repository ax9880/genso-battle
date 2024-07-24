extends MarginContainer


export(PackedScene) var activated_skill_hbox_container_packed_scene: PackedScene

onready var vbox_container := $MarginContainer/VBoxContainer


func play(activated_skills: Array) -> void:
	for child in vbox_container.get_children():
		child.queue_free()
	
	if not activated_skills.empty():
		for skill in activated_skills:
			print("Activated skill %s " % skill.skill_name)
			
			var activated_skill_hbox_container: HBoxContainer = activated_skill_hbox_container_packed_scene.instance()
			
			activated_skill_hbox_container.initialize(skill)
			
			vbox_container.add_child(activated_skill_hbox_container)
		
		# Yields one frame so the container updates before setting the growth
		# position
		yield(get_tree(), "idle_frame")
		
		_set_growth_position()
		
		$AnimationPlayer.play("Fade in and then out")


func _set_growth_position() -> void:
	reset_growth_direction()
	
	var screen_center: Vector2 = get_viewport_rect().size / 2.0
	
	var position_in_viewport: Vector2 = get_global_transform_with_canvas().origin
	
	var position_relative_to_center: Vector2 = screen_center - position_in_viewport
	
	if position_relative_to_center.x < 0:
		grow_horizontal = Control.GROW_DIRECTION_BEGIN
	else:
		grow_horizontal = Control.GROW_DIRECTION_END
	
	if position_relative_to_center.y < 0:
		grow_vertical = Control.GROW_DIRECTION_BEGIN


func reset_growth_direction() -> void:
	grow_horizontal = Control.GROW_DIRECTION_BOTH
	grow_vertical = Control.GROW_DIRECTION_END
