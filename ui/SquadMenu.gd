extends Control


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	for job in GameData.save_data.jobs:
		print("job %s" % job.job_name)
		pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass


func _on_ReturnButton_pressed() -> void:
	var _error = get_tree().change_scene("res://ui/PreBattleMenu.tscn")
