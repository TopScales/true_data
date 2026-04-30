##
##
@tool
extends VBoxContainer

enum PropertyType { SCRIPT, HIDDEN, KEY }

class Property:
	var prop_name: StringName
	var data_type: int
	var property_type: int
	var style: int
	var style_specs: Dictionary[StringName, Variant]
	var show_options: bool = true
	var alias: String = ""
# Properties can be:
# Script variable
# Hidden script variable
# Editable non-script (like file)
# Non-editable defined by func
# Expression

signal back_pressed

const Collection: GDScript = preload("res://addons/true_data/views/collection.gd")
const Header: GDScript = preload("res://addons/true_data/views/header.gd")

const HEADER_SCENE: PackedScene = preload("res://addons/true_data/views/header.tscn")

const INT_SPIN: int = 0
const INT_ENUM: int = 1
const FLOAT_SPIN: int = 0
const STRING_PLAIN: int = 0
const STRING_ENUM: int = 1

const _ADDON: StringName = &"TrueData"

var file_dialog: FileDialog
var undoredo: EditorUndoRedoManager

var _collection: Collection
var _props: Array[Property]
var _resources: Array[Resource]
var _key_prop: Property

@onready var _headers: Control = %Headers
@onready var _items: Control = %Items

# =============================================================
# ========= Public Functions ==================================

func reset() -> void:
	pass


func save_data() -> void:
	for res in _resources:
		if not res.resource_path.is_empty():
			Err.try_err(ResourceSaver.save(res, res.resource_path), "Failed to save collection item.", _ADDON)


func set_collection(collection: Collection) -> void:
	_collection = collection
	$CollectionLabel.text = collection.resource_name
	__add_headers()
	__add_items()
	%NumEntriesLabel.text = "Entries: %d" % _collection.entries

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

	match _collection.type:
		Collection.CollectionType.FILES:
			var prop: Property = Property.new()
			prop.prop_name = &"File"
			prop.data_type = TYPE_STRING
			prop.property_type = PropertyType.KEY
			prop.style = STRING_PLAIN
			prop.style_specs = {&"default_value": "New File"}
			_props.push_back(prop)
			_key_prop = prop
		Collection.CollectionType.STRING_DICTIONARY:
			var prop: Property = Property.new()
			prop.prop_name = &"Key"
			prop.data_type = TYPE_STRING
			prop.property_type = PropertyType.KEY
			prop.style = STRING_PLAIN
			prop.style_specs = {&"default_value": "New Key"}
			_props.push_back(prop)
			_key_prop = prop

	for p in props:
		var prop: Property = Property.new()
		prop.prop_name = p["name"]
		prop.data_type = p["type"]
		prop.property_type = PropertyType.SCRIPT
		__set_prop_style(prop, p["hint"], p["hint_string"])
		_props.push_back(prop)

	for p in _props:
		var header: Header = HEADER_SCENE.instantiate()
		_headers.add_child(header)
		header.set_property(p.prop_name, p.show_options)

	var delete_space: Control = Control.new()
	delete_space.custom_minimum_size.x = 32
	_headers.add_child(delete_space)


func __set_prop_style(prop: Property, hint: int, hint_string: String) -> void:
	if prop.data_type == TYPE_INT:
		if hint == PROPERTY_HINT_RANGE:
			prop.style = INT_SPIN
			prop.style_specs = __get_range_specs(hint_string)
		elif hint == PROPERTY_HINT_ENUM:
			prop.style = INT_ENUM
			prop.style_specs = __get_enum_specs(hint_string)
		else:
			prop.style = INT_SPIN
	elif prop.data_type == TYPE_FLOAT:
		prop.style = FLOAT_SPIN

		if hint == PROPERTY_HINT_RANGE:
			prop.style_specs = __get_range_specs(hint_string)
	elif prop.data_type == TYPE_STRING:
		if hint == PROPERTY_HINT_ENUM:
			prop.style = STRING_ENUM
			prop.style_specs = __get_enum_specs(hint_string)
		else:
			prop.style = STRING_PLAIN


func __add_items() -> void:
	if _collection.type == Collection.CollectionType.FILES:
		__add_file_collection_items()


func __add_file_collection_items() -> void:
	var list: PackedStringArray = ResourceLoader.list_directory(_collection.path)
	var count: int = 0

	for file in list:
		if file.get_extension() in ["tres", "res"]:
			var res: Resource = ResourceLoader.load(_collection.path.path_join(file))

			if res.script == _collection.collection_script:
				var row: Control = __add_row(res)
				var capitalize: bool = _key_prop.style_specs.get(&"capitalize", true)
				var edit: LineEdit = row.get_node("File")
				var filename: String = file.get_basename()
				edit.text = filename.capitalize() if capitalize else filename
				count += 1

	_collection.entries = count


func __add_row(res: Resource) -> Control:
	var row: HBoxContainer = HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_items.add_child(row)
	_resources.push_back(res)

	for prop in _props:
		if prop.property_type == PropertyType.HIDDEN:
			continue

		var value: Variant

		match prop.property_type:
			PropertyType.SCRIPT:
				value = res.get(prop.prop_name)
			PropertyType.KEY:
				value = prop.style_specs[&"default_value"]

		var cell: Control = __get_property_cell(prop, value, res)
		cell.name = prop.prop_name
		row.add_child(cell)
		cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var delete_button: Button = Button.new()
	delete_button.custom_minimum_size.x = 32
	delete_button.icon = EditorInterface.get_editor_theme().get_icon(&"Remove", &"EditorIcons")
	delete_button.flat = true
	row.add_child(delete_button)
	return row


func __get_property_cell(prop: Property, value: Variant, res: Resource) -> Control:
	match prop.data_type:
		TYPE_INT:
			return __get_int_cell(prop, value, res)
		TYPE_FLOAT:
			return __get_float_cell(prop, value, res)
		TYPE_STRING:
			return __get_string_cell(prop, value, res)
	return null


func __get_int_cell(prop: Property, value: int, res: Resource) -> Control:
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

		if prop.property_type == PropertyType.SCRIPT:
			Err.conn(cell.value_changed, func(new_value: float): res.set(prop.prop_name, int(new_value)), 0, _ADDON)

		return cell
	elif prop.style == INT_ENUM:
		var cell: OptionButton = OptionButton.new()
		var ids: PackedInt32Array = prop.style_specs.get(&"ids", [])
		var labels: PackedStringArray = prop.style_specs.get(&"labels", [])

		for i in labels.size():
			var id: int = ids[i]
			var label: String = labels[i]
			cell.add_item(label, id)

		if prop.property_type == PropertyType.SCRIPT:
			Err.conn(cell.item_selected, func(item: int): res.set(prop.prop_name, cell.get_item_id(item)), 0, _ADDON)

		cell.select(cell.get_item_index(value))
		return cell
	return null


func __get_float_cell(prop: Property, value: int, res: Resource) -> Control:
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

		if prop.property_type == PropertyType.SCRIPT:
			Err.conn(cell.value_changed, func(new_value: float): res.set(prop.prop_name, new_value), 0, _ADDON)

		return cell
	return null


func __get_string_cell(prop: Property, value: String, res: Resource) -> Control:
	if prop.style == STRING_PLAIN:
		var cell: LineEdit = LineEdit.new()
		cell.text = value
		cell.flat = true
		Err.conn(cell.editing_toggled, func(toggled_on: bool): cell.flat = not toggled_on, 0, _ADDON)

		if prop.property_type == PropertyType.SCRIPT:
			var f: Callable = func(new_text: String): res.set(prop.prop_name, new_text)
			Err.conn(cell.text_submitted, f, 0, _ADDON)
			Err.conn(cell.focus_exited, f.bind(cell.text), 0, _ADDON)
		elif prop.property_type == PropertyType.KEY:
			Err.conn(cell.text_submitted, _on_key_changed.bind(prop, res, cell), 0, _ADDON)
			Err.conn(cell.focus_exited, _on_key_changed.bind(cell.text, prop, res, cell), 0, _ADDON)

		return cell
	elif prop.style == STRING_ENUM:
		var cell: OptionButton = OptionButton.new()
		var ids: PackedInt32Array = prop.style_specs.get(&"ids", [])
		var labels: PackedStringArray = prop.style_specs.get(&"labels", [])
		var index: int = 0

		for i in labels.size():
			var id: int = ids[i]
			var label: String = labels[i]
			cell.add_item(label, id)

			if value == label:
				index = i

		if prop.property_type == PropertyType.SCRIPT:
			Err.conn(cell.item_selected, func(item: int): res.set(prop.prop_name, cell.get_item_text(item)), 0, _ADDON)

		cell.select(index)
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


func __add_new_row() -> void:
	var res: Resource = _collection.collection_script.new()
	var row: Control = __add_row(res)
	var focus_name: String = "File" if _collection.type == Collection.CollectionType.FILES else \
		"Key" if _collection.type == Collection.CollectionType.STRING_DICTIONARY else ""

	if not focus_name.is_empty():
		var focus_ctrl: LineEdit = row.get_node(focus_name) as LineEdit

		if focus_ctrl:
			focus_ctrl.select_all()
			focus_ctrl.grab_focus()


func __increase_filename(file: String) -> String:
	var parts: PackedStringArray = file.split("_")

	if parts.size() > 1 and parts[-1].is_valid_int():
		var num: int = parts[-1].to_int()
		var append: String = str(num + 1).lpad(parts[-1].length(), "0")
		return "".join(parts.slice(0, parts.size() - 1)) + "_" + append
	else:
		return file + "_001"


# =============================================================
# ========= Signal Callbacks ==================================

func _on_back_pressed() -> void:
	back_pressed.emit()


func _on_new_item_pressed() -> void:
	__add_new_row()
	_collection.entries += 1
	%NumEntriesLabel.text = "Entries: %d" % _collection.entries


func _on_key_changed(_new_key: String, prop: Property, res: Resource, edit: LineEdit) -> void:
	if _collection.type == Collection.CollectionType.FILES:
		var capitalize: bool = prop.style_specs.get(&"capitalize", true)
		var file_name: String = edit.text.to_snake_case() if capitalize else edit.text
		var path: String = _collection.path.path_join(file_name + ".tres")

		if res.resource_path != path:
			var changed: bool = false

			while FileAccess.file_exists(path):
				file_name = __increase_filename(file_name)
				path = _collection.path.path_join(file_name + ".tres")
				changed = true

			if res.resource_path.is_empty():
				Err.try_err(ResourceSaver.save(res, path), "Failed to save collection item file.", _ADDON)
			else:
				Err.try_err(DirAccess.rename_absolute(res.resource_path, path), "Failed to rename collection item file.", _ADDON)
				EditorInterface.get_resource_filesystem().scan()

			res.take_over_path(path)

			if changed:
				edit.text = file_name.capitalize() if capitalize else file_name
	elif _collection.type == Collection.CollectionType.STRING_DICTIONARY:
		pass
