##
##
@tool
extends VBoxContainer

class Property:
	var prop_name: StringName
	var type: int
	var style: int
	var style_specs: Dictionary[StringName, Variant]

const Collection: GDScript = preload("res://addons/true_data/views/collection.gd")
const Header: GDScript = preload("res://addons/true_data/views/header.gd")

const HEADER_SCENE: PackedScene = preload("res://addons/true_data/views/header.tscn")

const INT_SPIN: int = 0
const INT_ENUM: int = 1
const FLOAT_SPIN: int = 0
const STRING_PLAIN: int = 0
const STRING_ENUM: int = 1

var _collection_name: StringName
var _collection: Collection
var _props: Array[Property]

@onready var _headers: Control = $Headers

# =============================================================
# ========= Public Functions ==================================


func set_collection(collection_name: StringName, collection: Collection) -> void:
	_collection_name = collection_name
	_collection = collection
	$CollectionLabel.text = collection_name
	%NumEntriesLabel.text = "Entries: %d" % _collection.entries
	__add_headers()

# =============================================================
# ========= Built-in Functions ================================

func _ready() -> void:
	$Back.icon = EditorInterface.get_editor_theme().get_icon(&"ArrowLeft", &"EditorIcons")

# =============================================================
# ========= Virtual Methods ===================================

# =============================================================
# ========= Private Functions =================================

func __add_headers() -> void:
	var obj: Resource = _collection.collection_script.new()
	var usage: int = PROPERTY_USAGE_DEFAULT | PROPERTY_USAGE_SCRIPT_VARIABLE
	var props: Array[Dictionary] = Data.get_properties_info(obj, usage)

	for p in props:
		var prop: Property = Property.new()
		prop.prop_name = p["name"]
		prop.type = p["type"]
		__set_prop_style(prop, p["hint"], p["hint_string"])
		_props.push_back(prop)
		var header: Header = HEADER_SCENE.instantiate()
		_headers.add_child(header)
		header.set_property(prop.prop_name, true)


func __set_prop_style(prop: Property, hint: int, hint_string: String) -> void:
	if prop.type == TYPE_INT:
		if hint == PROPERTY_HINT_RANGE:
			prop.style = INT_SPIN
			prop.style_specs = __get_range_specs(hint_string)
		elif hint == PROPERTY_HINT_ENUM:
			prop.style = INT_ENUM
			prop.style_specs = __get_enum_specs(hint_string)
		else:
			prop.style = INT_SPIN
	elif prop.type == TYPE_FLOAT:
		prop.style = FLOAT_SPIN

		if hint == PROPERTY_HINT_RANGE:
			prop.style_specs = __get_range_specs(hint_string)
	elif prop.type == TYPE_STRING:
		if hint == PROPERTY_HINT_ENUM:
			prop.style = STRING_ENUM
			prop.style_specs = __get_enum_specs(hint_string)
		else:
			prop.style = STRING_PLAIN


func __add_entries() -> void:
	if _collection.type == Collection.CollectionType.FILES:
		__add_file_entries()


func __add_file_entries() -> void:
	var list: PackedStringArray = ResourceLoader.list_directory(_collection.path)

	for file in list:
		if file.get_extension() in ["tres", "res"]:
			var res: Resource = ResourceLoader.load(_collection.path.path_join(file))
			__add_row(res)


func __add_row(res: Resource) -> void:
	var row: HBoxContainer = HBoxContainer.new()
	add_child(row)

	for prop in _props:
		var value: Variant = res.get(prop.prop_name)
		var cell: Control = __get_property_cell(prop, value)
		row.add_child(cell)


func __get_property_cell(prop: Property, value: Variant) -> Control:
	match prop.type:
		TYPE_INT:
			return __get_int_cell(prop, value)
	return null


func __get_int_cell(prop: Property, value: int) -> Control:
	if prop.style == INT_SPIN:
		var cell: EditorSpinSlider = EditorSpinSlider.new()
		cell.value = value
		cell.step = prop.style_specs.get(&"step", 1)
		cell.max_value = prop.style_specs.get(&"max_value", 100)
		cell.min_value = prop.style_specs.get(&"min_value", 0)
		cell.allow_greater = prop.style_specs.get(&"allow_greater", true)
		cell.allow_lesser = prop.style_specs.get(&"allow_lesser", true)
		cell.suffix = prop.style_specs.get(&"suffix", "")
		cell.editing_integer = true
		return cell
	elif prop.style == INT_ENUM:
		var cell: OptionButton = OptionButton.new()
		var ids: PackedInt32Array = prop.style_specs.get(&"ids", [])
		var labels: PackedStringArray = prop.style_specs.get(&"labels", [])

		for i in labels.size():
			var id: int = ids[i]
			var label: String = labels[i]
			cell.add_item(label, id)

		cell.select(cell.get_item_index(value))
		return cell
	return null


func __get_float_cell(prop: Property, value: int) -> Control:
	if prop.style == FLOAT_SPIN:
		var cell: EditorSpinSlider = EditorSpinSlider.new()
		cell.value = value
		cell.step = prop.style_specs.get(&"step", 1)
		cell.max_value = prop.style_specs.get(&"max_value", 100)
		cell.min_value = prop.style_specs.get(&"min_value", 0)
		cell.allow_greater = prop.style_specs.get(&"allow_greater", true)
		cell.allow_lesser = prop.style_specs.get(&"allow_lesser", true)
		cell.suffix = prop.style_specs.get(&"suffix", "")
		cell.editing_integer = false
		cell.exp_edit = prop.style_specs.get(&"exp", false)
		return cell
	return null


func __get_range_specs(hint_string: String) -> Dictionary[StringName, Variant]:
	var parts: PackedStringArray = hint_string.split(",")
	var specs: Dictionary[StringName, Variant]
	specs[&"min_value"] = parts[0]
	specs[&"max_value"] = parts[1]
	specs[&"allow_greater"] = false
	specs[&"allow_lesser"] = false

	if parts.size() > 2:
		specs[&"step"] = parts[2]

		for i in range(3, parts.size()):
			match parts[i]:
				"or_greater":
					specs[&"allow_greater"] = true
				"or_less":
					specs[&"allow_lesser"] = true
				"exp":
					specs[&"exp"] = true
				"radians_as_degrees":
					specs[&"radians_as_degrees"] = true
				"degrees":
					specs[&"degrees"] = true
				"prefer_slider":
					specs[&"prefer_slider"] = true
				"hide_control":
					specs[&"hide_control"] = true
				_:
					if parts[i].begins_with("suffix"):
						specs[&"suffix"] = parts[i].split(":")[1]

	return specs


func __get_enum_specs(hint_string: String) -> Dictionary[StringName, Variant]:
	var parts: PackedStringArray = hint_string.split(",")
	var ids: PackedInt32Array
	var labels: PackedStringArray
	Err.try_resize(ids.resize(parts.size()))
	Err.try_resize(labels.resize(parts.size()))
	var id: int = 0

	for i in parts.size():
		var tag: String = parts[i]
		var tag_parts: PackedStringArray = tag.split(":")
		labels[i] = tag_parts[0]

		if tag_parts.size() > 1:
			id = int(tag_parts[1])
		else:
			id += 1

		ids[i] = id

	return { &"ids": ids, &"labels": labels }

# =============================================================
# ========= Signal Callbacks ==================================
