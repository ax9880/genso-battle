extends Node2D

class_name Attacker

export(PackedScene) var attack_effect_packed_scene: PackedScene = null

onready var timer: Timer = $Timer

# Array<Attack>
var _attack_queue: Array = []
var _random := RandomNumberGenerator.new()

signal attack_phase_finished


func _ready() -> void:
	_random.randomize()


func start(pincer: Pincerer.Pincer) -> void:
	_attack_queue = _queue_attacks(pincer)
	
	_filter_attacks(_attack_queue)
	
	_execute_next_attack()
	
	timer.start()


func _queue_attacks(pincer: Pincerer.Pincer) -> Array:
	var attack_queue := []
	
	# Pincering unit followed by its chain
	for pincering_unit in pincer.pincering_units:
		_queue_attack(attack_queue, pincer.pincered_units, pincering_unit)
		
		# Only player pincers have chaining
		if pincering_unit.faction == Unit.PLAYER_FACTION:
			_queue_chain_attacks(attack_queue, pincer.chain_families[pincering_unit], pincer.pincered_units, pincering_unit)
	
	return attack_queue


func _queue_attack(queue: Array, targeted_units: Array, attacking_unit: Unit, pincering_unit: Unit = null) -> void:
	var attack: Attack = Attack.new()
	
	attack.targeted_units = targeted_units
	attack.attacking_unit = attacking_unit
	
	if pincering_unit == null:
		attack.pincering_unit = attacking_unit
	else:
		attack.pincering_unit = pincering_unit
	
	queue.push_back(attack)


func _queue_chain_attacks(queue: Array, chains: Array, targeted_units: Array, pincering_unit: Unit) -> void:
	for chain in chains:
		for unit in chain:
			_queue_attack(queue, targeted_units, unit, pincering_unit)


func _filter_attacks(attacks: Array) -> void:
	for attack in attacks:
		var filtered_targeted_units: Array = []
		
		for targeted_unit in attack.targeted_units:
			if not targeted_unit.is_dead():
				filtered_targeted_units.push_back(targeted_unit)
		
		attack.targeted_units = filtered_targeted_units


func _execute_next_attack() -> void:
	var attack = _attack_queue.pop_front()
	
	if attack != null:
		_execute_attack(attack)
	else:
		timer.stop()
		
		call_deferred("emit_signal", "attack_phase_finished")


func _execute_attack(attack: Attack) -> void:
	_play_sound(attack.pincering_unit.get_stats().weapon_type)
	
	for targeted_unit in attack.targeted_units:
		var damage: int = targeted_unit.calculate_attack_damage(attack.attacking_unit.get_stats(), attack.pincering_unit.get_stats()) * _random.randf_range(0.9, 1.1)
		
		var attack_effect: Node2D = attack_effect_packed_scene.instance()
		add_child(attack_effect)
		
		attack_effect.position = targeted_unit.get_offset_origin()
		
		targeted_unit.inflict_damage(damage)
		
		targeted_unit.on_attacked()


func _play_sound(weapon_type: int) -> void:
	var audio_stream_player: AudioStreamPlayer = _get_audio_stream_player(weapon_type)
	
	if audio_stream_player.playing:
		$BackupAudio.stream = audio_stream_player.stream
		$BackupAudio.volume_db = audio_stream_player.volume_db
		audio_stream_player = $BackupAudio
	
	audio_stream_player.play()


func _get_audio_stream_player(weapon_type: int) -> Node:
	match(weapon_type):
		Enums.WeaponType.SWORD:
			return $SwordAudio
		Enums.WeaponType.GUN:
			return $GunAudio
		Enums.WeaponType.SPEAR:
			return $SpearAudio
		_:
			return $StaffAudio


func _on_Timer_timeout() -> void:
	_execute_next_attack()
