##
##
@tool
extends HBoxContainer

# =============================================================
# ========= Public Functions ==================================

# =============================================================
# ========= Built-in Functions ================================

func _ready() -> void:
	$LocationContainer/LocationBrowseButton.icon = EditorInterface.get_editor_theme().get_icon(&"FolderBrowse", &"EditorIcons")
	$DeleteButton.icon = EditorInterface.get_editor_theme().get_icon(&"Remove", &"EditorIcons")
	var types: OptionButton = $TypeOption
	types.set_item_icon(0, EditorInterface.get_editor_theme().get_icon(&"FileList", &"EditorIcons"))
	types.set_item_icon(1, EditorInterface.get_editor_theme().get_icon(&"Dictionary", &"EditorIcons"))
	types.set_item_icon(2, EditorInterface.get_editor_theme().get_icon(&"Array", &"EditorIcons"))
	types.set_item_icon(3, EditorInterface.get_editor_theme().get_icon(&"GDScript", &"EditorIcons"))
	$LoadCheck.icon = EditorInterface.get_editor_theme().get_icon(&"GuiChecked", &"EditorIcons")

# =============================================================
# ========= Virtual Methods ===================================

# =============================================================
# ========= Private Functions =================================

# =============================================================
# ========= Signal Callbacks ==================================
