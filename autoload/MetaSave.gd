extends Node
## 런 사이 유지되는 메타. S1 클리어 시 보급 레벨만 해금한다.

const Bal = preload("res://autoload/Balance.gd")

const SAVE_PATH := "user://infection_clearance_meta.json"

var supply_level: int = 0
var ibeonman_available: bool = true
var s1_cleared: bool = false

func _ready() -> void:
	load_meta()


func load_meta() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	var data: Dictionary = parsed
	supply_level = int(data.get("supply_level", 0))
	ibeonman_available = bool(data.get("ibeonman_available", true))
	s1_cleared = bool(data.get("s1_cleared", false))


func save_meta() -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_warning("MetaSave: cannot write %s" % SAVE_PATH)
		return
	file.store_string(JSON.stringify({
		"supply_level": supply_level,
		"ibeonman_available": ibeonman_available,
		"s1_cleared": s1_cleared,
	}, "\t"))


func unlock_supply_on_clear() -> bool:
	var first := not s1_cleared or supply_level < Bal.SUPPLY_LEVEL_ON_CLEAR
	s1_cleared = true
	if supply_level < Bal.SUPPLY_LEVEL_ON_CLEAR:
		supply_level = Bal.SUPPLY_LEVEL_ON_CLEAR
	save_meta()
	return first


func consume_ibeonman() -> void:
	ibeonman_available = false
	save_meta()


func reset_for_tests(path_override: String = "") -> void:
	if path_override != "":
		# tests may wipe user:// by deleting the default file
		pass
	supply_level = 0
	ibeonman_available = true
	s1_cleared = false
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
	save_meta()
