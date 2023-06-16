extends KinematicBody2D

class_name Unit

enum STATE {
	# Idle
	IDLE = 0,
	
	# Picked up, being dragged by the player or being moved by the AI
	PICKED_UP = 1,
	
	SNAPPING_TO_GRID = 2,
	
	SWAPPING = 3
}

enum Size {
	SINGLE_1X1,
	DOUBLE_2X2
}

const INVALID_FACTION: int = -1
const PLAYER_FACTION: int = 1
const ENEMY_FACTION: int = 2

const WEAPON_ADVANTAGE: float = 3.0
const WEAPON_DISADVANTAGE: float = 1.0

## Exports

export(PackedScene) var damage_numbers_packed_scene: PackedScene
export(PackedScene) var death_effect_packed_scene: PackedScene

export(Size) var size: int = Size.SINGLE_1X1

export var velocity_pixels_per_second: float = 10.0
export var snap_velocity_pixels_per_second: float = 200.0
export var swap_velocity_pixels_per_second: float = 500.0

# Max velocity when dragging the unit. It can't be too fast or the unit
# will tunnel through cells and other units.
export var max_velocity_pixels_per_second: float = 2048.0 # 2048

# Proportional control constant
export var kp: float = 1.4

export(bool) var is_click_to_drag: bool = true
export(bool) var is_controlled_by_player: bool = true

## Onready

onready var tween := $Tween
onready var sprite := $Sprite


## Vars

var current_state = STATE.IDLE setget set_current_state

var faction: int = INVALID_FACTION

var random := RandomNumberGenerator.new()


## Signals

signal picked_up(unit)
signal released(unit)
signal snapped_to_grid(unit)
signal death_animation_finished(unit)


func _ready() -> void:
	random.randomize()
	
	self.current_state = STATE.IDLE
	
	_load_job_textures()
	
	if not is_controlled_by_player or not is_click_to_drag:
		set_process_input(false)


func _physics_process(_delta: float) -> void:
	match(current_state):
		STATE.IDLE:
			pass
		STATE.PICKED_UP:
			if is_controlled_by_player:
				_move_towards_mouse()
				
				if is_click_to_drag:
					if Input.is_action_just_released("ui_accept"):
						release()


func appear() -> void: 
	disable_selection_area()
	
	disable_swap_area()
	
	$Sound/AppearAudio.play()
	
	$AnimationPlayer.play("appear")


func hide_name() -> void:
	$AnimationPlayer.play("hide name")


func play_death_animation() -> void:
	$AnimationPlayer.play("death")
	$Sound/DeathAudio.play()
	
	var death_effect: Node2D = death_effect_packed_scene.instance()
	
	add_child(death_effect)
	death_effect.play()
	
	disable_selection_area()
	disable_swap_area()
	Utils.disable_object($CollisionShape2D)


func is_death_animation_playing() -> bool:
	return $AnimationPlayer.current_animation == "death"


func play_scale_and_and_down_animation() -> void:
	$Tween.remove($Sprite, ":scale")
	
	$AnimationPlayer.play("scale up and down")


func stop_scale_and_and_down_animation() -> void:
	assert($AnimationPlayer.current_animation == "scale up and down")
	
	$AnimationPlayer.stop(true)
	
	$Tween.remove($Sprite, ":scale")
	
	$Tween.interpolate_property($Sprite, "scale",
		$Sprite.scale, Vector2.ONE,
		0.15,
		Tween.TRANS_LINEAR)
	
	$Tween.start()


func move_to_new_cell(target_position: Vector2) -> void:
	tween.remove(self, ":position")
	
	var tween_time_seconds: float = Utils.calculate_time(position, target_position, swap_velocity_pixels_per_second)
	
	tween.interpolate_property(self, "position",
				position, target_position,
				tween_time_seconds,
				Tween.TRANS_SINE)
			
	tween.start()
	
	self.current_state = STATE.SWAPPING


func push_to_cell(target_position: Vector2) -> void:
	move_to_new_cell(target_position)
	
	var tween_time_seconds: float = Utils.calculate_time(position, target_position, swap_velocity_pixels_per_second)
	
	tween.interpolate_property(self, "rotation",
				0.0, 2 * PI,
				tween_time_seconds,
				Tween.TRANS_SINE)
			
	tween.start()
	
	Utils.disable_object($CollisionShape2D)


func enable_swap_area() -> void:
	Utils.enable_object($SwapArea2D/CollisionShape2D)


func disable_swap_area() -> void:
	Utils.disable_object($SwapArea2D/CollisionShape2D)


func enable_selection_area() -> void:
	Utils.enable_object($SelectionArea2D/CollisionShape2D)
	
	$SelectionArea2D.monitorable = true


func disable_selection_area() -> void:
	Utils.disable_object($SelectionArea2D/CollisionShape2D)
	
	$SelectionArea2D.monitorable = false


func _move_towards_mouse() -> void:
	var error: Vector2 = get_global_mouse_position() - global_position
	
	var velocity = Vector2(error * kp * velocity_pixels_per_second).limit_length(max_velocity_pixels_per_second)
	
	var _velocity = move_and_slide(velocity, Vector2.ZERO)


func _input(event: InputEvent):
	if not is_click_to_drag and event.is_action_released("ui_select"):
		release()


func snap_to_grid(cell_origin: Vector2) -> void:
	self.current_state = STATE.SNAPPING_TO_GRID
	
	var tween_time_seconds: float = Utils.calculate_time(position, cell_origin, snap_velocity_pixels_per_second)
	
	tween.interpolate_property(self, "position",
		position, cell_origin,
		tween_time_seconds,
		Tween.TRANS_SINE)
	
	tween.start()


func is_picked_up() -> bool:
	return current_state == STATE.PICKED_UP


func is_snapping() -> bool:
	return current_state == STATE.SNAPPING_TO_GRID


func is_idle() -> bool:
	return current_state == STATE.IDLE


func _pick_up() -> void:
	if current_state == STATE.IDLE:
		self.current_state = STATE.PICKED_UP
		
		if is2x2():
			Utils.disable_object($CollisionShape2D)


func release() -> void:
	if current_state == STATE.PICKED_UP:
		self.current_state = STATE.IDLE
		
		emit_signal("released", self)


func _load_job_textures() -> void:
	$Control/WeaponType.texture = load(Enums.WEAPON_TYPE_TEXTURES[$Job.job.stats.weapon_type])
	$Sprite/Icon.texture = $Job.job.portrait
	
	$CanvasLayer/UnitName.text = tr($Job.job.job_name)


## Setters

func set_job(new_job: Job) -> void:
	$Job.set_job(new_job)
	
	_load_job_textures()


func set_drag_mode(drag_mode: int) -> void:
	if drag_mode == Enums.DragMode.CLICK:
		is_click_to_drag = true
		set_process_input(false)
	else:
		is_click_to_drag = false
		set_process_input(true)


# Setter function for current_state.
func set_current_state(new_state) -> void:
	current_state = new_state
	
	match(new_state):
		STATE.IDLE:
			disable_swap_area()
			
			set_physics_process(false)
			
			_restore_sprite_size()
			
			Utils.enable_object($CollisionShape2D)
		STATE.PICKED_UP:
			enable_swap_area()
			
			set_physics_process(true)
			
			emit_signal("picked_up", self)
			
			_increase_sprite_size()
			
			$Sound/PickUpAudio.play()
		STATE.SNAPPING_TO_GRID:
			disable_swap_area()
		STATE.SWAPPING:
			disable_swap_area()
			
			$Sound/SwapAudio.play()


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


func get_max_health() -> int:
	return $Job.base_stats.health


func calculate_attack_damage(attacker_stats: StartingStats, pincering_unit_stats: StartingStats = null) -> int:
	var attacker_weapon_type: int = attacker_stats.weapon_type
	
	if pincering_unit_stats != null:
		attacker_weapon_type = pincering_unit_stats.weapon_type
	
	var damage: int = calculate_damage(attacker_stats, get_stats(), 1.0, attacker_weapon_type, attacker_stats.attribute)
	
	return damage


func inflict_damage(damage: int) -> void:
	$Job.decrease_health(damage)
	
	if damage > 0:
		$AnimationPlayer.play("shake")
	
	var damage_numbers: Node2D = damage_numbers_packed_scene.instance()
	add_child(damage_numbers)
	
	damage_numbers.play(damage)


func activate_skills() -> Array:
	var activated_skills := []
	
	for skill in $Job.get_unlocked_skills():
		# TODO: Add more rules for activation?
		# If unit is not leading pincer?
		if skill.area_of_effect == Enums.AreaOfEffect.EQUIP:
			continue
		
		var activation: float = random.randf()
		
		if skill.activation_rate > activation:
			activated_skills.push_back(skill)
	
	return activated_skills


func play_skill_activation_animation(activated_skills: Array, layer_z_index: int) -> void:
	$CanvasLayer/ActivatedSkillMarginContainer.play(activated_skills)
	$CanvasLayer.z_index = layer_z_index


func apply_skill(unit: Unit, skill: Skill, on_damage_absorbed_callback: FuncRef) -> void:
	if skill.is_attack() or skill.is_healing():
		var damage := calculate_damage(unit.get_stats(), get_stats(), skill.primary_power, skill.primary_weapon_type, skill.primary_attribute)
		
		damage = int(damage * random.randf_range(0.9, 1.1))
		
		if skill.is_healing():
			damage = -damage * 3
		
		var absorbed_damage = int(skill.absorb_rate * damage)
		
		on_damage_absorbed_callback.call_func(absorbed_damage)
		
		inflict_damage(damage)
	else:
		# If it's buff or debuff, try to apply it
		# If it has status effect, try to apply it
		printerr("Don't know how to apply skill %s" % skill.skill_name)


func calculate_damage(attacker_stats: StartingStats,
			defender_stats: StartingStats,
			power: float,
			weapon_type: int,
			attribute: int) -> int:
	var damage: float = 0
	
	if weapon_type == Enums.WeaponType.STAFF:
		damage = 1.8 * power * attacker_stats.attack * attacker_stats.attack / defender_stats.defense
		
		damage = damage * (1 - get_attribute_resistance(defender_stats, attribute, defender_stats.attribute))
	else:
		damage = 1.57 * power * attacker_stats.attack * attacker_stats.attack / defender_stats.defense
		
		damage = damage * get_weapon_type_advantage(attacker_stats.weapon_type, defender_stats.weapon_type)
	
	return int(damage)


func get_weapon_type_advantage(attacker_weapon_type, defender_weapon_type) -> float:
	var disadvantaged_weapon_type = Enums.WEAPON_RELATIONSHIPS.get(attacker_weapon_type)
	
	if disadvantaged_weapon_type == defender_weapon_type:
		return WEAPON_ADVANTAGE
	else:
		return WEAPON_DISADVANTAGE


func get_attribute_resistance(defender_stats: StartingStats, attacker_attribute, defender_attribute) -> float:
	if attacker_attribute == defender_attribute:
		return defender_stats.same_attribute_resistance
	else:
		var disadvantaged_attribute = Enums.ATTRIBUTE_RELATIONSHIPS.get(attacker_attribute)
		
		if disadvantaged_attribute != null and disadvantaged_attribute == defender_attribute:
			# Vulnerable
			return -1.0
		else:
			# TODO: Use elemental resistance dictionary
			
			# No resistance
			return 0.0


func is_dead() -> bool:
	return get_stats().health <= 0


func is_alive() -> bool:
	return not is_dead()


func is2x2() -> bool:
	return size == Size.DOUBLE_2X2


## Animation playback


func _appear_animation_finished() -> void:
	self.current_state = STATE.IDLE


func _death_animation_finished() -> void:
	emit_signal("death_animation_finished", self)


func _on_snap_to_grid() -> void:
	self.current_state = STATE.IDLE
	
	emit_signal("snapped_to_grid", self)
	
	$Sound/SnapAudio.play()

## Signals

func _on_SelectionArea2D_input_event(_viewport: Node, event: InputEvent, _shape_idx: int):
	if event is InputEventMouseButton and event.pressed:
		match(current_state):
			STATE.IDLE:
				_pick_up()
			STATE.PICKED_UP:
				release()


func _on_Tween_tween_completed(_object: Object, key: String):
	match(current_state):
		STATE.SNAPPING_TO_GRID:
			if key == ":position":
				_on_snap_to_grid()
		STATE.SWAPPING:
			if key == ":position":
				self.current_state = STATE.IDLE


func _on_SelectionArea2D_mouse_entered():
	if current_state == STATE.IDLE:
		$Sprite/Glow.show()
		
		$Sprite.scale = Vector2(1.1, 1.1)


func _on_SelectionArea2D_mouse_exited():
	if current_state == STATE.IDLE:
		#$Sprite/Glow.hide()
		
		$Sprite.scale = Vector2(1, 1)
	
