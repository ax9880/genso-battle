extends NinePatchRect


onready var _texture_rect: TextureRect = $MarginContainer/TextureRect
onready var _glow_texture_rect: TextureRect = $GlowTextureRect
onready var _weapon_type_texture_rect: TextureRect = $WeaponTypeTexture


func initialize(job: Job, is_draggable: bool = false) -> void:
	if not is_draggable:
		mouse_default_cursor_shape = Control.CURSOR_ARROW
	
	_texture_rect.texture = job.portrait
	_weapon_type_texture_rect.texture = load(Enums.WEAPON_TYPE_TEXTURES[job.stats.weapon_type])


func show_glow() -> void:
	_glow_texture_rect.show()


func hide_glow() -> void:
	_glow_texture_rect.hide()
