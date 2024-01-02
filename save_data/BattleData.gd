extends Resource

class_name BattleData


export(String) var title

export(bool) var has_script_scene: bool = false
export(bool) var has_dialogue_scene: bool = false

export(String, FILE, "*.tscn") var battle_scene_path

export(bool) var has_post_battle_script_scene: bool = false
export(bool) var has_post_battle_dialogue_scene: bool = false
export(bool) var has_supports_scene: bool = false

# Navigate to default script scene
# Get title of current battle and update everything
