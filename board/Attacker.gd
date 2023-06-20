extends Node2D

class_name Attacker

export(PackedScene) var attack_effect_packed_scene: PackedScene = null

onready var timer: Timer = $Timer

# Array<Attack>
var attack_queue: Array = []
var random := RandomNumberGenerator.new()

signal attack_phase_finished


func _ready() -> void:
	random.randomize()


func start(attacks: Array) -> void:
	attack_queue = attacks
	
	_filter_attacks(attacks)
	
	_execute_next_attack()
	
	timer.start()


func _filter_attacks(attacks: Array) -> void:
	for attack in attacks:
		var filtered_targeted_units: Array = []
		
		for targeted_unit in attack.targeted_units:
			if not targeted_unit.is_dead():
				filtered_targeted_units.push_back(targeted_unit)
		
		attack.targeted_units = filtered_targeted_units


func _execute_next_attack() -> void:
	var attack = attack_queue.pop_front()
	
	if attack != null:
		_execute_attack(attack)
	else:
		timer.stop()
		
		emit_signal("attack_phase_finished")


func _execute_attack(attack: Attack) -> void:
	_play_sound(attack.pincering_unit.get_stats().weapon_type)
	
	for targeted_unit in attack.targeted_units:
		var damage: int = targeted_unit.calculate_attack_damage(attack.attacking_unit.get_stats(), attack.pincering_unit.get_stats()) * random.randf_range(0.9, 1.1)
		
		var attack_effect: Node2D = attack_effect_packed_scene.instance()
		add_child(attack_effect)
		
		attack_effect.position = targeted_unit.position
		
		targeted_unit.inflict_damage(damage)


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
