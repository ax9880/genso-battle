extends NinePatchRect

onready var texture_rect: TextureRect = $TextureRect
onready var glow_texture_rect: TextureRect = $GlowTextureRect
onready var weapon_type_texture_rect: TextureRect = $WeaponTypeTexture


func initialize(job: Job, is_draggable: bool = false) -> void:
	if not is_draggable:
		mouse_default_cursor_shape = Control.CURSOR_ARROW
	
	texture_rect.texture = job.portrait
	weapon_type_texture_rect.texture = load(Enums.WEAPON_TYPE_TEXTURES[job.stats.weapon_type])


func show_glow() -> void:
	glow_texture_rect.show()


func hide_glow() -> void:
	glow_texture_rect.hide()
