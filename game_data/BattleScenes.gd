extends Resource

class_name BattleScenes

# As translatable key
export(String) var title: String

export(Array, String, FILE, "*.tscn") var scenes

export(Array, String, FILE, "*.tscn") var support_scenes
