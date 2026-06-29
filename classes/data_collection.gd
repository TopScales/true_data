##
##
@tool
@abstract
extends Resource

@export var items_script: GDScript

# =============================================================
# ========= Public Functions ==================================

# =============================================================
# ========= Built-in Functions ================================

# =============================================================
# ========= Virtual Methods ===================================

# =============================================================
# ========= Private Functions =================================


func __transfer_item_data(from: Resource, to: Resource) -> void:
	if from.script and to.script:
		var usage: int = PROPERTY_USAGE_SCRIPT_VARIABLE | PROPERTY_USAGE_STORAGE
		var props_from: Array[Dictionary] = Data.get_script_properties_info(from.script, usage)
		var props_to: Array[Dictionary] = Data.get_script_properties_info(to.script, usage)

		for i in props_from.size():
			var prop_from: Dictionary = props_from[i]
			var type: int = prop_from["type"]
			var prop_name: String = prop_from["name"]

			for j in props_to.size():
				var prop_to: Dictionary = props_to[j]

				if prop_to["name"] == prop_name:
					if prop_to["type"] == type:
						to.set(prop_name, from.get(prop_name))
					break


# =============================================================
# ========= Signal Callbacks ==================================
