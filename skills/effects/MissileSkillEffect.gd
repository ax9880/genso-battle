extends SkillEffect

export(PackedScene) var particle_arc_scene: PackedScene
export(PackedScene) var hit_effect_packed_scene: PackedScene


func _start(unit: Unit, skill: Skill, target_cells: Array) -> void:
	for target_cell in target_cells:
		if target_cell.unit == unit:
			_on_ParticleArc_target_reached(unit, skill, target_cell)
		else:
			var particle_arc: Node2D = particle_arc_scene.instance()
			
			unit.add_child(particle_arc)
			
			var _error = particle_arc.connect("target_reached", self,
							"_on_ParticleArc_target_reached",
							[unit, skill, target_cell])
			
			particle_arc.play(target_cell.position, unit.position)


func _on_ParticleArc_target_reached(unit: Unit, skill: Skill, target_cell: Cell) -> void:
	var hit_effect: Node2D = hit_effect_packed_scene.instance()
	
	# Hit effect has to free automatically
	target_cell.add_child(hit_effect)
	
	hit_effect.play()
	
	_apply_skill(unit, skill, target_cell)
	
	_update_count(unit)

	# TODO: when target is reached, if healing, instance heal particles / instance the next effect on arrival
	# and free it when it's done
