##
##
@tool
class_name CollectionStringDict
extends Resource

@export var dict: Dictionary[StringName, Resource]

# =============================================================
# ========= Public Functions ==================================

func size() -> int:
	return dict.size()


func move_entry(from: StringName, to: StringName) -> void:
	var res: Resource = dict.get(from)

	if res:
		Err.try_erase(dict.erase(from))
		dict[to] = res


func add_entry(entry: StringName, resource: Resource) -> void:
	dict[entry] = resource


func remove_entry(entry: StringName) -> void:
	Err.try_erase(dict.erase(entry))


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
