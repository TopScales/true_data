##
##
@tool
extends HBoxContainer

signal deleted
signal edit

const Collection: GDScript = preload("res://addons/true_data/views/collection.gd")

const _ADDON: StringName = &"TrueData"

var collection: Collection
var collections: CollectionArray
var file_dialog: FileDialog
var delete_confirmation: ConfirmationDialog
var undoredo: EditorUndoRedoManager

var _updating: bool = false # Avoid triggering Load Check toggle signal.

@onready var _name_edit: LineEdit = $NameEdit
@onready var _path_label: Label = $PathContainer/PathLabel
@onready var _script_button: Button = $ScriptButton
@onready var _type_option: OptionButton = $TypeOption
@onready var _entries_label: Label = $EntriesLabel
@onready var _load_check: Button = $LoadCheckCell/LoadCheck

# =============================================================
# ========= Public Functions ==================================

func update_row() -> void:
	_updating = true
	_name_edit.text = collection.resource_name
	_path_label.text = collection.path
	_type_option.select(collection.type)
	_load_check.button_pressed = collection.bulk_load
	var script_name: String = collection.collection_script.get_global_name()
	_updating = false

	if script_name.is_empty():
		script_name = collection.collection_script.resource_path.get_basename().get_file().to_pascal_case()

	_script_button.text = script_name
	_entries_label.text = str(collection.entries)


func set_collection_name(new_name: StringName) -> void:
	collection.resource_name = new_name


func set_collection_path(new_path: String) -> void:
	collection.path = new_path
	_path_label.text = new_path


func set_collection_script(script_: GDScript) -> void:
	var script_name: String = script_.get_global_name()

	if script_name.is_empty():
		script_name = script_.resource_path.get_basename().get_file().to_pascal_case()

	collection.collection_script = script_
	_script_button.text = script_name


func set_collection_bulk_load(bulk_load: bool) -> void:
	collection.bulk_load = bulk_load
	var icon_name: StringName = &"GuiChecked" if bulk_load else &"GuiUnchecked"
	_load_check.icon = EditorInterface.get_editor_theme().get_icon(icon_name, &"EditorIcons")


# =============================================================
# ========= Built-in Functions ================================

# =============================================================
# ========= Virtual Methods ===================================

# =============================================================
# ========= Private Functions =================================

func __is_path_correct(path: String) -> bool:
	if path.is_empty():
		return false
	else:
		var exists: bool = false
#
		if path.get_extension().is_empty():
			exists = DirAccess.dir_exists_absolute(path)
		else:
			exists = FileAccess.file_exists(path)
#
		if exists:
			if collection.type == Collection.CollectionType.FILES:
				if not path.get_extension().is_empty():
					return false
			elif collection.type == Collection.CollectionType.CONFIG:
				return __is_config_path_correct(path)
			else:
				return __is_collection_path_correct(path, collection.type)
		else:
			return false

	return true


func __is_collection_path_correct(path: String, type: int) -> bool:
	if ResourceLoader.exists(path):
		var res: Resource = ResourceLoader.load(path)

		if type == Collection.CollectionType.STRING_DICTIONARY:
			return res is CollectionStringDict
		elif type == Collection.CollectionType.INT_DICTIONARY:
			return res is CollectionIntDict
		elif type == Collection.CollectionType.ARRAY:
			return res is CollectionArray

	return false


func __is_config_path_correct(path: String) -> bool:
	var config: ConfigFile = ConfigFile.new()
	return config.load(path) == OK

# =============================================================
# ========= Signal Callbacks ==================================

func _on_path_confirmed() -> void:
	file_dialog.canceled.disconnect(_on_file_dialog_canceled)

	if __is_path_correct(file_dialog.current_path):
		undoredo.create_action("Set collection path")
		undoredo.add_do_method(self, &"set_collection_path", file_dialog.current_path)
		undoredo.add_undo_method(self, &"set_collection_path", collection.path)
		undoredo.commit_action()


func _on_script_confirmed() -> void:
	file_dialog.canceled.disconnect(_on_file_dialog_canceled)
	var new_script: GDScript = load(file_dialog.current_path)

	if new_script.get_instance_base_type() == "Resource":
		undoredo.create_action("Set collection script")
		undoredo.add_do_method(self, &"set_collection_script", new_script)
		undoredo.add_undo_method(self, &"set_collection_script", collection.collection_script)
		undoredo.commit_action()


func _on_delete_confirmed() -> void:
	deleted.emit()


func _on_file_dialog_canceled() -> void:
	if file_dialog.confirmed.is_connected(_on_path_confirmed):
		file_dialog.confirmed.disconnect(_on_path_confirmed)

	if file_dialog.confirmed.is_connected(_on_script_confirmed):
		file_dialog.confirmed.disconnect(_on_script_confirmed)


func _on_name_edit_text_submitted(new_text: String) -> void:
	if new_text.is_empty():
		_name_edit.text = collection.resource_name
		return

	undoredo.create_action("Set collection name")
	undoredo.add_do_method(self, &"set_collection_name", StringName(new_text))
	undoredo.add_undo_method(self, &"set_collection_name", collection.resource_name)
	undoredo.commit_action()


func _on_name_edit_editing_toggled(toggled_on: bool) -> void:
	_name_edit.flat = not toggled_on


func _on_load_check_toggled(toggled_on: bool) -> void:
	if _updating:
		var icon_name: StringName = &"GuiChecked" if toggled_on else &"GuiUnchecked"
		_load_check.icon = EditorInterface.get_editor_theme().get_icon(icon_name, &"EditorIcons")
		return

	undoredo.create_action("Set collection bulk load")
	undoredo.add_do_method(self, &"set_collection_bulk_load", toggled_on)
	undoredo.add_undo_method(self, &"set_collection_bulk_load", collection.bulk_load)
	undoredo.commit_action()


func _on_path_browse_button_pressed() -> void:
	if collection.type == Collection.CollectionType.FILES:
		file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_DIR
		file_dialog.current_file = ""

		if collection.path.get_extension().is_empty() and DirAccess.dir_exists_absolute(collection.path):
			file_dialog.current_dir = collection.path
		else:
			file_dialog.current_dir = ""
	else:
		file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE

		if collection.type == Collection.CollectionType.CONFIG:
			file_dialog.filters = ["*.cfg,*.ini;Config File;text/plain"]
		else:
			file_dialog.filters = ["*.tres,*.res;Resource;text/plain"]

		if collection.path.get_extension().is_empty():
			file_dialog.current_dir = collection.path
			file_dialog.current_file = ""
		else:
			file_dialog.current_dir = ""
			file_dialog.current_file = collection.path

	Err.conn(file_dialog.confirmed, _on_path_confirmed, CONNECT_ONE_SHOT, _ADDON)
	Err.conn(file_dialog.canceled, _on_file_dialog_canceled, CONNECT_ONE_SHOT, _ADDON)
	file_dialog.popup_centered()


func _on_script_button_pressed() -> void:
	file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	file_dialog.filters = ["*.gd;GDScript;text/plain"]
	Err.conn(file_dialog.confirmed, _on_script_confirmed, CONNECT_ONE_SHOT, _ADDON)
	Err.conn(file_dialog.canceled, _on_file_dialog_canceled, CONNECT_ONE_SHOT, _ADDON)
	file_dialog.popup_centered()


func _on_edit_button_pressed() -> void:
	edit.emit()


func _on_delete_button_pressed() -> void:
	delete_confirmation.dialog_text = "Delete collection \"%s\"?" % collection.resource_name
	Err.conn(delete_confirmation.confirmed, _on_delete_confirmed, CONNECT_ONE_SHOT, _ADDON)
	var cancel_func: Callable = func():
		delete_confirmation.confirmed.disconnect(_on_delete_confirmed)
	Err.conn(delete_confirmation.canceled, cancel_func, CONNECT_ONE_SHOT, _ADDON)
	delete_confirmation.popup_centered()
