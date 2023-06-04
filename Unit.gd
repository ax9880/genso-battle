extends KinematicBody2D

class_name Unit


enum STATE {
	# Idle
	IDLE = 0,
	
	# Picked up, being dragged by the player
	PICKED_UP = 1,
	
	SNAPPING_TO_GRID = 2
}

const INVALID_FACTION: int = -1
const PLAYER_FACTION: int = 1
const ENEMY_FACTION: int = 2

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

var faction: int = INVALID_FACTION

## Onready

onready var tween := $Tween
onready var sprite := $Sprite

## Signals

signal picked_up(unit)
signal released(unit)
signal snapped_to_grid(unit)


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
			
			set_physics_process(false)
			
			_restore_sprite_size()
		STATE.PICKED_UP:
			enable_swap_area()
			
			set_physics_process(true)
			
			emit_signal("picked_up", self)
			
			_increase_sprite_size()
		STATE.SNAPPING_TO_GRID:
			disable_swap_area()


func _increase_sprite_size() -> void:
	tween.remove(sprite, ":scale")
	
	tween.interpolate_property(sprite, "scale",
		sprite.scale, Vector2(1.2, 1.2),
		0.25,
		Tween.TRANS_SINE)
	
	tween.start()


func _restore_sprite_size() -> void:
	tween.remove(sprite, ":scale")
	
	tween.interpolate_property(sprite, "scale",
		sprite.scale, Vector2.ONE, # TODO: Save original sprite scale
		0.25,
		Tween.TRANS_SINE)
	
	tween.start()


func is_ally(unit_faction: int) -> bool:
	return (faction & unit_faction) != 0


func is_enemy(unit_faction: int) -> bool:
	return !is_ally(unit_faction)


func get_stats() -> StartingStats:
	return $Job.current_stats


func calculate_damage(attacking_unit_stats: StartingStats) -> int:
	var damage: float = 0
	var power = 1
	
	if attacking_unit_stats.weapon_type == StartingStats.WeaponType.STAFF:
		damage = 1.395 * power * pow(attacking_unit_stats.attack, 1.7) / pow(get_stats().defense, 0.7)
	else:
		damage = 1.5 * power * pow(attacking_unit_stats.spiritual_attack, 1.7) / pow(get_stats().spiritual_defense, 0.7)
	
	# TODO: randomize
	# TODO: circle of carnage
	# TODO: elemental resistances
	
	return int(damage)


func inflict_damage(damage: int) -> void:
	# tween HP down
	pass


## Signals

func _on_SelectionArea2D_input_event(_viewport: Node, event: InputEvent, _shape_idx: int):
	if event is InputEventMouseButton:
		if event.pressed:
			_pick_up()


func _on_Tween_tween_completed(_object: Object, key: String):
	if current_state == STATE.SNAPPING_TO_GRID:
		if key == ":position":
			self.current_state = STATE.IDLE
			
			emit_signal("snapped_to_grid", self)
