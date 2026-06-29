@tool
extends ConfirmationDialog

const STRING_PLAIN: int = 0
const STRING_COLLECTION_ITEM: int = 4

const Collection: GDScript = preload("res://addons/true_data/classes/collection.gd")

const _ADDON: StringName = &"TrueData"

var _collections: DataCollections
var _collections_ready: bool = false
var _selected_collection: int = 0
var _props: Array[Dictionary]
var _prop_selected: String = ""

# =============================================================
# ========= Public Functions ==================================

func show_dialog(collections: DataCollections, style: Dictionary[StringName, Variant]) -> void:
	_collections = collections
	_collections_ready = false
	%CollectionOptions.clear()
	var type_idx: int = %TypeOptions.get_item_index(style.get(&"style_type", STRING_PLAIN))
	_selected_collection = style.get(&"collection_idx", 0)
	_prop_selected = style.get(&"property_name", "")
	%TypeOptions.select(type_idx)
	popup_centered()


func get_style() -> Dictionary[StringName, Variant]:
	var dict: Dictionary[StringName, Variant]
	var type: int = %TypeOptions.get_selected_id()
	dict[&"style_type"] = type

	if type == STRING_COLLECTION_ITEM:
		dict[&"collection_idx"] = _selected_collection
		dict[&"property_name"] = _prop_selected

	return dict

# =============================================================
# ========= Built-in Functions ================================

# =============================================================
# ========= Virtual Methods ===================================

# =============================================================
# ========= Private Functions =================================

func __add_collections_options() -> void:
	if _collections_ready:
		return

	var options: OptionButton = %CollectionOptions
	options.clear()

	for i in _collections.size():
		var collection: Collection = _collections.arr[i]

		if collection.type == Collection.CollectionType.FILES:
			options.add_item(collection.resource_name, i)

	options.select(_selected_collection)
	_collections_ready = true

	if _selected_collection == 0:
		_on_collection_options_item_selected(0)


func __add_property_options() -> void:
	var collection: Collection = _collections.arr[_selected_collection]
	var col_script: GDScript = collection.collection_script
	var usage: int = PROPERTY_USAGE_DEFAULT | PROPERTY_USAGE_SCRIPT_VARIABLE
	_props = Data.get_script_properties_info(col_script, usage)
	var options: OptionButton = %PropertyOptions
	options.clear()

	options.add_item("File")
	var selected: int = 0

	for i in _props.size():
		var prop: Dictionary = _props[i]
		var prop_name: String = prop["name"]
		options.add_item(prop_name.capitalize())

		if prop_name == _prop_selected:
			selected = i + 1

	options.select(selected)


# =============================================================
# ========= Signal Callbacks ==================================


func _on_type_options_item_selected(index: int) -> void:
	var id: int = %TypeOptions.get_item_id(index)

	match id:
		STRING_PLAIN:
			$BoxContainer/CollectionContainer.hide()
			$BoxContainer/PropertyContainer.hide()
		STRING_COLLECTION_ITEM:
			$BoxContainer/CollectionContainer.show()
			$BoxContainer/PropertyContainer.show()
			__add_collections_options()


func _on_collection_options_item_selected(index: int) -> void:
	_selected_collection = index
	__add_property_options()


func _on_property_options_item_selected(index: int) -> void:
	if index == 0:
		_prop_selected = ""
	else:
		var prop: Dictionary = _props[index - 1]
		_prop_selected = prop["name"]
