extends Resource

class_name ChapterData


export(String) var title: String

export(String, FILE, "*.tscn") var battle_scene_path: String

export(Texture) var script_background: Texture
export(Texture) var dialogue_background: Texture
export(Texture) var post_battle_script_background: Texture

export(AudioStream) var script_audio_stream: AudioStream
export(AudioStream) var dialogue_audio_stream: AudioStream
export(AudioStream) var post_battle_script_audio_stream: AudioStream
