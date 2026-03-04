##
##
class_name ResourceStringDict
extends Resource

@export var dict: Dictionary[StringName, Resource]

# =============================================================
# ========= Public Functions ==================================

func size() -> int:
	return dict.size()

# =============================================================
# ========= Built-in Functions ================================

func _set(property: StringName, value: Variant) -> bool:
	if dict.has(property):
		assert(value is Resource)
		dict[property] = value
		return true
	return false


func _get(property: StringName) -> Variant:
	if dict.has(property):
		return dict[property]
	return null

# =============================================================
# ========= Virtual Methods ===================================

# =============================================================
# ========= Private Functions =================================

# =============================================================
# ========= Signal Callbacks ==================================
