##
##
@tool
extends ConfirmationDialog

const WIDTH: int = 440
const ERR_NAME_EMPTY_IDX: int = 0
const ERR_PATH_EMPTY_IDX: int = 1
const ERR_PATH_NOT_FOUND_IDX: int = 2
const ERR_PATH_INCORRECT_IDX: int = 3
const ERR_SCRIPT_EMPTY_IDX: int = 4
const ERR_SCRIPT_WRONG_IDX: int = 5

const Collection: GDScript = preload("res://addons/true_data/classes/collection.gd")

const ERR_NAME_EMPTY: int = 1
const ERR_PATH_EMPTY: int = 2
const ERR_PATH_NOT_FOUND: int = 4
const ERR_PATH_INCORRECT: int = 8
const ERR_SCRIPT_EMPTY: int = 16
const ERR_SCRIPT_WRONG: int = 32

const _ADDON: StringName = &"TrueData"

@export var file_dialog: FileDialog

var _err_status: int = OK
var _script: GDScript
var _type_selected: bool = false

@onready var _errors: Array[Control] = [
	$Box/NameErrorContainer,
	$Box/NoPathErrorContainer,
	$Box/PathNotFoundErrorContainer,
	$Box/IncorrectPathErrorContainer,
	$Box/NoScriptErrorContainer,
	$Box/WrongScriptErrorContainer
]
@onready var _type: OptionButton = %TypeOption

# =============================================================
# ========= Public Functions ==================================

func show_dialog() -> void:
	for err in _errors:
		err.hide()

	%NameEdit.text = ""
	%PathEdit.text = ""
	%ScriptEdit.text = ""
	_type.select(0)
	%LoadOption.select(0)
	_err_status = ERR_NAME_EMPTY | ERR_PATH_EMPTY | ERR_SCRIPT_EMPTY
	get_ok_button().disabled = true
	_script = null
	_type_selected = false
	popup_centered(Vector2i(WIDTH, 0))


func get_collection() -> Collection:
	if _err_status != OK:
		return null

	var collection: Collection = Collection.new()
	collection.resource_name = %NameEdit.text
	collection.path = %PathEdit.text
	collection.type = %TypeOption.selected
	collection.collection_script = _script
	collection.bulk_load = %LoadOption.get_selected_id()
	return collection

# =============================================================
# ========= Built-in Functions ================================

# =============================================================
# ========= Virtual Methods ===================================

# =============================================================
# ========= Private Functions =================================


func __check_path(path: String) -> void:
	if path.is_empty():
		_err_status |= ERR_PATH_EMPTY
		_errors[ERR_PATH_EMPTY_IDX].show()
		_err_status &= ~ERR_PATH_NOT_FOUND
		_errors[ERR_PATH_NOT_FOUND_IDX].hide()
		_err_status &= ~ERR_PATH_INCORRECT
		_errors[ERR_PATH_INCORRECT_IDX].hide()
	else:
		_err_status &= ~ERR_PATH_EMPTY
		_errors[ERR_PATH_EMPTY_IDX].hide()
		var exists: bool = false

		if path.get_extension().is_empty():
			exists = DirAccess.dir_exists_absolute(path)
		else:
			exists = FileAccess.file_exists(path)

		if exists:
			_err_status &= ~ERR_PATH_NOT_FOUND
			_errors[ERR_PATH_NOT_FOUND_IDX].hide()

			match _type.selected:
				Collection.CollectionType.FILES:
					__set_files_incorrect_path(path)
				Collection.CollectionType.STRING_DICTIONARY:
					__set_dictionary_incorrect_path(path, true)
				Collection.CollectionType.INT_DICTIONARY:
					__set_dictionary_incorrect_path(path, false)
				Collection.CollectionType.ARRAY:
					__set_array_incorrect_path(path)
				Collection.CollectionType.CONFIG:
					__set_config_incorrect_path(path)
		else:
			_err_status |= ERR_PATH_NOT_FOUND
			_errors[ERR_PATH_NOT_FOUND_IDX].show()
			_err_status &= ~ERR_PATH_INCORRECT
			_errors[ERR_PATH_INCORRECT_IDX].hide()

	get_ok_button().disabled = _err_status != OK
	size.y = 0


func __set_files_incorrect_path(path: String) -> void:
	if path.get_extension().is_empty():
		_err_status &= ~ERR_PATH_INCORRECT
		_errors[ERR_PATH_INCORRECT_IDX].hide()
	else:
		_err_status |= ERR_PATH_INCORRECT
		_errors[ERR_PATH_INCORRECT_IDX].show()


func __set_dictionary_incorrect_path(path: String, is_type_string: bool) -> void:
	var incorrect: bool = true

	if ResourceLoader.exists(path):
		var res: Resource = ResourceLoader.load(path)

		if is_type_string:
			if res is CollectionStringDict:
				incorrect = false
		elif res is CollectionIntDict:
				incorrect = false

	if incorrect:
		_err_status |= ERR_PATH_INCORRECT
		_errors[ERR_PATH_INCORRECT_IDX].show()
	else:
		_err_status &= ~ERR_PATH_INCORRECT
		_errors[ERR_PATH_INCORRECT_IDX].hide()


func __set_array_incorrect_path(path: String) -> void:
	var incorrect: bool = true

	if ResourceLoader.exists(path):
		var res: Resource = ResourceLoader.load(path)

		if res is CollectionArray:
			incorrect = false

	if incorrect:
		_err_status |= ERR_PATH_INCORRECT
		_errors[ERR_PATH_INCORRECT_IDX].show()
	else:
		_err_status &= ~ERR_PATH_INCORRECT
		_errors[ERR_PATH_INCORRECT_IDX].hide()


func __set_config_incorrect_path(path: String) -> void:
	var config: ConfigFile = ConfigFile.new()

	if config.load(path) == OK:
		_err_status &= ~ERR_PATH_INCORRECT
		_errors[ERR_PATH_INCORRECT_IDX].hide()
	else:
		_err_status |= ERR_PATH_INCORRECT
		_errors[ERR_PATH_INCORRECT_IDX].show()


# =============================================================
# ========= Signal Callbacks ==================================


func _on_path_confirmed() -> void:
	file_dialog.canceled.disconnect(_on_file_dialog_canceled)
	set_exclusive.call_deferred(true)
	var path: String = file_dialog.current_path
	%PathEdit.text = path
	__check_path(path)


func _on_script_confirmed() -> void:
	file_dialog.canceled.disconnect(_on_file_dialog_canceled)
	set_exclusive.call_deferred(true)
	_script = load(file_dialog.current_path)
	_err_status &= ~ERR_SCRIPT_EMPTY
	_errors[ERR_SCRIPT_EMPTY_IDX].hide()

	if _script.get_instance_base_type() == "Resource":
		_err_status &= ~ERR_SCRIPT_WRONG
		_errors[ERR_SCRIPT_WRONG_IDX].hide()
		var script_name: String = _script.get_global_name()

		if script_name.is_empty():
			script_name = file_dialog.current_path.get_basename().get_file().to_pascal_case()

		%ScriptEdit.text = script_name
	else:
		_err_status |= ERR_SCRIPT_WRONG
		_errors[ERR_SCRIPT_WRONG_IDX].show()
		%ScriptEdit.text = "[Incorrect Script]"

	set_exclusive.call_deferred(true)
	get_ok_button().disabled = _err_status != OK
	size.y = 0


func _on_file_dialog_canceled() -> void:
	if file_dialog.confirmed.is_connected(_on_path_confirmed):
		file_dialog.confirmed.disconnect(_on_path_confirmed)

	if file_dialog.confirmed.is_connected(_on_script_confirmed):
		file_dialog.confirmed.disconnect(_on_script_confirmed)

		if %ScriptEdit.text.is_empty():
			_err_status |= ERR_SCRIPT_EMPTY
			_errors[ERR_SCRIPT_EMPTY_IDX].show()
		else:
			_err_status &= ~ERR_SCRIPT_EMPTY
			_errors[ERR_SCRIPT_EMPTY_IDX].hide()

	set_exclusive.call_deferred(true)
	get_ok_button().disabled = _err_status != OK
	size.y = 0


func _on_name_edit_text_submitted(new_text: String) -> void:
	if new_text.is_empty():
		_err_status |= ERR_NAME_EMPTY
		_errors[ERR_NAME_EMPTY_IDX].show()
	else:
		_err_status &= ~ERR_NAME_EMPTY
		_errors[ERR_NAME_EMPTY_IDX].hide()

	get_ok_button().disabled = _err_status != OK
	size.y = 0


func _on_name_edit_focus_exited() -> void:
	_on_name_edit_text_submitted(%NameEdit.text)


func _on_path_edit_text_submitted(new_text: String) -> void:
	__check_path(new_text)


func _on_path_edit_focus_exited() -> void:
	__check_path(%PathEdit.text)


func _on_path_browse_button_pressed() -> void:
	var current: String = %PathEdit.text

	if _type.selected == Collection.CollectionType.FILES:
		file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_DIR
		file_dialog.current_file = ""

		if current.get_extension().is_empty() and DirAccess.dir_exists_absolute(current):
			file_dialog.current_dir = current
		else:
			file_dialog.current_dir = ""
	else:
		file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE

		if _type.selected == Collection.CollectionType.CONFIG:
			file_dialog.filters = ["*.cfg,*.ini;Config File;text/plain"]
		else:
			file_dialog.filters = ["*.tres,*.res;Resource;text/plain"]

		if current.get_extension().is_empty():
			file_dialog.current_dir = current
			file_dialog.current_file = ""
		else:
			file_dialog.current_dir = ""
			file_dialog.current_file = current

	exclusive = false
	Err.conn(file_dialog.confirmed, _on_path_confirmed, CONNECT_ONE_SHOT, _ADDON)
	Err.conn(file_dialog.canceled, _on_file_dialog_canceled, CONNECT_ONE_SHOT, _ADDON)
	file_dialog.popup_centered()


func _on_script_browse_button_pressed() -> void:
	file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	file_dialog.filters = ["*.gd;GDScript;text/plain"]
	exclusive = false
	Err.conn(file_dialog.confirmed, _on_script_confirmed, CONNECT_ONE_SHOT, _ADDON)
	Err.conn(file_dialog.canceled, _on_file_dialog_canceled, CONNECT_ONE_SHOT, _ADDON)
	file_dialog.popup_centered()


func _on_type_option_item_selected(index: int) -> void:
	if index == Collection.CollectionType.CONFIG:
		%ScriptEdit.clear()
		%ScriptBrowseButton.disabled = true
	else:
		%ScriptBrowseButton.disabled = false

	if _type_selected:
		var path_incorrect_shown: bool = _errors[ERR_PATH_INCORRECT_IDX].visible
		__check_path(%PathEdit.text)

		if not path_incorrect_shown:
			_errors[ERR_PATH_INCORRECT_IDX].hide()
	else:
		_type_selected = true
