extends SkillEffect

# TODO: Load this from the scene
export(PackedScene) var particle_arc_scene: PackedScene


func _start(unit: Unit, skill: Skill, target_cells: Array) -> void:
	for cell in target_cells:
		if cell.unit == unit:
			_on_ParticleArc_target_reached(unit, skill, cell.unit)
		else:
			var particle_arc: Node2D = particle_arc_scene.instance()
			
			unit.add_child(particle_arc)
			
			var _error = particle_arc.connect("target_reached", self,
							"_on_ParticleArc_target_reached",
							[unit, skill, cell.unit])
			
			particle_arc.play(cell.position, unit.position)


func _on_ParticleArc_target_reached(unit: Unit, skill: Skill, target_unit: Unit) -> void:
	_apply_skill(unit, skill, target_unit)
	
	_update_count(unit)
