##
##
@tool
extends HBoxContainer

signal order_changed(order: int)
signal options_pressed

const ORDER_NONE: int = 0
const ORDER_INCREMENTAL: int = 1
const ORDER_DECREMENTAL: int = 2

var _order: int = ORDER_NONE: set = __set_order
var _prop_name: StringName

@onready var _button: Button = $Button
@onready var _options: Button = $Options

# =============================================================
# ========= Public Functions ==================================

func set_property(property_name: StringName, show_options: bool, show_title: bool = true) -> void:
	_prop_name = property_name
	name = _prop_name.to_pascal_case()
	_options.visible = show_options

	if show_title:
		_button.text = _prop_name.capitalize()
	else:
		_button.text = ""
		size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		custom_minimum_size.x = 32


func clear_order() -> void:
	_order = ORDER_NONE


# =============================================================
# ========= Built-in Functions ================================


# =============================================================
# ========= Virtual Methods ===================================

# =============================================================
# ========= Private Functions =================================

func __set_order(value: int) -> void:
	_order = value

	if not is_inside_tree():
		return

	match _order:
		ORDER_NONE:
			_button.icon = null
		ORDER_INCREMENTAL:
			_button.icon = EditorInterface.get_editor_theme().get_icon(&"GuiSpinboxDown", &"EditorIcons")
		ORDER_DECREMENTAL:
			_button.icon = EditorInterface.get_editor_theme().get_icon(&"GuiSpinboxUp", &"EditorIcons")


# =============================================================
# ========= Signal Callbacks ==================================


func _on_button_pressed() -> void:
	match _order:
		ORDER_NONE:
			_order = ORDER_INCREMENTAL
		ORDER_INCREMENTAL:
			_order = ORDER_DECREMENTAL
		ORDER_DECREMENTAL:
			_order = ORDER_INCREMENTAL

	order_changed.emit(_order)


func _on_options_pressed() -> void:
	options_pressed.emit()
