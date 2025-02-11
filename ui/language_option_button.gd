extends OptionButton


const LANGUAGE_EN_INDEX: int = 0
const LANGUAGE_ES_INDEX: int = 1


func _ready() -> void:
	var locale = TranslationServer.get_locale()
	
	if locale.begins_with("es"):
		select(LANGUAGE_ES_INDEX)
	else:
		select(LANGUAGE_EN_INDEX)


func _on_LanguageOptionButton_item_selected(index: int) -> void:
	match(index):
		LANGUAGE_EN_INDEX:
			TranslationServer.set_locale("en")
		LANGUAGE_ES_INDEX:
			TranslationServer.set_locale("es")
