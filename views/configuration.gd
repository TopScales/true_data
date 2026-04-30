##
##
@tool
extends ConfirmationDialog

const SETTINGS_PREFIX: String = "addons/true_data/"
const CONFIG_BAD_FOLDER: int = 1
const CONFIG_BAD_FILE: int = 2
const CONFIG_OK: int = 0
const EXTENSION_TRES: int = 0
const EXTENSION_RES: int = 1
const DEFAULT_FILE_NAME: String = "collections"
const _ADDON: StringName = &"TrueData"

@export var file_dialog: FileDialog

var _config_status: int = CONFIG_OK

@onready var _dir_edit: LineEdit = %DirectoryEdit
@onready var _file_edit: LineEdit = %FileEdit
@onready var _ext_option: OptionButton = %ExtensionOption

# =============================================================
# ========= Public Functions ==================================

func show_dialog() -> void:
	var path: String = ProjectSettings.get_setting(SETTINGS_PREFIX + "collections_resource_path", "")

	if path.begins_with("uid://"):
		var id: int = ResourceUID.text_to_id(path)

		if ResourceUID.has_id(id):
			path = ResourceUID.uid_to_path(path)
		else:
			path = ""

	var dir: String = path.get_base_dir()
	var file: String = path.get_file().get_basename()
	var ext: String = path.get_extension()
	_config_status = CONFIG_OK

	if file.is_empty():
		file = DEFAULT_FILE_NAME
	elif ext != "tres" and ext != "res":
		_config_status |= CONFIG_BAD_FILE

	if dir.is_empty():
		_config_status |= CONFIG_BAD_FOLDER

	_file_edit.text = file
	_dir_edit.text = dir
	get_ok_button().disabled = _config_status != CONFIG_OK
	popup_centered()

# =============================================================
# ========= Built-in Functions ================================

# =============================================================
# ========= Virtual Methods ===================================

# =============================================================
# ========= Private Functions =================================

# =============================================================
# ========= Signal Callbacks ==================================


func _on_directory_selected(dir: String) -> void:
	_dir_edit.text = dir
	file_dialog.canceled.disconnect(_on_directory_canceled)
	set_exclusive.call_deferred(true)
	_config_status &= ~CONFIG_BAD_FOLDER
	get_ok_button().disabled = _config_status != CONFIG_OK


func _on_directory_canceled() -> void:
	file_dialog.dir_selected.disconnect(_on_directory_selected)
	set_exclusive.call_deferred(true)


func _on_directory_edit_text_changed(new_text: String) -> void:
	if DirAccess.dir_exists_absolute(new_text):
		_dir_edit.remove_theme_color_override(&"font_color")
		_config_status &= ~CONFIG_BAD_FOLDER
	else:
		_dir_edit.add_theme_color_override(&"font_color", Color.RED)
		_config_status |= CONFIG_BAD_FOLDER

	get_ok_button().disabled = _config_status != CONFIG_OK


func _on_directory_browse_button_pressed() -> void:
	exclusive = false
	file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_DIR
	Err.conn(file_dialog.dir_selected, _on_directory_selected, CONNECT_ONE_SHOT, _ADDON)
	Err.conn(file_dialog.canceled, _on_directory_canceled, CONNECT_ONE_SHOT, _ADDON)
	file_dialog.popup_centered()


func _on_confirmed() -> void:
	if _config_status != CONFIG_OK:
		return

	var dir: String = _dir_edit.text
	var file: String = _file_edit.text
	var path: String = dir.path_join(file + _ext_option.get_item_text(_ext_option.selected))

	if not ResourceLoader.exists(path, "Resource"):
		var collection: CollectionArray = CollectionArray.new()
		Err.try_err(ResourceSaver.save(collection, path), "Failed to save collections resource.", _ADDON)

	ProjectSettings.set_setting(SETTINGS_PREFIX + "collections_resource_path", ResourceUID.path_to_uid(path))
	Err.try_err(ProjectSettings.save(), "Failed to save Project Settings.", _ADDON)


func _on_file_edit_text_submitted(new_text: String) -> void:
	if not new_text.is_valid_filename():
		return

	var ext: String = new_text.get_extension()

	if ext == "tres":
		var file: String = new_text.trim_suffix(".tres")
		_file_edit.text = file
		_ext_option.select(EXTENSION_TRES)
	elif ext == "res":
		var file: String = new_text.trim_suffix(".res")
		_file_edit.text = file
		_ext_option.select(EXTENSION_RES)


func _on_file_edit_text_changed(new_text: String) -> void:
	if new_text.is_valid_filename():
		_file_edit.remove_theme_color_override(&"font_color")
		_config_status &= ~CONFIG_BAD_FILE
	else:
		_file_edit.add_theme_color_override(&"font_color", Color.RED)
		_config_status |= CONFIG_BAD_FILE
