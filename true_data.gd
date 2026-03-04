@tool
extends EditorPlugin

const SETTINGS_PREFIX: String = "addons/true_data/"
const ADDON_PATH := "res://addons/true_data/"
const DEFAULT_DATA_PATH: String = "data.gd"
const DATA_NAME: String = "Data"

var _active: bool = false
var _data_path: String

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

	_data_path = ProjectSettings.get_setting(SETTINGS_PREFIX + "data_script_path")
	add_autoload_singleton(DATA_NAME, _data_path)

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


func _exit_tree() -> void:
	if not _active:
		return

	remove_autoload_singleton(DATA_NAME)
	ProjectSettings.clear(SETTINGS_PREFIX + "data_script_path")
	ProjectSettings.clear(SETTINGS_PREFIX + "collections_resource_path")
