##
##
@tool
class_name DataCollectionArray
extends "res://addons/true_data/classes/data_collection.gd"

@export var arr: Array[Resource]:
	set(value):
		arr = value

		if items_script:
			for i in arr.size():
				var item: Resource = arr[i]

				if item == null:
					arr[i] = items_script.new()
				elif item.script != items_script:
					var new_item: Resource = items_script.new()
					__transfer_item_data(item, new_item)
					arr[i] = new_item

		emit_changed()

# =============================================================
# ========= Public Functions ==================================

func size() -> int:
	return arr.size()


func move_item(from: int, to: int) -> void:
	if from >= arr.size() or to >= arr.size() or from < 0 or to < 0:
		return

	var item: Resource = arr.pop_at(from)
	Err.try_insert(arr.insert(to, item))


func add_item(item: Resource) -> void:
	arr.push_back(item)


func remove_item(item: Resource) -> void:
	arr.erase(item)


# =============================================================
# ========= Built-in Functions ================================

# =============================================================
# ========= Virtual Methods ===================================

# =============================================================
# ========= Private Functions =================================

# =============================================================
# ========= Signal Callbacks ==================================
