##
##
@tool
extends Control

signal edit_collection(collection: Resource)

const SETTINGS_PREFIX: String = "addons/true_data/"
const Row: GDScript = preload("res://addons/true_data/views/collections_row.gd")
const Collection: GDScript = preload("res://addons/true_data/classes/collection.gd")

const _ADDON: StringName = &"TrueData"

@export var file_dialog: FileDialog

var undoredo: EditorUndoRedoManager

@onready var _configuration: ConfirmationDialog = $Configuration
@onready var _new_collection: ConfirmationDialog = $NewCollectionDialog
@onready var _no_col_warn: Button = $NoCollectionsWarning
@onready var _incorrect_col_warn: Button = $IncorrectCollectionsWarning
@onready var _num_coll_label: Label = %NumCollectionsLabel
@onready var _delete_confirmation: ConfirmationDialog = $DeleteConfirmation
@onready var _spreadsheet: Control = $ScrollContainer/Spreadsheet

var _collections_path: String
var _collections: CollectionArray
var _row_scn: PackedScene = preload("res://addons/true_data/views/collections_row.tscn")
var _rows: Array[Row]

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


func add_collection(collection: Collection) -> void:
	if not _collections:
		return

	_collections.add_item(collection)
	__add_collection_row(collection)


func remove_collection(collection: Collection) -> void:
	for row in _rows:
		if row.collection == collection:
			remove_child(row)
			row.queue_free()
			break

	_collections.remove_item(collection)

	if _collections.size() == 0:
		for child in %HeadersContainer.get_children():
			if child is Button:
				child.disabled = true


# =============================================================
# ========= Built-in Functions ================================

func _ready() -> void:
	_configuration.file_dialog = file_dialog
	_new_collection.file_dialog = file_dialog
	Err.conn(EditorInterface.get_resource_filesystem().filesystem_changed, _on_filesystem_changed, 0, _ADDON)

# =============================================================
# ========= Virtual Methods ===================================

# =============================================================
# ========= Private Functions =================================

func __load_collections() -> void:
	var path: String = ProjectSettings.get_setting(SETTINGS_PREFIX + "collections_resource_path", "")

	if path.is_empty():
		_collections = null
		_no_col_warn.show()
		_incorrect_col_warn.hide()
	else:
		_no_col_warn.hide()

		if ResourceLoader.exists(path):
			_collections = ResourceLoader.load(path)

			if _collections:
				Err.conn(_collections.changed, reset, 0, _ADDON)
				_incorrect_col_warn.hide()
			else:
				_incorrect_col_warn.show()
		else:
			_collections = null
			_incorrect_col_warn.show()

	var disable: bool = _collections == null
	%NewCollection.disabled = disable
	%AddCollection.disabled = disable
	_num_coll_label.text = "Collections: %d" % (0 if disable else _collections.size())
	_collections_path = path
	var hide_headers: bool = not _collections or _collections.size() == 0

	for child in %HeadersContainer.get_children():
		if child is Button:
			child.disabled = hide_headers

	if _collections:
		for i in _collections.size():
			__add_collection_row(_collections.arr[i])


func __add_collection_row(collection: Collection) -> void:
	if _collections.size() == 0:
		for child in %HeadersContainer.get_children():
			if child is Button:
				child.disabled = false

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


func _on_configuration_pressed() -> void:
	_configuration.show_dialog()


func _on_configuration_confirmed() -> void:
	__load_collections()


func _on_no_collections_warning_pressed() -> void:
	_configuration.show_dialog()


func _on_incorrect_collections_warning_pressed() -> void:
	_configuration.show_dialog()


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
