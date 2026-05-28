extends Node

signal word_accepted(word: String, score: int)
signal word_rejected(word: String)

var _word_set: Dictionary = {}


func _ready() -> void:
	_load_words()


func _load_words() -> void:
	var file := FileAccess.open("res://assets/data/words_en.txt", FileAccess.READ)
	if file == null:
		push_error("WordValidator: cannot open words_en.txt — error %d" % FileAccess.get_open_error())
		return
	while not file.eof_reached():
		var w := file.get_line().strip_edges().to_lower()
		if w.length() >= 3:
			_word_set[w] = true
	file.close()


func is_valid(word: String) -> bool:
	return _word_set.has(word.to_lower())


func submit(word: String, tiles: Array[LetterTile]) -> void:
	if is_valid(word):
		word_accepted.emit(word, _score(tiles))
	else:
		word_rejected.emit(word)


func _score(tiles: Array[LetterTile]) -> int:
	var base := 0
	for t in tiles:
		base += t.point_value
	return base * (2 if tiles.size() >= 5 else 1)
