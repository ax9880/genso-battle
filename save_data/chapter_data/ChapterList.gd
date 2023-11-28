extends Resource

class_name ChapterList

# Array<ChapterData>
export(Array, Resource) var chapters: Array


func find_by_title(title: String) -> ChapterData:
	for chapter in chapters:
		if chapter.title == title:
			return chapter
	
	return null
