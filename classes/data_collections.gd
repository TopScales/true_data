##
##
@tool
class_name DataCollections
extends DataCollectionStringDict

const Collection: GDScript = preload("res://addons/true_data/classes/collection.gd")

# =============================================================
# ========= Public Functions ==================================


func get_collection_count(bulk_only: bool = false) -> int:
	var count: int = 0

	for key in dict.keys():
		var collection: Collection = dict[key]

		if not bulk_only or collection.bulk_load:
			count += collection.entries

	return count


func get_collection_item(collection: StringName, item: Variant) -> Resource:
	return null


# =============================================================
# ========= Built-in Functions ================================


func _init() -> void:
	items_script = Collection


# =============================================================
# ========= Virtual Methods ===================================

# =============================================================
# ========= Private Functions =================================

# =============================================================
# ========= Signal Callbacks ==================================
