extends Resource

class_name SaveData

const MAX_SQUAD_SIZE: int = 6
const MIN_SQUAD_SIZE: int = 2

# Array<Job>
# Units that the player has 
export(Array, Resource) var jobs: Array = []

# Array<int>
export(Array, int) var active_units: Array = []

# TODO: chosen supports
# TODO: current battle

export(float) var music_volume: float = 1.0
export(float) var sound_effects_volume: float = 1.0

export(String, "en", "es") var locale: String = ""

#export(bool) var is_hold_to_drag: bool
