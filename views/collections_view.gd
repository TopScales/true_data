##
##
@tool
extends ScrollContainer

const SETTINGS_PREFIX: String = "addons/true_data/"
const Collections: GDScript = preload("res://addons/true_data/classes/collections.gd")

@onready var _configuration: ConfirmationDialog = $Configuration
@onready var _warning: Button = $MainContainer/NoCollectionsWarning
@onready var _num_coll_label: Label = %NumCollectionsLabel

var _collections_path: String
var _collections: Collections

# =============================================================
# ========= Public Functions ==================================

# =============================================================
# ========= Built-in Functions ================================

func _ready() -> void:
	$MainContainer/ToolsContainer/NewCollection.icon = EditorInterface.get_editor_theme().get_icon(&"ToolAddNode", &"EditorIcons")
	$MainContainer/ToolsContainer/AddCollection.icon = EditorInterface.get_editor_theme().get_icon(&"FileAccess", &"EditorIcons")
	$MainContainer/ToolsContainer/Configuration.icon = EditorInterface.get_editor_theme().get_icon(&"Tools", &"EditorIcons")
	$MainContainer/NoCollectionsWarning.icon = EditorInterface.get_editor_theme().get_icon(&"NodeWarning", &"EditorIcons")
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
		_warning.show()
		_num_coll_label.text = "Collections: 0"
	else:
		_warning.hide()
		_collections = ResourceLoader.load(path)
		_collections_path = path
		_num_coll_label.text = "Collections: %d" % _collections.size()


# =============================================================
# ========= Signal Callbacks ==================================


func _on_configuration_pressed() -> void:
	_configuration.show_dialog()


func _on_configuration_confirmed() -> void:
	__load_collections()


func _on_no_collections_warning_pressed() -> void:
	_configuration.show_dialog()


func _on_add_collection_pressed() -> void:
	pass # Replace with function body.


func _on_new_collection_pressed() -> void:
	pass # Replace with function body.
