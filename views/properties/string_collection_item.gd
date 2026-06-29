@tool
extends VBoxContainer

const Collection: GDScript = preload("res://addons/true_data/classes/collection.gd")

# =============================================================
# ========= Public Functions ==================================


func set_property(collection: Collection, property: StringName) -> void:
	var files: PackedStringArray = ResourceLoader.list_directory(collection.path)

	for file in files:
		var ext: String = file.get_extension()

		if ext == "tres" or ext == "res":
			pass



# =============================================================
# ========= Built-in Functions ================================

# =============================================================
# ========= Virtual Methods ===================================

# =============================================================
# ========= Private Functions =================================

# =============================================================
# ========= Signal Callbacks ==================================
