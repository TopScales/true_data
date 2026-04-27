##
##
@tool
extends MarginContainer

var undoredo: EditorUndoRedoManager:
	set(value):
		undoredo = value
		_current_view.undoredo = undoredo

var _current_view: Control

# =============================================================
# ========= Public Functions ==================================

# =============================================================
# ========= Built-in Functions ================================

func _ready() -> void:
	_current_view = $CurrentView.get_child(0)

# =============================================================
# ========= Virtual Methods ===================================

# =============================================================
# ========= Private Functions =================================

# =============================================================
# ========= Signal Callbacks ==================================
