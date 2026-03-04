##
##
@tool
extends ResourceStringDict

enum CollectionType { FILES, DICTIONARY, ARRAY, CONFIG }

class Collection:
	@export var location: String
	@export var type: int = 0
	@export var entries: int = 0
	@export var load_collection: bool = true


# =============================================================
# ========= Public Functions ==================================

# =============================================================
# ========= Built-in Functions ================================

# =============================================================
# ========= Virtual Methods ===================================

# =============================================================
# ========= Private Functions =================================

# =============================================================
# ========= Signal Callbacks ==================================
