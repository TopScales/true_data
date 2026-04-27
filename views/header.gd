##
##
@tool
extends Button

signal options_pressed
signal order_changed(order: int)

const ORDER_NONE: int = 0
const ORDER_INCREMENTAL: int = 1
const ORDER_DECREMENTAL: int = 2

var _order: int = ORDER_NONE: set = __set_order
var _prop_name: StringName


# =============================================================
# ========= Public Functions ==================================

func set_property(property_name: StringName, show_options: bool) -> void:
	_prop_name = property_name
	name = _prop_name.to_pascal_case()
	text = _prop_name.capitalize()
	$Options.visible = show_options


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

	match _order:
		ORDER_NONE:
			icon = null
		ORDER_INCREMENTAL:
			icon = EditorInterface.get_editor_theme().get_icon(&"GuiSpinboxDown", &"EditorIcons")
		ORDER_DECREMENTAL:
			icon = EditorInterface.get_editor_theme().get_icon(&"GuiSpinboxUp", &"EditorIcons")


# =============================================================
# ========= Signal Callbacks ==================================


func _on_options_pressed() -> void:
	options_pressed.emit()


func _on_pressed() -> void:
	match _order:
		ORDER_NONE:
			_order = ORDER_INCREMENTAL
		ORDER_INCREMENTAL:
			_order = ORDER_DECREMENTAL
		ORDER_DECREMENTAL:
			_order = ORDER_INCREMENTAL

	order_changed.emit(_order)
