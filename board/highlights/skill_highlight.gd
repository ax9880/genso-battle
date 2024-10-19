extends Node2D


export(PackedScene) var cell_highlight_packed_scene: PackedScene


# Array<Cell>
func show_highlight(target_cells: Array, color: Color) -> void:
	$AnimationPlayer.play("Fade in")
	
	for cell in target_cells:
		var cell_highlight: Node2D = cell_highlight_packed_scene.instance()
		
		add_child(cell_highlight)
		
		cell_highlight.position = cell.position
		cell_highlight.modulate = color


func stop() -> void:
	$AnimationPlayer.play("Fade out and free")
