@tool
extends VBoxContainer

enum PropertyType { SCRIPT, HIDDEN, KEY }

class Property:
	var prop_name: StringName
	var data_type: int
	var property_type: PropertyType
	var style: int
	var style_specs: Dictionary[StringName, Variant]
	var index: int = 0
# Properties can be:
# Script variable
# Hidden script variable
# Editable non-script (like file)
# Non-editable defined by func
# Expression

signal back_pressed

const Collection: GDScript = preload("res://addons/true_data/classes/collection.gd")
const Header: GDScript = preload("res://addons/true_data/views/header.gd")
const VectorProperty: GDScript = preload("res://addons/true_data/views/properties/vector_property.gd")
const StringOptionsScn: PackedScene = preload("res://addons/true_data/views/property_options/string_options_dialog.tscn")
const StringOptions: GDScript = preload("res://addons/true_data/views/property_options/string_options_dialog.gd")

const HEADER_SCENE: PackedScene = preload("res://addons/true_data/views/header.tscn")

const INT_STATIC: int = 0
const INT_SPIN: int = 1
const INT_ENUM: int = 2
const INT_FLAGS: int = 3
const FLOAT_SPIN: int = 0
const STRING_PLAIN: int = 0
const STRING_ENUM: int = 1
const STRING_FILE: int = 2
const STRING_DIR: int = 3
const STRING_COLLECTION_ITEM: int = 4

const _ADDON: StringName = &"TrueData"
const _SETTINGS_PREFIX: String = "addons/true_data/"

var file_dialog: EditorFileDialog
var undoredo: EditorUndoRedoManager

var _collections: DataCollections
var _collection: Collection
var _props: Array[Property]
var _prop_dict: Dictionary[StringName, Property]
var _resources: Array[Resource]
var _key_prop: Property
var _collection_res: Resource
var _to_delete: int

var _string_options: StringOptions

@onready var _headers: Control = %Headers
@onready var _items: Control = %Items
@onready var _delete_confirmation: ConfirmationDialog = $DeleteConfirmation

# =============================================================
# ========= Public Functions ==================================

func reset() -> void:
	pass


func save_data() -> void:
	if _collection.type == Collection.CollectionType.FILES:
		for res in _resources:
			if not res.resource_path.is_empty():
				Err.try_err(ResourceSaver.save(res, res.resource_path), "Failed to save collection item.", _ADDON)
	elif _collection_res:
		Err.try_err(ResourceSaver.save(_collection_res, _collection_res.resource_path), "Failed to save collection.", _ADDON)


func set_collection(collection: Collection) -> void:
	_collection = collection
	var path: String = ProjectSettings.get_setting(_SETTINGS_PREFIX + "collections_resource_path", "")
	_collections = ResourceLoader.load(path)

	if collection.type == Collection.CollectionType.ARRAY or collection.type == Collection.CollectionType.STRING_DICTIONARY \
			or collection.type == Collection.CollectionType.INT_DICTIONARY \
			or collection.type == Collection.CollectionType.CONFIG:
		_collection_res = load(_collection.path)

	$CollectionLabel.text = collection.resource_name
	__add_headers()
	__add_items()
	%NumEntriesLabel.text = "Entries: %d" % _collection.entries


func add_new_item() -> void:
	var res: Resource = _collection.collection_script.new()
	var key: Variant = __get_new_key()
	add_item_at(-1, res, key)

	if _collection.type == Collection.CollectionType.FILES or _collection.type == Collection.CollectionType.STRING_DICTIONARY:
		var row: Control = _items.get_child(-1)
		var key_edit: LineEdit = row.get_child(0) as LineEdit
		key_edit.select_all()
		key_edit.grab_focus()


func add_item_at(index: int, item: Resource, key: Variant) -> void:
	__add_row(item, key, index)
	_collection.entries += 1
	%NumEntriesLabel.text = "Entries: %d" % _collection.entries

	if index == -1:
		_resources.push_back(item)
	else:
		Err.try_insert(_resources.insert(index, item), _ADDON)

	if _collection.type == Collection.CollectionType.ARRAY:
		var array_collection: DataCollectionArray = _collection_res as DataCollectionArray

		if index == -1:
			array_collection.arr.push_back(item)
		else:
			Err.try_insert(array_collection.arr.insert(index, item), _ADDON)


func remove_item(index: int) -> void:
	var row: Control = _items.get_child(index)
	row.queue_free()
	var res: Resource = _resources[index]
	_resources.remove_at(index)
	_collection.entries -= 1
	%NumEntriesLabel.text = "Entries: %d" % _collection.entries

	match _collection.type:
		Collection.CollectionType.FILES:
			Err.try_err(DirAccess.remove_absolute(res.resource_path), "Failed to remove collection file.", _ADDON)
			EditorInterface.get_resource_filesystem().scan()
		Collection.CollectionType.ARRAY:
			var array_collection: DataCollectionArray = _collection_res as DataCollectionArray
			array_collection.arr.remove_at(index)


func set_property_style(property: StringName, style: Dictionary[StringName, Variant]) -> void:
	if style.is_empty():
		@warning_ignore("return_value_discarded")
		_collection.styles.erase(property)
	else:
		_collection.styles[property] = style

	__update_property_cells(property)


# =============================================================
# ========= Built-in Functions ================================


func _notification(what: int) -> void:
	if what == NOTIFICATION_THEME_CHANGED:
		$Back.icon = EditorInterface.get_editor_theme().get_icon(&"ArrowLeft", &"EditorIcons")
		%NewItem.icon = EditorInterface.get_editor_theme().get_icon(&"Add", &"EditorIcons")


# =============================================================
# ========= Virtual Methods ===================================

# =============================================================
# ========= Private Functions =================================

func __add_headers() -> void:
	var usage: int = PROPERTY_USAGE_DEFAULT | PROPERTY_USAGE_SCRIPT_VARIABLE
	var props: Array[Dictionary] = Data.get_script_properties_info(_collection.collection_script, usage)

	match _collection.type:
		Collection.CollectionType.FILES:
			var prop: Property = Property.new()
			prop.prop_name = &"File"
			prop.data_type = TYPE_STRING
			prop.property_type = PropertyType.KEY
			prop.style = STRING_PLAIN
			_props.push_back(prop)
			_key_prop = prop
		Collection.CollectionType.STRING_DICTIONARY:
			var prop: Property = Property.new()
			prop.prop_name = &"Key"
			prop.data_type = TYPE_STRING_NAME
			prop.property_type = PropertyType.KEY
			prop.style = STRING_PLAIN
			_props.push_back(prop)
			_key_prop = prop
		Collection.CollectionType.ARRAY:
			var prop: Property = Property.new()
			prop.prop_name = &"Index"
			prop.data_type = TYPE_INT
			prop.property_type = PropertyType.KEY
			prop.style = INT_STATIC
			prop.style_specs = {&"default_value": "New Key", &"show_title": false,
					&"size_flags": Control.SIZE_FILL}
			_props.push_back(prop)
			_key_prop = prop

	for p in props:
		var prop: Property = Property.new()
		prop.prop_name = p["name"]
		prop.data_type = p["type"]
		prop.property_type = PropertyType.SCRIPT
		__set_prop_style(prop, p["hint"], p["hint_string"])
		_props.push_back(prop)

	for i in _props.size():
		var prop: Property = _props[i]
		var header: Header = HEADER_SCENE.instantiate()
		_headers.add_child(header)
		var show_options: bool = prop.style_specs.get(&"show_options", false)
		var show_title: bool = prop.style_specs.get(&"show_title", true)
		var size_flags: int = prop.style_specs.get(&"size_flags", Control.SIZE_EXPAND_FILL)
		header.set_property(prop.prop_name, show_options, show_title)
		header.size_flags_horizontal = size_flags
		Err.conn(header.options_pressed, _on_header_options_pressed.bind(prop.prop_name), 0, _ADDON)
		prop.index = i
		_prop_dict[prop.prop_name] = prop

	var delete_space: Control = Control.new()
	delete_space.custom_minimum_size.x = 32
	_headers.add_child(delete_space)


func __set_prop_style(prop: Property, hint: int, hint_string: String) -> void:
	var def_style: Dictionary[StringName, Variant]

	if prop.data_type == TYPE_INT:
		if hint == PROPERTY_HINT_RANGE:
			prop.style = INT_SPIN
			prop.style_specs = __get_range_specs(hint_string)
		elif hint == PROPERTY_HINT_ENUM:
			prop.style = INT_ENUM
			prop.style_specs = __get_enum_specs(hint_string)
		elif hint == PROPERTY_HINT_FLAGS:
			prop.style = INT_FLAGS
			prop.style_specs = __get_flags_specs(hint_string)
		else:
			prop.style_specs = _collection.styles.get(prop.prop_name, def_style)
			prop.style = prop.style_specs.get(&"style_type", INT_SPIN)
			prop.style_specs[&"show_options"] = true
	elif prop.data_type == TYPE_FLOAT:
		if hint == PROPERTY_HINT_RANGE:
			prop.style = FLOAT_SPIN
			prop.style_specs = __get_range_specs(hint_string)
			prop.style_specs[&"hide_slider"] = false
			prop.style_specs[&"show_options"] = false
		else:
			prop.style_specs = _collection.styles.get(prop.prop_name, def_style)
			prop.style = prop.style_specs.get(&"style_type", FLOAT_SPIN)
			prop.style_specs[&"show_options"] = true
	elif prop.data_type == TYPE_STRING:
		if hint == PROPERTY_HINT_ENUM:
			prop.style = STRING_ENUM
			prop.style_specs = __get_enum_specs(hint_string)
			prop.style_specs[&"show_options"] = false
		elif hint == PROPERTY_HINT_FILE:
			prop.style = STRING_FILE
			prop.style_specs = __get_file_specs(hint_string, true)
		elif hint == PROPERTY_HINT_FILE_PATH:
			prop.style = STRING_FILE
			prop.style_specs = __get_file_specs(hint_string, false)
		elif hint == PROPERTY_HINT_DIR:
			prop.style = STRING_DIR
		else:
			prop.style_specs = _collection.styles.get(prop.prop_name, def_style)
			prop.style = prop.style_specs.get(&"style_type", STRING_PLAIN)
			prop.style_specs[&"show_options"] = true
	elif prop.data_type == TYPE_STRING_NAME:
		prop.style_specs = _collection.styles.get(prop.prop_name, def_style)
		prop.style = prop.style_specs.get(&"style_type", STRING_PLAIN)
		prop.style_specs[&"show_options"] = true


func __add_items() -> void:
	match _collection.type:
		Collection.CollectionType.FILES:
			__add_file_collection_items()
		Collection.CollectionType.ARRAY:
			__add_array_collection_items()


func __add_file_collection_items() -> void:
	var list: PackedStringArray = ResourceLoader.list_directory(_collection.path)

	for file in list:
		if file.get_extension() in ["tres", "res"]:
			var res: Resource = ResourceLoader.load(_collection.path.path_join(file))

			if res.script == _collection.collection_script:
				var filename: String = file.get_basename()
				var capitalize: bool = _key_prop.style_specs.get(&"capitalize", true)
				var key: String = filename.capitalize() if capitalize else filename
				__add_row(res, key, -1)
				_resources.push_back(res)

	_collection.entries = _resources.size()


func __add_array_collection_items() -> void:
	var c: DataCollectionArray = _collection_res as DataCollectionArray

	for i in c.size():
		__add_row(c.arr[i], i, -1)

	_collection.entries = c.size()
	_resources = (_collection_res as DataCollectionArray).arr


func __add_row(res: Resource, key: Variant, index: int) -> void:
	var row: HBoxContainer = HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.set_meta(&"key", key)
	_items.add_child(row)

	if index != -1:
		_items.move_child(row, index)

	for prop in _props:
		if prop.property_type == PropertyType.HIDDEN:
			continue

		var value: Variant = res.get(prop.prop_name) if prop.property_type == PropertyType.SCRIPT else key
		var cell: Control = __get_property_cell(prop, value, res)
		cell.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		cell.name = prop.prop_name
		row.add_child(cell)

	var delete_button: Button = Button.new()
	delete_button.custom_minimum_size.x = 32
	delete_button.icon = EditorInterface.get_editor_theme().get_icon(&"Remove", &"EditorIcons")
	delete_button.flat = true
	row.add_child(delete_button)
	Err.conn(delete_button.pressed, _on_delete_pressed.bind(row.get_index()), 0, _ADDON)


func __get_new_key() -> Variant:
	match _collection.type:
		Collection.CollectionType.FILES:
			return "New File"
		Collection.CollectionType.STRING_DICTIONARY:
			return "New Key"
		Collection.CollectionType.ARRAY:
			return _resources.size()
		_:
			return null


func __get_property_cell(prop: Property, value: Variant, res: Resource) -> Control:
	match prop.data_type:
		TYPE_INT:
			return __get_int_cell(prop, value, res)
		TYPE_FLOAT:
			return __get_float_cell(prop, value, res)
		TYPE_STRING:
			return __get_string_cell(prop, value, res)
		TYPE_STRING_NAME:
			return __get_stringname_cell(prop, value, res)
		TYPE_COLOR:
			return __get_color_cell(prop, value, res)
		TYPE_VECTOR2I:
			return __get_vector2i_cell(prop, value, res)
		_:
			return __get_ni_cell()


func __get_ni_cell() -> Control:
	var cell: Label = Label.new()
	cell.text = tr("Not implemented")
	cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cell.text_overrun_behavior = TextServer.OVERRUN_TRIM_CHAR
	return cell


func __get_int_cell(prop: Property, value: int, res: Resource) -> Control:
	match prop.style:
		INT_SPIN:
			var cell: EditorSpinSlider = EditorSpinSlider.new()
			cell.step = prop.style_specs.get(&"step", 1)
			cell.max_value = prop.style_specs.get(&"max_value", 100)
			cell.min_value = prop.style_specs.get(&"min_value", 0)
			cell.allow_greater = prop.style_specs.get(&"allow_greater", true)
			cell.allow_lesser = prop.style_specs.get(&"allow_lesser", true)
			cell.suffix = prop.style_specs.get(&"suffix", "")
			cell.value = value
			cell.editing_integer = true
			cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL

			if prop.property_type == PropertyType.SCRIPT:
				Err.conn(cell.value_changed, func(new_value: float): res.set(prop.prop_name, int(new_value)), 0, _ADDON)

			return cell
		INT_ENUM:
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
			cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			return cell
		INT_FLAGS:
			var cell: VBoxContainer = VBoxContainer.new()
			cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			cell.add_theme_constant_override(&"separation", 0)
			cell.name = prop.prop_name
			var ids: PackedInt32Array = prop.style_specs.get(&"ids", [])
			var labels: PackedStringArray = prop.style_specs.get(&"labels", [])

			for i in labels.size():
				var id: int = ids[i]
				var label: String = labels[i]
				var flag: CheckBox = CheckBox.new()
				flag.text = label
				flag.set_meta(&"id", id)
				Err.conn(flag.pressed, __update_flags_value.bind(cell, prop.property_type == PropertyType.SCRIPT, res), 0, _ADDON)
				cell.add_child(flag)
				flag.button_pressed = value & id
			return cell
		INT_STATIC:
			var cell: Label = Label.new()
			cell.text = str(value)
			cell.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
			cell.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
			cell.custom_minimum_size.x = 32
			return cell
	return null


func __get_float_cell(prop: Property, value: float, res: Resource) -> Control:
	if prop.style == FLOAT_SPIN:
		var cell: EditorSpinSlider = EditorSpinSlider.new()
		cell.step = prop.style_specs.get(&"step", 0.001)
		cell.max_value = prop.style_specs.get(&"max_value", 100)
		cell.min_value = prop.style_specs.get(&"min_value", 0)
		cell.allow_greater = prop.style_specs.get(&"allow_greater", true)
		cell.allow_lesser = prop.style_specs.get(&"allow_lesser", true)
		cell.suffix = prop.style_specs.get(&"suffix", "")
		var hide_slider: bool = prop.style_specs.get(&"hide_slider", true)
		cell.control_state = EditorSpinSlider.CONTROL_STATE_HIDE if hide_slider else EditorSpinSlider.CONTROL_STATE_PREFER_SLIDER
		cell.editing_integer = false
		cell.exp_edit = prop.style_specs.get(&"exp", false)
		cell.value = value
		cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL

		if prop.property_type == PropertyType.SCRIPT:
			Err.conn(cell.value_changed, func(new_value: float): res.set(prop.prop_name, new_value), 0, _ADDON)

		return cell
	return null


func __get_string_cell(prop: Property, value: String, res: Resource) -> Control:
	match prop.style:
		STRING_PLAIN:
			var cell: LineEdit = LineEdit.new()
			cell.text = value
			cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL

			if prop.property_type == PropertyType.SCRIPT:
				var f: Callable = func(new_text: String): res.set(prop.prop_name, new_text)
				Err.conn(cell.text_changed, f, 0, _ADDON)
			elif prop.property_type == PropertyType.KEY:
				Err.conn(cell.text_submitted, _on_key_changed.bind(prop, res, cell), 0, _ADDON)
				Err.conn(cell.focus_exited, _on_key_changed.bind(cell.text, prop, res, cell), 0, _ADDON)

			return cell
		STRING_ENUM:
			var cell: OptionButton = OptionButton.new()
			cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
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
		STRING_FILE, STRING_DIR:
			return __get_path_cell(prop, value, res)
		STRING_COLLECTION_ITEM:
			return null
		_:
			return null


func __get_path_cell(prop: Property, value: String, res: Resource) -> Control:
	var cell: HBoxContainer = HBoxContainer.new()
	cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var edit: LineEdit = LineEdit.new()
	edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var use_uid: bool = prop.style_specs.get(&"use_uid", false)
	var path: String = ResourceUID.uid_to_path(value) if use_uid and not value.is_empty() else value
	edit.text = path
	cell.add_child(edit)
	var button: Button = Button.new()
	var icon_name: StringName = &"FileBrowse" if prop.style == STRING_FILE else &"FolderBrowse"
	button.icon = EditorInterface.get_editor_theme().get_icon(icon_name, &"EditorIcons")
	var browse: Callable = func():
		if prop.style == STRING_FILE:
			file_dialog.filters = prop.style_specs.get(&"filters", [])
			file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
			Err.conn(file_dialog.file_selected, _on_path_cell_file_selected.bind(edit), CONNECT_ONE_SHOT, _ADDON)
		elif prop.style == STRING_DIR:
			file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_DIR
			Err.conn(file_dialog.dir_selected, _on_path_cell_dir_selected.bind(edit), CONNECT_ONE_SHOT, _ADDON)
		Err.conn(file_dialog.canceled, _on_path_cell_canceled, CONNECT_ONE_SHOT, _ADDON)
		file_dialog.popup_centered()
	Err.conn(button.pressed, browse, 0, _ADDON)
	cell.add_child(button)

	if prop.property_type == PropertyType.SCRIPT:
		var f: Callable = func(new_text: String):
			var new_path: String = ResourceUID.path_to_uid(new_text) if use_uid and not new_text.is_empty() else new_text
			res.set(prop.prop_name, new_path)
		Err.conn(edit.text_changed, f, 0, _ADDON)
	return cell


func __get_stringname_cell(prop: Property, value: String, res: Resource) -> Control:
	if prop.style == STRING_PLAIN:
		var cell: LineEdit = LineEdit.new()
		cell.text = value
		cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL

		if prop.property_type == PropertyType.SCRIPT:
			var f: Callable = func(new_text: String): res.set(prop.prop_name, new_text)
			Err.conn(cell.text_submitted, f, 0, _ADDON)
			Err.conn(cell.focus_exited, f.bind(cell.text), 0, _ADDON)
		elif prop.property_type == PropertyType.KEY:
			Err.conn(cell.text_submitted, _on_key_changed.bind(prop, res, cell), 0, _ADDON)
			Err.conn(cell.focus_exited, _on_key_changed.bind(cell.text, prop, res, cell), 0, _ADDON)

		return cell
	return null


func __get_color_cell(prop: Property, value: Color, res: Resource) -> Control:
	var cell: ColorPickerButton = ColorPickerButton.new()
	cell.color = value
	cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var f: Callable = func(new_color: Color): res.set(prop.prop_name, new_color)
	Err.conn(cell.color_changed, f, 0, _ADDON)
	return cell


func __get_vector2i_cell(prop: Property, value: Vector2i, res: Resource) -> Control:
	var cell: VectorProperty = VectorProperty.new(2, true)
	cell.set_value(value)
	var f: Callable = func(new_value: Vector2i): res.set(prop.prop_name, new_value)
	Err.conn(cell.changed, f, 0, _ADDON)
	return cell


func __get_range_specs(hint_string: String) -> Dictionary[StringName, Variant]:
	var parts: PackedStringArray = hint_string.split(",")
	var specs: Dictionary[StringName, Variant]
	specs[&"min_value"] = parts[0].to_int()
	specs[&"max_value"] = parts[1].to_int()
	specs[&"allow_greater"] = false
	specs[&"allow_lesser"] = false

	if parts.size() > 2:
		specs[&"step"] = parts[2].to_int()

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
	var id: int = -1

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


func __get_flags_specs(hint_string: String) -> Dictionary[StringName, Variant]:
	var parts: PackedStringArray = hint_string.split(",")
	var ids: PackedInt32Array
	var labels: PackedStringArray
	Err.try_resize(ids.resize(parts.size()))
	Err.try_resize(labels.resize(parts.size()))

	for i in parts.size():
		var tag: String = parts[i]
		var tag_parts: PackedStringArray = tag.split(":")
		labels[i] = tag_parts[0]
		var id: int = int(tag_parts[1]) if tag_parts.size() > 1 else int(pow(2, i))
		ids[i] = id

	return { &"ids": ids, &"labels": labels }


func __get_file_specs(hint_string: String, use_uid: bool) -> Dictionary[StringName, Variant]:
	var filters: PackedStringArray = ["%s;Files;text/plain" % hint_string]
	return {&"filters": filters, &"use_uid": use_uid}


func __increase_key(file: String) -> String:
	var parts: PackedStringArray = file.split("_")

	if parts.size() > 1 and parts[-1].is_valid_int():
		var num: int = parts[-1].to_int()
		var append: String = str(num + 1).lpad(parts[-1].length(), "0")
		return "".join(parts.slice(0, parts.size() - 1)) + "_" + append
	else:
		return file + "_001"

func __update_flags_value(control: Control, update_res: bool, resource: Resource):
	var value: int = 0

	for i in control.get_child_count():
		var flag: CheckBox = control.get_child(i)
		var id: int = flag.get_meta(&"id")
		value += id * int(flag.button_pressed)

	control.set_meta(&"value", value)

	if update_res:
		resource.set(control.name, value)


func __update_property_cells(property: StringName) -> void:
	var prop: Property = _prop_dict[property]
	var index: int = prop.index

	for i in _resources.size():
		var res: Resource = _resources[i]
		var value: Variant = res.get(prop.prop_name)
		var cell: Control = __get_property_cell(prop, value, res)
		var row: Control = _items.get_child(i)
		var old: Control = row.get_child(index)
		row.remove_child(old)
		old.queue_free()
		row.add_child(cell)
		row.move_child(cell, index)


# =============================================================
# ========= Signal Callbacks ==================================

func _on_back_pressed() -> void:
	back_pressed.emit()


func _on_new_item_pressed() -> void:
	undoredo.create_action("Add new item")
	undoredo.add_do_method(self, &"add_new_item")
	undoredo.add_undo_method(self, &"remove_item", _resources.size())
	undoredo.commit_action()


func _on_key_changed(_new_key: String, prop: Property, res: Resource, edit: LineEdit) -> void:
	var row: Control = edit.get_parent()
	var new_key: String = edit.text # The passed argument _new_key is mandatory for the text submitted signal,
									# but is not correct for the focus exited signal.
	row.set_meta(&"key", new_key)

	if _collection.type == Collection.CollectionType.FILES:
		var capitalize: bool = prop.style_specs.get(&"capitalize", true)
		var file_name: String = new_key.to_snake_case() if capitalize else new_key
		var path: String = _collection.path.path_join(file_name + ".tres")

		if res.resource_path != path:
			var changed: bool = false

			while FileAccess.file_exists(path):
				file_name = __increase_key(file_name)
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
		var capitalize: bool = prop.style_specs.get(&"capitalize", true)
		var key: String = new_key.to_snake_case() if capitalize else new_key
		var collection: DataCollectionStringDict = _collection_res as DataCollectionStringDict

		if collection.has_item(key):
			var item: Resource = collection.dict[key]

			if item != res:
				pass


func _on_header_options_pressed(property: StringName) -> void:
	var prop: Property = _prop_dict[property]

	if prop.data_type == TYPE_STRING:
		if _string_options == null:
			_string_options = StringOptionsScn.instantiate()
			Err.conn(_string_options.canceled, func() -> void: _string_options.confirmed.disconnect(_on_string_options_confirmed), 0, _ADDON)
			add_child(_string_options)

		var default_dict: Dictionary[StringName, Variant]
		Err.conn(_string_options.confirmed, _on_string_options_confirmed.bind(property), CONNECT_ONE_SHOT, _ADDON)
		_string_options.show_dialog(_collections, _collection.styles.get(property, default_dict))


func _on_string_options_confirmed(property: StringName) -> void:
	var style: Dictionary[StringName, Variant] = _string_options.get_style()
	undoredo.create_action("Set property options")
	undoredo.add_do_method(self, &"set_property_style", property, style)
	var def_dict: Dictionary[StringName, Variant]
	undoredo.add_undo_method(self, &"set_property_style", property, _collection.styles.get(property, def_dict))


func _on_delete_pressed(row: int) -> void:
	var row_ctrl: Control = _items.get_child(row)
	var key: Variant = row_ctrl.get_meta(&"key")

	match _collection.type:
		Collection.CollectionType.FILES, Collection.CollectionType.STRING_DICTIONARY:
			_delete_confirmation.dialog_text = "Delete item '%s'?" % key
		Collection.CollectionType.INT_DICTIONARY, Collection.CollectionType.ARRAY:
			_delete_confirmation.dialog_text = "Delete item with index %d?" % key

	_to_delete = row
	_delete_confirmation.popup_centered()


func _on_delete_confirmation_confirmed() -> void:
	undoredo.create_action("Delete item")
	undoredo.add_do_method(self, &"remove_item", _to_delete)
	var row: Control = _items.get_child(_to_delete)
	var key: Variant = row.get_meta(&"key")
	undoredo.add_undo_method(self, &"add_item_at", _to_delete, _resources[_to_delete], key)
	undoredo.commit_action()


func _on_path_cell_canceled() -> void:
	if file_dialog.file_selected.is_connected(_on_path_cell_file_selected):
		file_dialog.file_selected.disconnect(_on_path_cell_file_selected)

	if file_dialog.dir_selected.is_connected(_on_path_cell_dir_selected):
		file_dialog.dir_selected.disconnect(_on_path_cell_dir_selected)


func _on_path_cell_file_selected(path: String, edit: LineEdit) -> void:
	file_dialog.canceled.disconnect(_on_path_cell_canceled)
	edit.text = path
	edit.text_changed.emit(path)


func _on_path_cell_dir_selected(dir: String, edit: LineEdit) -> void:
	file_dialog.canceled.disconnect(_on_path_cell_canceled)
	edit.text = dir
	edit.text_changed.emit(dir)
