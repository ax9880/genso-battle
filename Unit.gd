extends KinematicBody2D

class_name Unit


enum STATE {
	# Idle
	IDLE = 0,
	
	# Picked up, being dragged by the player
	PICKED_UP = 1,
	
	SNAPPING_TO_GRID = 2
}

## Exports

export var velocity_pixels_per_second: float = 10.0
export var snap_velocity_pixels_per_second: float = 200.0
export var swap_velocity_pixels_per_second: float = 500.0

# Max velocity when dragging the unit. It can't be too fast or the unit
# will tunnel through cells and other units.
export var max_velocity_pixels_per_second: float = 2048.0 # 2048

# Proportional control constant
export var kp: float = 1.4

## Vars

var current_state = STATE.IDLE setget set_current_state

## Onready

onready var tween := $Tween
onready var sprite := $Sprite

## Signals

signal picked_up(unit, unit_position)
signal released(unit)
signal snapped_to_grid()


func _ready() -> void:
	self.current_state = STATE.IDLE


func _physics_process(_delta: float) -> void:
	match(current_state):
		STATE.IDLE:
			pass
		STATE.PICKED_UP:
			_move_towards_mouse()


func move_to_new_cell(target_position: Vector2) -> void:
	tween.remove(self, ":position")
	
	var tween_time_seconds: float = Utils.calculate_time(position, target_position, swap_velocity_pixels_per_second)
	
	tween.interpolate_property(self, "position",
				position, target_position,
				tween_time_seconds,
				Tween.TRANS_SINE)
			
	tween.start()


func enable_swap_area() -> void:
	Utils.enable_object($SwapArea2D/CollisionShape2D)


func disable_swap_area() -> void:
	Utils.disable_object($SwapArea2D/CollisionShape2D)


func enable_selection_area() -> void:
	Utils.enable_object($SelectionArea2D/CollisionShape2D)


func disable_selection_area() -> void:
	Utils.disable_object($SelectionArea2D/CollisionShape2D)


func _move_towards_mouse() -> void:
	var error: Vector2 = get_global_mouse_position() - global_position
	
	var velocity = Vector2(error * kp * velocity_pixels_per_second).limit_length(max_velocity_pixels_per_second)
	
	var _velocity = move_and_slide(velocity, Vector2.ZERO)


func _input(event: InputEvent):
	if event.is_action_released("ui_select"):
		_release()


func snap_to_grid(cell_origin: Vector2) -> void:
	self.current_state = STATE.SNAPPING_TO_GRID
	
	# Tween to position at fixed speed
	var tween_time_seconds: float = Utils.calculate_time(position, cell_origin, snap_velocity_pixels_per_second)
	
	tween.interpolate_property(self, "position",
		position, cell_origin,
		tween_time_seconds,
		Tween.TRANS_SINE)
	
	tween.start()


func is_snapping() -> bool:
	return current_state == STATE.SNAPPING_TO_GRID


func _pick_up() -> void:
	if current_state == STATE.IDLE:
		self.current_state = STATE.PICKED_UP


func _release() -> void:
	if current_state == STATE.PICKED_UP:
		self.current_state = STATE.IDLE
		
		emit_signal("released", self)


## Setters

# Setter function for current_state.
func set_current_state(new_state) -> void:
	current_state = new_state
	
	match(new_state):
		STATE.IDLE:
			disable_swap_area()
			
			# TODO: snap to grid ?
			set_physics_process(false)
			
			tween.remove(sprite, ":scale")
			
			tween.interpolate_property(sprite, "scale",
				sprite.scale, Vector2.ONE, # TODO: Save original sprite scale
				0.25,
				Tween.TRANS_SINE)
			
			tween.start()
		STATE.PICKED_UP:
			enable_swap_area()
			
			emit_signal("picked_up", self, position)
			
			set_physics_process(true)
			
			tween.remove(sprite, ":scale")
			
			tween.interpolate_property(sprite, "scale",
				sprite.scale, Vector2(1.1, 1.1),
				0.25,
				Tween.TRANS_SINE)
			
			tween.start()
		STATE.SNAPPING_TO_GRID:
			disable_swap_area()


## Signals

func _on_SelectionArea2D_input_event(_viewport: Node, event: InputEvent, _shape_idx: int):
	if event is InputEventMouseButton:
		if event.pressed:
			_pick_up()


func _on_Tween_tween_completed(_object: Object, key: String):
	if current_state == STATE.SNAPPING_TO_GRID:
		if key == ":position":
			self.current_state = STATE.IDLE
			
			emit_signal("snapped_to_grid")
