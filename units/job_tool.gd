tool
extends Node


export(NodePath) var _unit_node_path: NodePath

export(NodePath) var _sprite_node_path: NodePath
export(NodePath) var _job_node_path: NodePath

export(NodePath) var _weapon_type_node_path: NodePath
export(NodePath) var _turn_count_node_path: NodePath

export(NodePath) var _unit_name_node_path: NodePath


func _ready() -> void:
	if not Engine.editor_hint:
		return
	
	var job_node = get_node(_job_node_path)
	var job: Job = job_node.job
	
	var sprite: Sprite = get_node(_sprite_node_path)
	sprite.texture = job.portrait
	
	var unit: Unit = get_node(_unit_node_path)
	var turn_count_label: Label = get_node(_turn_count_node_path)
	turn_count_label.text = str(unit.turn_counter)
	
	var weapon_type_icon: TextureRect = get_node(_weapon_type_node_path)
	weapon_type_icon.texture = load(Enums.WEAPON_TYPE_TEXTURES[job.stats.weapon_type])
	
	var unit_name_label: Label = get_node(_unit_name_node_path)
	unit_name_label.text = str(job.job_name)
