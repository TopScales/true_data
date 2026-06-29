@tool
extends Control

signal edit_collection(collection: Resource)

const Row: GDScript = preload("res://addons/true_data/views/collections_row.gd")
const Collection: GDScript = preload("res://addons/true_data/classes/collection.gd")

const _SETTINGS_PREFIX: String = "addons/true_data/"
const _ADDON: StringName = &"TrueData"

var file_dialog: EditorFileDialog
var undoredo: EditorUndoRedoManager

@onready var _new_collection: ConfirmationDialog = $NewCollectionDialog
@onready var _num_coll_label: Label = %NumCollectionsLabel
@onready var _delete_confirmation: ConfirmationDialog = $DeleteConfirmation
@onready var _spreadsheet: Control = $ScrollContainer/Spreadsheet

var _collections_path: String
var _collections: DataCollections
var _row_scn: PackedScene = preload("res://addons/true_data/views/collections_row.tscn")

# =============================================================
# ========= Public Functions ==================================


func reset() -> void:
	if _collections:
		_collections.changed.disconnect(reset)

	for i in range(1, _spreadsheet.get_child_count()):
		var row: Node = _spreadsheet.get_child(i)
		row.queue_free()

	__load_collections()


func load_data() -> void:
	__load_collections()


func save_data() -> void:
	if _collections:
		var save_path: String = ResourceUID.uid_to_path(_collections_path)
		Err.try_err(ResourceSaver.save(_collections, save_path), "Failed to save collections file.", _ADDON)


func add_collection(collection_name: StringName, collection: Collection) -> void:
	if not _collections:
		return

	if _collections.size() == 0:
		for child in %HeadersContainer.get_children():
			if child is Button:
				child.disabled = false

	_collections.add_item(collection_name, collection)
	__add_collection_row(collection)
	_num_coll_label.text = "Collections: %d" % _collections.size()


func remove_collection(collection_name: StringName) -> void:
	var row: Control = _spreadsheet.get_node(NodePath(collection_name))
	row.queue_free()
	_collections.remove_item(collection_name)
	_num_coll_label.text = "Collections: %d" % _collections.size()

	if _collections.size() == 0:
		for child in %HeadersContainer.get_children():
			if child is Button:
				child.disabled = true


# =============================================================
# ========= Built-in Functions ================================

func _ready() -> void:
	_new_collection.file_dialog = file_dialog
	Err.conn(EditorInterface.get_resource_filesystem().filesystem_changed, _on_filesystem_changed, 0, _ADDON)


func _notification(what: int) -> void:
	if what == NOTIFICATION_THEME_CHANGED:
		$WarningBox/Icon.texture = EditorInterface.get_editor_theme().get_icon(&"NodeWarning", &"EditorIcons")
		$WarningBox/Label.add_theme_color_override(&"font_color", EditorInterface.get_editor_theme().get_color(&"warning_color", &"Editor"))
		%NewCollection.icon = EditorInterface.get_editor_theme().get_icon(&"Add", &"EditorIcons")
		%AddCollection.icon = EditorInterface.get_editor_theme().get_icon(&"FileAccess", &"EditorIcons")

# =============================================================
# ========= Virtual Methods ===================================

# =============================================================
# ========= Private Functions =================================

func __load_collections() -> void:
	var path: String = ProjectSettings.get_setting(_SETTINGS_PREFIX + "collections_resource_path", "")
	var incorrect: bool = path.is_empty() or not ResourceLoader.exists(path)
	_collections = null

	if not incorrect:
		_collections = ResourceLoader.load(path)

		if _collections:
			Err.conn(_collections.changed, reset, 0, _ADDON)
		else:
			incorrect = true

	$WarningBox.visible = incorrect
	%NewCollection.disabled = incorrect
	%AddCollection.disabled = incorrect

	_num_coll_label.text = "Collections: %d" % (0 if incorrect else _collections.size())
	_collections_path = path
	var hide_headers: bool = incorrect or _collections.size() == 0

	for child in %HeadersContainer.get_children():
		if child is Button:
			child.disabled = hide_headers

	if _collections:
		for i in _collections.size():
			__add_collection_row(_collections.arr[i] as Collection)


func __add_collection_row(collection: Collection) -> void:
	var row: Row = _row_scn.instantiate() as Row
	_spreadsheet.add_child(row)
	row.collection = collection
	row.collections = _collections
	row.file_dialog = file_dialog
	row.undoredo = undoredo
	row.delete_confirmation = _delete_confirmation
	row.update_row()
	_rows.push_back(row)
	Err.conn(row.deleted, _on_row_deleted.bind(collection), 0, _ADDON)
	Err.conn(row.edit, _on_row_edit.bind(collection), 0, _ADDON)


# =============================================================
# ========= Signal Callbacks ==================================

func _on_filesystem_changed() -> void:
	if _collections and not FileAccess.file_exists(_collections_path):
		reset()


func _on_row_edit(collection: Collection) -> void:
	edit_collection.emit(collection)


func _on_row_deleted(collection: Collection) -> void:
	undoredo.create_action("Delete collection")
	undoredo.add_do_method(self, &"remove_collection", collection)
	undoredo.add_undo_method(self, &"add_collection", collection)
	undoredo.commit_action()


func _on_new_collection_pressed() -> void:
	_new_collection.show_dialog()


func _on_new_collection_confirmed() -> void:
	var collection: Collection = _new_collection.get_collection()

	if collection:
		undoredo.create_action("Create new collection")
		undoredo.add_do_method(self, &"add_collection", collection)
		undoredo.add_undo_method(self, &"remove_collection", collection)
		undoredo.commit_action()


func _on_add_collection_pressed() -> void:
	pass # Replace with function body.
