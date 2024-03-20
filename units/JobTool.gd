tool
extends Node

export(NodePath) var unit_node_path: NodePath

export(NodePath) var sprite_node_path: NodePath
export(NodePath) var job_node_path: NodePath

export(NodePath) var weapon_type_node_path: NodePath
export(NodePath) var turn_count_node_path: NodePath

export(NodePath) var unit_name_node_path: NodePath


func _ready() -> void:
	if Engine.editor_hint:
		var job_node = get_node(job_node_path)
		var job: Job = job_node.job
		
		var sprite: Sprite = get_node(sprite_node_path)
		sprite.texture = job.portrait
		
		var unit: Unit = get_node(unit_node_path)
		var turn_count_label: Label = get_node(turn_count_node_path)
		turn_count_label.text = str(unit.turn_counter)
		
		var weapon_type_icon: TextureRect = get_node(weapon_type_node_path)
		weapon_type_icon.texture = load(Enums.WEAPON_TYPE_TEXTURES[job.stats.weapon_type])
		
		var unit_name_label: Label = get_node(unit_name_node_path)
		unit_name_label.text = str(job.job_name)
