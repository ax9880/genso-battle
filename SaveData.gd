extends Resource

class_name SaveData


const MAX_SQUAD_SIZE: int = 6
const MIN_SQUAD_SIZE: int = 2

export(int) var version: int = 1

# Array<Job>
# Units that the player has 
export(Array, Resource) var jobs: Array = []

# Array<int>
export(Array, int) var active_units: Array = []

# Dictionary<String (battle title), int (current index of scene of said battle)>
export(Dictionary) var battle_progress: Dictionary = {}

# TODO: Save in file
export(int) var current_battle_index: int = 0
export(int) var current_battle_scene_index: int = 0

# TODO: chosen supports

export(float) var music_volume: float = 1.0
export(float) var sound_effects_volume: float = 1.0

export(String, "en", "es") var locale: String = ""
export(Enums.DragMode) var drag_mode: int = Enums.DragMode.CLICK

