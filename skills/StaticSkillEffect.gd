extends SkillEffect


# Frame at which the skill is activated
export(int) var activation_frame: int = 0
export(PackedScene) var animation_packed_scene: PackedScene

var target_count: int = 0
var targets_affected: int = 0
var absorbed_damage: int = 0


func _ready() -> void:
	$AnimatedSprite.hide()
	$AnimatedSprite.stop()


func execute(unit: Unit, skill: Skill, target_cells: Array) -> void:
	target_count = target_cells.size()
	targets_affected = 0
	absorbed_damage = 0
	
	if target_count == 0:
		emit_signal("effect_finished")
		
		return
	
	for cell in target_cells:
		var animated_sprite: AnimatedSprite = animation_packed_scene.instance()
		
		add_child(animated_sprite)
		animated_sprite.position = cell.position
		
		animated_sprite.connect("frame_changed", self,
				"_on_AnimatedSprite_frame_changed",
				[animated_sprite, unit, skill, cell.unit])
		
		animated_sprite.connect("animation_finished", self,
				"_on_AnimatedSprite_animation_finished",
				[],
				CONNECT_ONESHOT)
		
		animated_sprite.play()


func _on_AnimatedSprite_frame_changed(animated_sprite: AnimatedSprite, unit: Unit, skill: Skill, target_unit: Unit) -> void:
	if animated_sprite.frame == activation_frame and target_unit != null:
		target_unit.apply_skill(unit, skill)
	


func _on_AnimatedSprite_animation_finished() -> void:
	targets_affected += 1
	
	if targets_affected >= target_count:
		if absorbed_damage > 0:
			# TODO: play absorb animation
			pass
		
		emit_signal("effect_finished")
		hide()
		queue_free()
