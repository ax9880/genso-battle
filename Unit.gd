extends KinematicBody2D


enum STATE {
	# Idle
	IDLE = 0,
	
	# Picked up, being dragged by the player
	PICKED_UP = 1,
	
	SNAPPING_TO_GRID = 2
}

## Exports

export var velocity_pixels_per_second: float = 10.0
export var snap_velocity_pixels_per_second: float = 100.0

# Proportional control constant
export var kp: float = 1.4

## Vars

var current_state = STATE.IDLE setget set_current_state

## Onready

onready var tween := $Tween
onready var sprite := $Sprite

## Signals

signal picked_up(unit, unit_position)
signal released(unit, unit_position)


func _ready() -> void:
	self.current_state = STATE.IDLE


func _physics_process(_delta: float) -> void:
	match(current_state):
		STATE.IDLE:
			pass
		STATE.PICKED_UP:
			_move_towards_mouse()


func _move_towards_mouse() -> void:
	var error: Vector2 = get_global_mouse_position() - global_position
	
	var control: Vector2 = error * Vector2(kp, kp) * velocity_pixels_per_second
	
	var _velocity = move_and_slide(control, Vector2.ZERO)


func _input(event: InputEvent):
	if event.is_action_released("ui_select"):
		_release()


func snap_to_grid(cell_origin: Vector2) -> void:
	# Disable collision shape so it doesn't complain ?
	# tween to position at fixed speed
	# so calculate how long it will take you to get there and use that time for the tween
	#emit_signal("released", position)
	
	self.current_state = STATE.SNAPPING_TO_GRID
	
	var distance_pixels: float = position.distance_to(cell_origin)
	var snap_time_seconds: float = distance_pixels / snap_velocity_pixels_per_second
	
	tween.interpolate_property(self, "position",
		position, cell_origin,
		snap_time_seconds, # TODO: calculate time based on a fixed speed
		Tween.TRANS_SINE)
	
	tween.start()


func _pick_up() -> void:
	if current_state == STATE.IDLE:
		self.current_state = STATE.PICKED_UP


func _release() -> void:
	if current_state == STATE.PICKED_UP:
		self.current_state = STATE.IDLE
		
		emit_signal("released", self, position)


## Setters

# Setter function for current_state.
func set_current_state(new_state) -> void:
	match(new_state):
		STATE.IDLE:
			# TODO: snap to grid ?
			set_physics_process(false)
			
			tween.remove(sprite, ":scale")
			
			tween.interpolate_property(sprite, "scale",
				sprite.scale, Vector2.ONE, # TODO: Save original sprite scale
				0.25,
				Tween.TRANS_SINE)
			
			tween.start()
		STATE.PICKED_UP:
			emit_signal("picked_up", self, position)
			
			set_physics_process(true)
			
			tween.remove(sprite, ":scale")
			
			tween.interpolate_property(sprite, "scale",
				sprite.scale, Vector2(1.1, 1.1),
				0.25,
				Tween.TRANS_SINE)
			
			tween.start()
	
	current_state = new_state


## Signals

func _on_SelectionArea2D_input_event(_viewport: Node, event: InputEvent, _shape_idx: int):
	if event is InputEventMouseButton:
		if event.pressed:
			_pick_up()

func _on_Tween_tween_completed(_object: Object, key: String):
	if current_state == STATE.SNAPPING_TO_GRID:
		if key == ":position":
			self.current_state = STATE.IDLE
