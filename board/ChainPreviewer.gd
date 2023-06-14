extends Node2D

export(PackedScene) var chain_preview_line_2d_packed_scene: PackedScene


func update_preview(unit: Unit, cell: Cell) -> void:
	clear()
	
	if unit.faction != Unit.PLAYER_FACTION:
		return
	
	# Could be a dictionary, but it's not too important
	var last_cells_with_ally_for_each_direction: Array = []
	
	# This code is similar to find_chains() in Pincerer
	for direction in Cell.DIRECTION.values():
		var neighbor: Cell = cell.get_neighbor(direction)
		
		var last_cell_with_ally: Cell = null
		
		while neighbor != null:
			if neighbor.unit != null:
				if neighbor.unit.is_ally(unit.faction):
					last_cell_with_ally = neighbor
				else:
					break
			
			neighbor = neighbor.get_neighbor(direction)
		
		if last_cell_with_ally != null:
			last_cells_with_ally_for_each_direction.push_back(last_cell_with_ally)
	
	for last_cell in last_cells_with_ally_for_each_direction:
		var chain_preview_line_2d: Line2D = chain_preview_line_2d_packed_scene.instance()
		
		chain_preview_line_2d.add_point(cell.position)
		chain_preview_line_2d.add_point(last_cell.position)
		
		add_child(chain_preview_line_2d)


func clear() -> void:
	for child in get_children():
		child.queue_free()
