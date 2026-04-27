##
##
@tool
extends Resource

enum CollectionType { FILES, STRING_DICTIONARY, INT_DICTIONARY, ARRAY, CONFIG }

@export var path: String
@export var type: CollectionType = CollectionType.FILES
@export var collection_script: GDScript
@export var entries: int = 0: get = get_entries
@export var bulk_load: bool = false

var _entries_read: bool = false

# =============================================================
# ========= Public Functions ==================================

func get_entries() -> int:
	if not _entries_read:
		if type == CollectionType.FILES:
			var files: PackedStringArray = ResourceLoader.list_directory(path)
			entries = 0

			for file in files:
				var ext: String = file.get_extension()
				if ext == "tres" or ext == "res":
					entries += 1
		elif type == CollectionType.CONFIG:
			entries = -1
		else:
			var res: Resource = load(path)
			entries = res.size()

		_entries_read = true
	return entries

# =============================================================
# ========= Built-in Functions ================================

# =============================================================
# ========= Virtual Methods ===================================

# =============================================================
# ========= Private Functions =================================

# =============================================================
# ========= Signal Callbacks ==================================
