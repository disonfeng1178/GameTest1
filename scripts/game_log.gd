class_name GameLog
extends RefCounted

const PATH := "user://jiexian.log"
const MAX_LINES := 500

static func _stamp() -> String:
	var t: Dictionary = Time.get_datetime_dict_from_system()
	return "%04d-%02d-%02d %02d:%02d:%02d" % [t["year"], t["month"], t["day"], t["hour"], t["minute"], t["second"]]

static func _write(level: String, msg: String) -> void:
	var line: String = "[%s] [%s] %s" % [_stamp(), level, msg]
	print(line)
	var f: FileAccess = FileAccess.open(PATH, FileAccess.READ_WRITE)
	if f == null:
		f = FileAccess.open(PATH, FileAccess.WRITE)
		if f == null:
			return
	f.seek_end()
	f.store_line(line)
	f.close()
	_trim()

static func _trim() -> void:
	var f: FileAccess = FileAccess.open(PATH, FileAccess.READ)
	if f == null:
		return
	var lines: PackedStringArray = f.get_as_text().split("\n")
	f.close()
	if lines.size() > MAX_LINES + 1:
		var keep: PackedStringArray = lines.slice(lines.size() - MAX_LINES - 1)
		var w: FileAccess = FileAccess.open(PATH, FileAccess.WRITE)
		if w != null:
			w.store_string("\n".join(keep))
			w.close()

static func info(msg: String) -> void:
	_write("INFO", msg)

static func warn(msg: String) -> void:
	_write("WARN", msg)

static func err(msg: String) -> void:
	_write("ERROR", msg)

static func tail(n: int = 30) -> String:
	var f: FileAccess = FileAccess.open(PATH, FileAccess.READ)
	if f == null:
		return "(no log)"
	var lines: PackedStringArray = f.get_as_text().split("\n")
	f.close()
	return "\n".join(lines.slice(maxi(0, lines.size() - n - 1)))
