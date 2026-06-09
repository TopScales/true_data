##
##
extends HBoxContainer

signal changed(value: Variant)

const _ADDON: StringName = &"TrueData"
const _COMPONENT_LABELS: PackedStringArray = ["x", "y", "z", "w"]

var _component_count: int
var _spin_sliders: Array[EditorSpinSlider]
var _value: Variant

# =============================================================
# ========= Public Functions ==================================

func set_value(value: Variant) -> void:
	var is_correct: bool = false

	match typeof(value):
		TYPE_VECTOR2, TYPE_VECTOR2I:
			is_correct = _component_count == 2
		TYPE_VECTOR3, TYPE_VECTOR3I:
			is_correct = _component_count == 3
		TYPE_VECTOR4, TYPE_VECTOR4I:
			is_correct = _component_count == 4

	if is_correct:
		_value = value

		for i in _spin_sliders.size():
			var spin: EditorSpinSlider = _spin_sliders[i]
			spin.value = _value[i]
	else:
		Log.error("Trying to set value to an incorrect type.", _ADDON)


# =============================================================
# ========= Built-in Functions ================================

func _init(component_count: int, is_int: bool) -> void:
	_component_count = component_count
	Err.try_resize(_spin_sliders.resize(component_count), _ADDON)

	if is_int:
		match component_count:
			2:
				_value = Vector2i()
			3:
				_value = Vector3i()
			4:
				_value = Vector4i()
			_:
				Log.error("Incorrect number of components.", _ADDON)
	else:
		match component_count:
			2:
				_value = Vector2()
			3:
				_value = Vector3()
			4:
				_value = Vector4()
			_:
				Log.error("Incorrect number of components.", _ADDON)

	for i in _component_count:
		var spin: EditorSpinSlider = EditorSpinSlider.new()
		spin.flat = true
		spin.label = _COMPONENT_LABELS[i]
		spin.accessibility_name = _COMPONENT_LABELS[i]
		spin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		spin.editing_integer = is_int
		spin.step = 1.0 if is_int else 0.001
		Err.conn(spin.value_changed, _on_value_changed.bind(i))
		_spin_sliders[i] = spin
		add_child(spin)


# =============================================================
# ========= Virtual Methods ===================================

# =============================================================
# ========= Private Functions =================================

# =============================================================
# ========= Signal Callbacks ==================================

func _on_value_changed(value: float, field_index: int) -> void:
	_value[field_index] = value
	changed.emit(_value)
