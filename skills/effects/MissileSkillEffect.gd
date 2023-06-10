extends SkillEffect

export(PackedScene) var particle_arc_scene: PackedScene
export(PackedScene) var hit_effect_packed_scene: PackedScene


func _start(unit: Unit, skill: Skill, target_cells: Array) -> void:
	for cell in target_cells:
		if cell.unit == unit:
			_on_ParticleArc_target_reached(unit, skill, cell)
		else:
			var particle_arc: Node2D = particle_arc_scene.instance()
			
			unit.add_child(particle_arc)
			
			var _error = particle_arc.connect("target_reached", self,
							"_on_ParticleArc_target_reached",
							[unit, skill, cell])
			
			particle_arc.play(cell.position, unit.position)


func _on_ParticleArc_target_reached(unit: Unit, skill: Skill, cell: Cell) -> void:
	var hit_effect: Node2D = hit_effect_packed_scene.instance()
	
	# Hit effect has to free automatically
	cell.add_child(hit_effect)
	
	hit_effect.play()
	
	_apply_skill(unit, skill, cell.unit)
	
	_update_count(unit)

	# TODO: when target is reached, if healing, instance heal particles / instance the next effect on arrival
	# and free it when it's done
