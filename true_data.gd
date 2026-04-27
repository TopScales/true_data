@tool
extends EditorPlugin

const SETTINGS_PREFIX: String = "addons/true_data/"
const ADDON_PATH := "res://addons/true_data/"
const DEFAULT_DATA_PATH: String = "data.gd"
const DATA_NAME: String = "Data"

var _active: bool = false
var _data_path: String
var _data_ctrl: Control

func _enter_tree() -> void:
	if not EditorInterface.is_plugin_enabled("logerr"):
		printerr("Missing LogErr addon.")
		_active = false
		return

	# Get Data singleton script from path in project settings.
	if not ProjectSettings.has_setting(SETTINGS_PREFIX + "data_script_path"):
		ProjectSettings.set_setting(SETTINGS_PREFIX + "data_script_path",
			ADDON_PATH + DEFAULT_DATA_PATH)
	ProjectSettings.add_property_info({
		name = SETTINGS_PREFIX + "data_script_path",
		type = TYPE_STRING,
		hint = PROPERTY_HINT_FILE,
		hint_string = "*.gd"
	})
	ProjectSettings.set_initial_value(SETTINGS_PREFIX + "data_script_path", ADDON_PATH + DEFAULT_DATA_PATH)

	# Add Data autoload.
	_data_path = ProjectSettings.get_setting(SETTINGS_PREFIX + "data_script_path")

	if _data_path.begins_with("uid://"):
		_data_path = ResourceUID.uid_to_path(_data_path)

	add_autoload_singleton(DATA_NAME, _data_path)

	# Specify the collections resource file to be used to save and display all game data.
	if not ProjectSettings.has_setting(SETTINGS_PREFIX + "collections_resource_path"):
		ProjectSettings.set_setting(SETTINGS_PREFIX + "collections_resource_path", "")
	ProjectSettings.add_property_info(
		{
			"name" = SETTINGS_PREFIX + "collections_resource_path",
			"type" = TYPE_STRING,
			"hint" = PROPERTY_HINT_FILE
		}
	)
	ProjectSettings.set_initial_value(SETTINGS_PREFIX + "collections_resource_path", "")

	# Add data main screen.
	_data_ctrl = preload("views/data_screen.tscn").instantiate()
	EditorInterface.get_editor_main_screen().add_child(_data_ctrl)
	_data_ctrl.hide()
	_data_ctrl.undoredo = get_undo_redo()


func _exit_tree() -> void:
	if not _active:
		return

	remove_autoload_singleton(DATA_NAME)
	ProjectSettings.clear(SETTINGS_PREFIX + "data_script_path")
	ProjectSettings.clear(SETTINGS_PREFIX + "collections_resource_path")
	_data_ctrl.queue_free()


func _make_visible(visible: bool) -> void:
	_data_ctrl.visible = visible


func _has_main_screen() -> bool:
	return true


func _get_plugin_name() -> String:
	return "Data"


func _get_plugin_icon() -> Texture2D:
	return EditorInterface.get_editor_theme().get_icon(&"ResourcePreloader", &"EditorIcons")
