##
##
@tool
extends Node

const IGNORE_USAGE: int = -1
const INCLUDE_ALL_LEVELS: int = -1
const INVALID_ASSET: int = -1
const _SETTINGS_PREFIX: String = "addons/true_data/"
const _MOD: StringName = &"Data"

const Collection: GDScript = preload("res://addons/true_data/classes/collection.gd")

var _collections: DataCollections
var _collections_array: Dictionary[StringName, DataCollectionArray]

# =============================================================
# ========= Public Functions ==================================


func get_script_properties_info(
	script_: Script,
	usage: int = IGNORE_USAGE,
	filter_list: PackedStringArray = [],
	is_blacklist: bool = false,
	script_levels: int = INCLUDE_ALL_LEVELS
) -> Array[Dictionary]:
	var props: Array[Dictionary] = []
	var use_whitelist: bool = not is_blacklist and not filter_list.is_empty()
	var use_blacklist: bool = is_blacklist and not filter_list.is_empty()
	var levels: int = 1
	var all_props: Array[Dictionary] = script_.get_script_property_list()
	script_ = script_.get_base_script()

	while script_ and (levels < script_levels or script_levels == INCLUDE_ALL_LEVELS):
		var p: Array[Dictionary] = script_.get_script_property_list()
		all_props.append_array(p)
		levels += 1

	__select_properties(all_props, usage, filter_list, use_whitelist, use_blacklist, props)
	return props


func get_obj_properties_info(
	obj: Object,
	usage: int = IGNORE_USAGE,
	filter_list: PackedStringArray = [],
	is_blacklist: bool = false,
	core_levels: int = INCLUDE_ALL_LEVELS,
	script_levels: int = INCLUDE_ALL_LEVELS
) -> Array[Dictionary]:
	var props: Array[Dictionary] = []
	var use_whitelist: bool = not is_blacklist and not filter_list.is_empty()
	var use_blacklist: bool = is_blacklist and not filter_list.is_empty()

	if core_levels == INCLUDE_ALL_LEVELS and script_levels == INCLUDE_ALL_LEVELS:
		var all_props: Array[Dictionary] = obj.get_property_list()
		__select_properties(all_props, usage, filter_list, use_whitelist, use_blacklist, props)
	else:
		if script_levels > 0:
			var script: Script = obj.get_script()

			if script:
				var all_script_props: Array[Dictionary] = script.get_script_property_list()
				var script_props: Array[Dictionary] = []
				__select_properties(all_script_props, usage, filter_list, use_whitelist, use_blacklist, script_props)
				script = script.get_base_script()
				var level: int = 1
				var assigned: bool = false

				while script:
					if level >= script_levels:
						var parent_script_props: Array[Dictionary] = script.get_script_property_list()
						var selected_props: PackedInt32Array = []

						for iprop in script_props.size():
							var prop: Dictionary = script_props[iprop]
							var prop_name: String = prop["name"]
							var parent_props_size: int = parent_script_props.size()
							var include: bool = true

							for ipprop in parent_props_size:
								var pprop: Dictionary = parent_script_props[ipprop]

								if pprop["name"] == prop_name:
									var new_size: int = parent_props_size - 1
									parent_script_props[ipprop] = parent_script_props[new_size]
									Err.try_resize(parent_script_props.resize(new_size), "Data")
									include = false
									break

							if include:
								Err.try_append(selected_props.push_back(iprop), "Data")

						Err.try_resize(props.resize(selected_props.size()), "Data")
						assigned = true

						for i in selected_props.size():
							props[i] = script_props[selected_props[i]]

						break

					script = script.get_base_script()
					level += 1

				if not assigned:
					props = script_props

		if core_levels > 0:
			var obj_class: StringName = obj.get_class()

			for i in core_levels:
				var class_props: Array[Dictionary] = ClassDB.class_get_property_list(obj_class, true)
				props.append_array(class_props)
				obj_class = ClassDB.get_parent_class(obj_class)

	return props


func bulk_load() -> void:
	pass


func bulk_load_threaded() -> void:
	pass


func get_obj_name(obj: Object) -> String:
	if obj is Node:
		return (obj as Node).name
	elif obj is Resource:
		var res: Resource = obj as Resource
		return res.resource_name if not res.resource_name.is_empty() else res.to_string()
	else:
		return obj.to_string()


func get_collection_item(collection: StringName, item: int) -> Resource:
	if item != INVALID_ASSET:
		var col: DataCollectionArray = _collections_array.get(collection)

		if col:
			if item < 0 or item >= col.size():
				Log.error("Collection item index out of bounds.", _MOD)
			else:
				return col.arr[item]
		else:
			Log.warning("Collection '%s' not found." % collection)

	return null


# =============================================================
# ========= Built-in Functions ================================

func _ready() -> void:
	var path: String = ProjectSettings.get_setting(_SETTINGS_PREFIX + "collections_resource_path", "")

	if not path.is_empty() and ResourceLoader.exists(path):
		_collections = ResourceLoader.load(path) as DataCollections


# =============================================================
# ========= Virtual Methods ===================================

# =============================================================
# ========= Private Functions =================================


static func __select_properties(
	props_list: Array[Dictionary],
	usage: int,
	filter: PackedStringArray,
	use_whitelist: bool,
	use_blacklist: bool,
	props_out: Array[Dictionary]
) -> void:
	for prop in props_list:
		var prop_name: String = prop["name"]

		if usage != IGNORE_USAGE and (prop["usage"] & usage) != usage:
			continue

		if (not use_whitelist or use_whitelist and prop_name in filter) and not (use_blacklist and prop_name in filter):
			props_out.push_back(prop)


func __load_array_collection(collection: Collection) -> void:
	if ResourceLoader.exists(collection.path):
		var col: DataCollectionArray = ResourceLoader.load(collection.path)

		if not col.resource_name.is_empty():
			_collections_array[StringName(col.resource_name)] = col

# =============================================================
# ========= Signal Callbacks ==================================
