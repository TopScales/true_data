##
##
@tool
extends ConfirmationDialog

const SETTINGS_PREFIX: String = "addons/true_data/"

const CONFIG_OK: int = 0
const CONFIG_NO_FILE: int = 1
const CONFIG_BAD_FILE: int = 2

const EXTENSION_TRES: int = 0
const EXTENSION_RES: int = 1
const DEFAULT_FILE_NAME: String = "collections"
const _ADDON: StringName = &"TrueData"

var file_dialog: EditorFileDialog

var _config_status: int = CONFIG_OK
var _create_new_file: bool = false
var _collections_exist: bool = false

@onready var _path_edit: LineEdit = %PathEdit

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

	if path.is_empty():
		_config_status = CONFIG_NO_FILE
	elif not FileAccess.file_exists(path):
		_config_status = CONFIG_BAD_FILE
	else:
		_collections_exist = true
		_config_status = CONFIG_OK

	_path_edit.text = path
	get_ok_button().disabled = _config_status != CONFIG_OK
	__show_messages()
	popup_centered()

# =============================================================
# ========= Built-in Functions ================================

func _ready() -> void:
	for child in $BoxContainer/DataCollections/ResourcePicker.get_children(true):
		print(child)
	#var resource_picker: EditorResourcePicker = EditorResourcePicker.new()
	#resource_picker.base_type = "Shape3D"
	#$BoxContainer/DataCollections.add_child(resource_picker)
	#resource_picker.owner = self


func _notification(what: int) -> void:
	if what == NOTIFICATION_THEME_CHANGED:
		%PathBrowseButton.icon = EditorInterface.get_editor_theme().get_icon(&"FileBrowse", &"EditorIcons")
		%PathNewButton.icon = EditorInterface.get_editor_theme().get_icon(&"New", &"EditorIcons")
		%NoCollectionLabel.add_theme_color_override("font_color", EditorInterface.get_editor_theme().get_color(&"warning_color", &"Editor"))
		%CollectionCreatedLabel.add_theme_color_override("font_color", EditorInterface.get_editor_theme().get_color(&"success_color", &"Editor"))
		%InvalidPathLabel.add_theme_color_override("font_color", EditorInterface.get_editor_theme().get_color(&"error_color", &"Editor"))


# =============================================================
# ========= Virtual Methods ===================================

# =============================================================
# ========= Private Functions =================================


func __show_messages() -> void:
	%NoCollectionLabel.visible = _config_status == CONFIG_NO_FILE
	%InvalidPathLabel.visible = _config_status == CONFIG_BAD_FILE
	%CollectionCreatedLabel.visible = _create_new_file && _config_status == CONFIG_OK


# =============================================================
# ========= Signal Callbacks ==================================

func _on_collections_file_selected(path: String) -> void:
	_path_edit.text = path
	file_dialog.canceled.disconnect(_on_collections_file_canceled)
	set_exclusive.call_deferred(true)
	_config_status &= ~CONFIG_BAD_FILE
	get_ok_button().disabled = _config_status != CONFIG_OK


func _on_collections_file_canceled() -> void:
	file_dialog.file_selected.disconnect(_on_collections_file_selected)
	set_exclusive.call_deferred(true)


func _on_path_browse_button_pressed() -> void:
	exclusive = false
	file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	file_dialog.filters = ["*.tres,*.res;Resource;text/plain"]
	Err.conn(file_dialog.file_selected, _on_collections_file_selected, CONNECT_ONE_SHOT, _ADDON)
	Err.conn(file_dialog.canceled, _on_collections_file_canceled, CONNECT_ONE_SHOT, _ADDON)
	file_dialog.popup_centered()


func _on_directory_edit_text_changed(new_text: String) -> void:
	pass
	#if DirAccess.dir_exists_absolute(new_text):
		#_dir_edit.remove_theme_color_override(&"font_color")
		#_config_status &= ~CONFIG_BAD_FOLDER
	#else:
		#_dir_edit.add_theme_color_override(&"font_color", Color.RED)
		#_config_status |= CONFIG_BAD_FOLDER
#
	#get_ok_button().disabled = _config_status != CONFIG_OK


func _on_directory_browse_button_pressed() -> void:
	exclusive = false
	#file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_DIR
	#Err.conn(file_dialog.dir_selected, _on_directory_selected, CONNECT_ONE_SHOT, _ADDON)
	#Err.conn(file_dialog.canceled, _on_directory_canceled, CONNECT_ONE_SHOT, _ADDON)
	#file_dialog.popup_centered()


func _on_confirmed() -> void:
	if _config_status != CONFIG_OK:
		return

	#var dir: String = _dir_edit.text
	#var file: String = _file_edit.text
	#var path: String = dir.path_join(file + _ext_option.get_item_text(_ext_option.selected))
	#var update_filesystem: bool = not DirAccess.dir_exists_absolute(dir)
#
	#if not ResourceLoader.exists(path, "Resource"):
		#var collection: DataCollectionArray = DataCollectionArray.new()
		#Err.try_err(ResourceSaver.save(collection, path), "Failed to save collections resource.", _ADDON)
#
	#ProjectSettings.set_setting(SETTINGS_PREFIX + "collections_resource_path", ResourceUID.path_to_uid(path))
	#Err.try_err(ProjectSettings.save(), "Failed to save Project Settings.", _ADDON)


func _on_file_edit_text_submitted(new_text: String) -> void:
	if not new_text.is_valid_filename():
		return

	#var ext: String = new_text.get_extension()
#
	#if ext == "tres":
		#var file: String = new_text.trim_suffix(".tres")
		#_file_edit.text = file
		#_ext_option.select(EXTENSION_TRES)
	#elif ext == "res":
		#var file: String = new_text.trim_suffix(".res")
		#_file_edit.text = file
		#_ext_option.select(EXTENSION_RES)
#
#
#func _on_file_edit_text_changed(new_text: String) -> void:
	#if new_text.is_valid_filename():
		#_file_edit.remove_theme_color_override(&"font_color")
		#_config_status &= ~CONFIG_BAD_FILE
	#else:
		#_file_edit.add_theme_color_override(&"font_color", Color.RED)
		#_config_status |= CONFIG_BAD_FILE


func _on_path_edit_text_changed(new_text: String) -> void:
	if _create_new_file:
		if new_text.is_valid_filename():
			var ext: String = new_text.get_extension()

			if ext in ["tres", "res"]:
				_config_status = CONFIG_OK
			else:
				_config_status = CONFIG_BAD_FILE
		else:
			_config_status = CONFIG_BAD_FILE
	elif new_text.is_empty():
		if _collections_exist:
			_config_status = CONFIG_BAD_FILE
		else:
			_config_status = CONFIG_NO_FILE
	elif not FileAccess.file_exists(new_text):
		_config_status = CONFIG_BAD_FILE
	else:
		_config_status = CONFIG_OK

	__show_messages()


func _on_new_collections_pressed() -> void:
	pass # Replace with function body.


func _on_resource_picker_mouse_entered() -> void:
	print("Entered")
	exclusive = false


func _on_resource_picker_mouse_exited() -> void:
	print("Exited!!")
	exclusive = true
