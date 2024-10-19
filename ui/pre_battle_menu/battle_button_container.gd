extends MarginContainer


signal pressed


func set_values(title: String, battle_info: BattleInfo) -> void:
	$HBoxContainer/AudioButton.text = tr(title)
	
	$HBoxContainer/VBoxContainer/HBoxContainer/SwordEnemyCountLabel.text = str(battle_info.sword_enemy_count)
	$HBoxContainer/VBoxContainer/HBoxContainer2/SpearEnemyCountLabel.text = str(battle_info.spear_enemy_count)
	$HBoxContainer/VBoxContainer2/HBoxContainer/GunEnemyCountLabel.text = str(battle_info.gun_enemy_count)
	$HBoxContainer/VBoxContainer2/HBoxContainer2/StaffEnemyCountLabel.text = str(battle_info.staff_enemy_count)
	
	$HBoxContainer/VBoxContainer3/BattleCountLabel.text = "%s: %d" % [tr("BATTLES"), battle_info.phases_count]


func _on_AudioButton_pressed() -> void:
	emit_signal("pressed")
