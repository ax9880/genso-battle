class_name ChapterList
extends Resource


# Array<ChapterData>
# Collection of all the chapters that can be unlocked in the game
export(Array, Resource) var chapters: Array


func find_by_title(title: String) -> ChapterData:
	for chapter in chapters:
		if chapter.title == title:
			return chapter
	
	return null
