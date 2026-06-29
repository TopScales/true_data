##
##
@tool
class_name DataCollectionStringDict
extends "res://addons/true_data/classes/data_collection.gd"

@export var dict: Dictionary[StringName, Resource]:
	set(value):
		dict = value

		if items_script:
			for key in dict.keys():
				var item: Resource = dict[key]
#
				if item == null:
					dict[key] = items_script.new()
				elif item.script != items_script:
					var new_item: Resource = items_script.new()
					__transfer_item_data(item, new_item)
					dict[key] = new_item

		emit_changed()

# =============================================================
# ========= Public Functions ==================================

func size() -> int:
	return dict.size()


func move_item(from: StringName, to: StringName) -> void:
	var res: Resource = dict.get(from)

	if res:
		Err.try_erase(dict.erase(from))
		dict[to] = res


func add_item(item: StringName, resource: Resource) -> void:
	dict[item] = resource


func remove_item(item: StringName) -> void:
	Err.try_erase(dict.erase(item))


func has_item(item: StringName) -> bool:
	return dict.has(item)


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
