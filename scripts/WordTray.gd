class_name WordTray
extends Control

signal tile_added(tile: LetterTile)
signal tile_removed(tile: LetterTile)
signal tray_full

const MAX_TILES: int = 8

var _tiles: Array[LetterTile] = []

var word: String:
	get:
		var s := ""
		for t in _tiles:
			s += t.letter
		return s


func _ready() -> void:
	var ls := LabelSettings.new()
	ls.font = load("res://assets/fonts/ui_font.ttf")
	ls.font_size = 22
	ls.font_color = Color.WHITE
	for i in MAX_TILES:
		var lbl := Label.new()
		lbl.name = "Slot%d" % i
		lbl.text = "_"
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		lbl.custom_minimum_size = Vector2(44, 38)
		lbl.modulate.a = 0.3
		lbl.label_settings = ls
		$Slots.add_child(lbl)


func add_tile(tile: LetterTile) -> bool:
	if _tiles.size() >= MAX_TILES:
		tray_full.emit()
		return false
	_tiles.append(tile)
	tile.select()
	tile.tree_exiting.connect(_on_tile_exiting.bind(tile))
	tile_added.emit(tile)
	_refresh()
	return true


func remove_last() -> void:
	if _tiles.is_empty():
		return
	var tile := _tiles.pop_back()
	_disconnect_exiting(tile)
	tile.deselect()
	tile_removed.emit(tile)
	_refresh()


func clear() -> void:
	for tile in _tiles.duplicate():
		_disconnect_exiting(tile)
		tile.deselect()
	_tiles.clear()
	_refresh()


func accept_and_destroy() -> void:
	for tile in _tiles.duplicate():
		_disconnect_exiting(tile)
	_tiles.clear()
	_refresh()


func get_tiles() -> Array[LetterTile]:
	return _tiles.duplicate()


func has_tile(tile: LetterTile) -> bool:
	return tile in _tiles


func last_tile() -> LetterTile:
	if _tiles.is_empty():
		return null
	return _tiles.back()


func _disconnect_exiting(tile: LetterTile) -> void:
	var cb := _on_tile_exiting.bind(tile)
	if tile.tree_exiting.is_connected(cb):
		tile.tree_exiting.disconnect(cb)


func _on_tile_exiting(tile: LetterTile) -> void:
	if _tiles.has(tile):
		_tiles.erase(tile)
		_refresh()


func _refresh() -> void:
	var slots := $Slots
	for i in MAX_TILES:
		var lbl: Label = slots.get_child(i)
		if i < _tiles.size():
			lbl.text = _tiles[i].letter
			lbl.modulate.a = 1.0
		else:
			lbl.text = "_"
			lbl.modulate.a = 0.3
