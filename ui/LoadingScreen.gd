extends CanvasLayer

const FADE_IN_ANIMATION_NAME := "Fade in"
const FADE_OUT_ANIMATION_NAME := "Fade out"

onready var animation_player := $AnimationPlayer

signal fade_in_finished()
signal fade_out_finished()


func play_loading_animation() -> void:
	animation_player.play(FADE_IN_ANIMATION_NAME)


func fade_out() -> void:
	animation_player.play(FADE_OUT_ANIMATION_NAME)


func _on_AnimationPlayer_animation_finished(animation_name: String) -> void:
	match(animation_name):
		FADE_IN_ANIMATION_NAME:
			emit_signal("fade_in_finished")
			
		FADE_OUT_ANIMATION_NAME:
			emit_signal("fade_out_finished")
