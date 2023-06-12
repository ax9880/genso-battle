extends SkillEffect

# Frame at which the skill is activated
export(int) var activation_frame: int = 0
export(PackedScene) var animation_packed_scene: PackedScene


func _ready() -> void:
	$AnimatedSprite.hide()
	$AnimatedSprite.stop()


func _start(unit: Unit, skill: Skill, target_cells: Array) -> void:
	for cell in target_cells:
		var animated_sprite: AnimatedSprite = animation_packed_scene.instance()
		
		add_child(animated_sprite)
		animated_sprite.position = cell.position
		
		if activation_frame > 0:
			var _error = animated_sprite.connect("frame_changed", self,
							"_on_AnimatedSprite_frame_changed",
							[animated_sprite, unit, skill, cell.unit])
		else:
			_apply_skill(unit, skill, cell.unit)
		
		var _error = animated_sprite.connect("animation_finished", self,
						"_on_AnimatedSprite_animation_finished",
						[unit],
						CONNECT_ONESHOT)
		
		animated_sprite.play()


func _on_AnimatedSprite_frame_changed(animated_sprite: AnimatedSprite, unit: Unit, skill: Skill, target_unit: Unit) -> void:
	if animated_sprite.frame == activation_frame:
		_apply_skill(unit, skill, target_unit)


func _on_AnimatedSprite_animation_finished(unit: Unit) -> void:
	_update_count(unit)
