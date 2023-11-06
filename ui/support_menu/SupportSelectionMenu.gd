extends StackBasedMenuScreen


func _on_ReturnButton_pressed() -> void:
	change_scene("res://ui/pre_battle_menu/StackBasedPreBattleMenu.tscn")


func _on_YachieAndSakiButton_pressed() -> void:
	navigate("")


func _on_SakiAndYuumaButton_pressed() -> void:
	navigate("")


func _on_YuumaAndYachieButton_pressed() -> void:
	navigate("")
