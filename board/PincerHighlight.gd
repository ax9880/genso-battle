extends Node2D

export(Color) var player_color: Color
export(Color) var enemy_color: Color


func initialize(pincer: Pincerer.Pincer) -> void:
	for children in $Highlight.get_children():
		children.hide()
	
	var sprite: Sprite
	
	if(pincer.pincer_orientation == Enums.PincerOrientation.HORIZONTAL || pincer.pincer_orientation == Enums.PincerOrientation.VERTICAL):
		sprite = _get_sprite_based_on_size(pincer.size())
		
		var start_position: Vector2 = pincer.pincering_units.front().position
		var end_position: Vector2 = pincer.pincering_units.back().position
		
		position = (start_position + end_position) / 2.0
		
		if pincer.pincer_orientation == Enums.PincerOrientation.VERTICAL:
			$Highlight.rotation_degrees = 90
	else:
		sprite = _get_corner_sprite(pincer.pincer_orientation)
		
		position = _get_corner_position(pincer)
	
	$Highlight.hide()
	sprite.show()
	
	if pincer.pincering_units.front().is_player():
		sprite.modulate = player_color
	else:
		sprite.modulate = enemy_color
	
	$AnimationPlayer.play("Fade in and out")
	
	# Freed automatically when animation finishes


func _get_sprite_based_on_size(pincer_size: int) -> Node:
	match(pincer_size):
		3:
			return $Highlight/PincerHighlight3Units
		4:
			return $Highlight/PincerHighlight4Units
		5:
			return $Highlight/PincerHighlight5Units
		6:
			return $Highlight/PincerHighlight6Units
		7:
			return $Highlight/PincerHighlight7Units
		8:
			return $Highlight/PincerHighlight8Units
		_:
			printerr("Unsupported pincer size %d" % pincer_size)
			
			return $Highlight/PincerHighlight3Units


func _get_corner_sprite(pincer_orientation: int) -> Node:
	match(pincer_orientation):
		Enums.PincerOrientation.BOTTOM_LEFT_CORNER:
			return $Highlight/PincerHighlightBottomLeftCorner
		Enums.PincerOrientation.BOTTOM_RIGHT_CORNER:
			return $Highlight/PincerHighlightBottomRightCorner
		Enums.PincerOrientation.TOP_LEFT_CORNER:
			return $Highlight/PincerHighlightTopLeftCorner
		Enums.PincerOrientation.TOP_RIGHT_CORNER:
			return $Highlight/PincerHighlightTopRightCorner
		_:
			return $Highlight/PincerHighlightBottomLeftCorner


func _get_corner_position(pincer: Pincerer.Pincer) -> Vector2:
	var start_position: Vector2 = pincer.pincering_units.front().position
	var end_position: Vector2 = pincer.pincering_units.back().position
	
	match(pincer.pincer_orientation):
		Enums.PincerOrientation.BOTTOM_LEFT_CORNER:
			return Vector2(min(start_position.x, end_position.x), max(start_position.y, end_position.y))
		Enums.PincerOrientation.BOTTOM_RIGHT_CORNER:
			return Vector2(max(start_position.x, end_position.x), max(start_position.y, end_position.y))
		Enums.PincerOrientation.TOP_LEFT_CORNER:
			return Vector2(min(start_position.x, end_position.x), min(start_position.y, end_position.y))
		Enums.PincerOrientation.TOP_RIGHT_CORNER:
			return Vector2(max(start_position.x, end_position.x), min(start_position.y, end_position.y))
		_:
			return Vector2.ZERO

