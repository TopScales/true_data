##
##
@tool
extends MarginContainer

enum View { COLLECTIONS, COLLECTION }

const SETTINGS_PREFIX: String = "addons/true_data/"

const _ADDON: StringName = &"TrueData"

@export_file_path("*.tscn", "*.scn") var view_paths: PackedStringArray

var undoredo: EditorUndoRedoManager

var _current_view_ctrl: Control
var _current_view: View = View.COLLECTIONS
var _file_dialog: EditorFileDialog


# =============================================================
# ========= Public Functions ==================================

func save_data() -> void:
	_current_view_ctrl.save_data()


func change_view(view_index: View) -> void:
	_current_view_ctrl.queue_free()
	var scn: PackedScene = load(view_paths[view_index])
	_current_view_ctrl = scn.instantiate()
	_current_view_ctrl.undoredo = undoredo
	_current_view_ctrl.file_dialog = _file_dialog
	add_child(_current_view_ctrl)
	move_child(_current_view_ctrl, 0)
	_current_view = view_index
	__connect_view()


# =============================================================
# ========= Built-in Functions ================================

func _enter_tree() -> void:
	if not _file_dialog:
		_file_dialog = EditorFileDialog.new()
		add_child(_file_dialog)
		_file_dialog.hide()

	_current_view_ctrl = get_child(0)
	_current_view_ctrl.undoredo = undoredo
	_current_view_ctrl.file_dialog = _file_dialog


func _ready() -> void:
	if not undoredo:
		# Likely the scene is being edited.
		return

	_current_view_ctrl.load_data()
	Err.conn(ProjectSettings.settings_changed, _on_settings_changed, 0, _ADDON)
	__connect_view()


# =============================================================
# ========= Virtual Methods ===================================

# =============================================================
# ========= Private Functions =================================

func __connect_view() -> void:
	if _current_view == View.COLLECTIONS:
		Err.conn(_current_view_ctrl.edit_collection, _on_collections_edit_collection, 0, _ADDON)
	elif _current_view == View.COLLECTION:
		Err.conn(_current_view_ctrl.back_pressed, _on_collection_back_pressed, 0, _ADDON)

# =============================================================
# ========= Signal Callbacks ==================================

func _on_settings_changed() -> void:
	if SETTINGS_PREFIX + "collections_resource_path" in ProjectSettings.get_changed_settings():
		_current_view_ctrl.reset()


func _on_collections_edit_collection(collection: Resource) -> void:
	_current_view_ctrl.save_data()
	change_view(View.COLLECTION)
	_current_view_ctrl.set_collection(collection)


func _on_collection_back_pressed() -> void:
	_current_view_ctrl.save_data()
	change_view(View.COLLECTIONS)
	_current_view_ctrl.load_data()
