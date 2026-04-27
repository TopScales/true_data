##
##
@tool
extends Control

const SETTINGS_PREFIX: String = "addons/true_data/"
const Row: GDScript = preload("res://addons/true_data/views/collections_row.gd")
const Collection: GDScript = preload("res://addons/true_data/views/collection.gd")

@export var file_dialog: FileDialog

var undoredo: EditorUndoRedoManager

@onready var _configuration: ConfirmationDialog = $Configuration
@onready var _new_collection: ConfirmationDialog = $NewCollectionDialog
@onready var _warning: Button = $NoCollectionsWarning
@onready var _num_coll_label: Label = %NumCollectionsLabel
@onready var _delete_confirmation: ConfirmationDialog = $DeleteConfirmation

var _collections_path: String
var _collections: CollectionStringDict
var _row_scn: PackedScene = preload("res://addons/true_data/views/collections_row.tscn")
var _rows: Array[Row]

# =============================================================
# ========= Public Functions ==================================

func add_collection(collection: Collection) -> void:
	var row: Row = _row_scn.instantiate()
	row.collection = collection
	row.collections = _collections
	row.collection_name = collection.resource_name
	row.file_dialog = file_dialog
	row.undoredo = undoredo
	row.delete_confirmation = _delete_confirmation
	row.update_row()
	add_child(row)
	_rows.push_back(row)


func remove_collection(collection: Collection) -> void:
	for row in _rows:
		if row.collection == collection:
			remove_child(row)
			row.queue_free()
			break


# =============================================================
# ========= Built-in Functions ================================

func _ready() -> void:
	_configuration.file_dialog = file_dialog
	_new_collection.file_dialog = file_dialog
	__load_collections()

# =============================================================
# ========= Virtual Methods ===================================

# =============================================================
# ========= Private Functions =================================

func __load_collections() -> void:
	var path: String = ProjectSettings.get_setting(SETTINGS_PREFIX + "collections_resource_path", "")

	if path == _collections_path:
		return

	if path.is_empty():
		_collections = null
	else:
		_collections = ResourceLoader.load(path)

	var disable: bool = _collections == null
	_warning.visible = disable
	%NewCollection.disabled = disable
	%AddCollection.disabled = disable
	_num_coll_label.text = "Collections: %d" % (0 if disable else _collections.size())
	_collections_path = path

	for child in $HeadersContainer.get_children():
		if child is Button:
			child.disabled = disable


# =============================================================
# ========= Signal Callbacks ==================================


func _on_configuration_pressed() -> void:
	_configuration.show_dialog()


func _on_configuration_confirmed() -> void:
	__load_collections()


func _on_no_collections_warning_pressed() -> void:
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
