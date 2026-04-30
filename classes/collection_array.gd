##
##
@tool
class_name CollectionArray
extends Resource

@export var arr: Array[Resource]:
	set(value):
		arr = value
		emit_changed()

# =============================================================
# ========= Public Functions ==================================

func size() -> int:
	return arr.size()


#func move_item(from: int, to: int) -> void:
	#if from >= arr.size() or to >= arr.size() or from < 0 or to < 0:
		#return
		#
	#var item: Resource = arr[from]
	#
	#for i in range(mini(from, to), maxi(from, to)):
		#if i == to:
			#arr[i] = item
		#else:
			#pass


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
