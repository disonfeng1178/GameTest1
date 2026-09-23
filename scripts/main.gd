extends Control

var scenes: Array = []
var idx: int = 0
var affinity := {"求知": 0, "体面": 0, "因果": 0}

var full_text: String = ""
var shown_chars: int = 0
var typing: bool = false
var type_speed: float = 45.0
var _accum: float = 0.0
var current_bg: String = ""

const CHAR_PATH := "res://assets/chars/%s.png"
const CHOICE_BG := "res://assets/ui/choice_bg.png"
const SPEAKER_COLOR := {
	"旁白": Color(0.82, 0.8, 0.72),
	"店伙计": Color(0.95, 0.8, 0.55),
	"老黄头": Color(0.92, 0.72, 0.48),
	"萧索": Color(0.62, 0.82, 1.0),
	"萧索（内心）": Color(0.62, 0.82, 1.0),
	"女修": Color(0.65, 0.95, 0.82),
	"系统": Color(0.98, 0.84, 0.5),
}

@onready var bg: TextureRect = $BG
@onready var stage: Control = $Stage
@onready var title_label: Label = $TopBar/Title
@onready var aff_label: Label = $TopBar/Affinity
@onready var speaker: Label = $Speaker
@onready var text_label: RichTextLabel = $Dialogue/VBox/Text
@onready var hint: Label = $Dialogue/VBox/Hint
@onready var choices_box: VBoxContainer = $Dialogue/VBox/Choices
@onready var loc_label: Label = $LocationTag

func _ready() -> void:
	var f: FileAccess = FileAccess.open("res://data/ch1.json", FileAccess.READ)
	var data: Variant = JSON.parse_string(f.get_as_text())
	scenes = data["scenes"]
	title_label.text = str(data.get("title", ""))
	_update_affinity()
	_show(idx)

func _update_affinity() -> void:
	aff_label.text = "求知 %d   体面 %d   因果 %d" % [affinity["求知"], affinity["体面"], affinity["因果"]]

func _show(i: int) -> void:
	for c in stage.get_children():
		c.queue_free()
	for c in choices_box.get_children():
		c.queue_free()
	var s: Dictionary = scenes[i]
	var bg_path: String = str(s.get("bg", ""))
	if bg_path != current_bg:
		current_bg = bg_path
		_fade_bg(bg_path)
	else:
		bg.texture = load(bg_path)
	_spawn_chars(s)
	var sp: String = str(s.get("speaker", ""))
	speaker.text = sp
	speaker.add_theme_color_override("font_color", SPEAKER_COLOR.get(sp, Color(1, 1, 1)))
	full_text = str(s.get("text", ""))
	shown_chars = 0
	typing = true
	_accum = 0.0
	text_label.text = ""
	loc_label.text = _loc_name(bg_path)
	loc_label.visible = true
	var tw: Tween = create_tween()
	loc_label.modulate.a = 0.0
	tw.tween_property(loc_label, "modulate:a", 1.0, 0.4)
	tw.tween_interval(1.2)
	tw.tween_property(loc_label, "modulate:a", 0.0, 0.6)
	if s.has("choice"):
		hint.visible = false
		var choice_tex: Texture2D = load(CHOICE_BG)
		for opt in s["choice"]:
			var b := Button.new()
			b.text = "◆  " + str(opt["label"])
			b.alignment = HORIZONTAL_ALIGNMENT_LEFT
			b.add_theme_font_size_override("font_size", 24)
			b.add_theme_color_override("font_color", Color(0.96, 0.9, 0.76))
			b.add_theme_color_override("font_hover_color", Color(1.0, 0.95, 0.8))
			b.custom_minimum_size = Vector2(1000, 64)
			var sb := StyleBoxTexture.new()
			sb.texture = choice_tex
			sb.content_margin_left = 56.0
			sb.content_margin_right = 20.0
			sb.content_margin_top = 8.0
			sb.content_margin_bottom = 8.0
			b.add_theme_stylebox_override("normal", sb)
			b.add_theme_stylebox_override("hover", sb)
			b.add_theme_stylebox_override("pressed", sb)
			b.add_theme_stylebox_override("focus", sb)
			b.pressed.connect(_on_choice.bind(opt))
			choices_box.add_child(b)
		typing = false
		text_label.text = full_text
	else:
		hint.visible = true

func _loc_name(bg_path: String) -> String:
	if "shop" in bg_path:
		return "黄狗县 · 卤鸡脚店"
	if "dark" in bg_path:
		return "小黑屋 · 深夜"
	if "forest" in bg_path:
		return "树林 · 两年半前"
	return ""

func _fade_bg(path: String) -> void:
	var tw: Tween = create_tween()
	tw.tween_property(bg, "modulate:a", 0.0, 0.25)
	tw.tween_callback(func() -> void:
		bg.texture = load(path)
		bg.modulate.a = 0.0
		var tw2: Tween = create_tween()
		tw2.tween_property(bg, "modulate:a", 1.0, 0.45)
	)

func _spawn_chars(s: Dictionary) -> void:
	var names: Array = s.get("chars", [])
	var focus: String = str(s.get("focus", ""))
	var n: int = names.size()
	for k in range(n):
		var char_name: String = str(names[k])
		var holder := Control.new()
		holder.custom_minimum_size = Vector2(340, 560)
		holder.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var shadow := ColorRect.new()
		shadow.color = Color(0, 0, 0, 0.35)
		shadow.position = Vector2(60, 500)
		shadow.size = Vector2(220, 34)
		shadow.mouse_filter = Control.MOUSE_FILTER_IGNORE
		holder.add_child(shadow)
		var tr := TextureRect.new()
		tr.texture = load(CHAR_PATH % char_name)
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tr.custom_minimum_size = Vector2(340, 510)
		tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		holder.add_child(tr)
		var pos_x: float
		if n == 1:
			pos_x = 470.0
		elif n == 2:
			pos_x = 280.0 if k == 0 else 660.0
		else:
			pos_x = 130.0 + k * 340.0
		holder.position = Vector2(pos_x, 60)
		holder.size = Vector2(340, 560)
		if focus != "" and char_name != focus:
			holder.modulate = Color(0.45, 0.45, 0.5, 1.0)
		else:
			holder.modulate = Color(1, 1, 1, 0)
		stage.add_child(holder)
		var tw: Tween = create_tween().set_parallel(true)
		tw.tween_property(holder, "modulate:a", 1.0 if (focus == "" or char_name == focus) else 0.85, 0.4)
		tw.tween_property(holder, "position:y", 40.0, 0.4).from(70.0)
		var target_scale := Vector2(1.04, 1.04) if (focus == "" or char_name == focus) else Vector2(0.96, 0.96)
		holder.pivot_offset = Vector2(170, 560)
		tw.tween_property(holder, "scale", target_scale, 0.4)

func _process(delta: float) -> void:
	if not typing:
		return
	_accum += delta * type_speed
	var target: int = int(_accum)
	if target > shown_chars:
		shown_chars = mini(target, full_text.length())
		text_label.text = full_text.left(shown_chars)
		if shown_chars >= full_text.length():
			typing = false
			hint.text = "▼ 点击 / 空格继续"

func _advance() -> void:
	if typing:
		shown_chars = full_text.length()
		text_label.text = full_text
		typing = false
		hint.text = "▼ 点击 / 空格继续"
		return
	var s: Dictionary = scenes[idx]
	if s.has("choice"):
		return
	if idx < scenes.size() - 1:
		idx += 1
		hint.text = "···"
		_show(idx)

func _on_choice(opt: Dictionary) -> void:
	for k in (opt.get("affinity", {}) as Dictionary).keys():
		affinity[k] = int(affinity.get(k, 0)) + int(opt["affinity"][k])
	_update_affinity()
	speaker.text = "系统"
	speaker.add_theme_color_override("font_color", SPEAKER_COLOR["系统"])
	full_text = "你选择了【%s】\n属性已更新：%s\nDemo完，可重播第一章。" % [str(opt["label"]), str(affinity)]
	text_label.text = full_text
	typing = false
	for c in choices_box.get_children():
		c.queue_free()
	hint.visible = false

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event
		if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			_advance()
	elif event is InputEventKey:
		var ke: InputEventKey = event
		if ke.pressed and not ke.echo and (ke.keycode == KEY_SPACE or ke.keycode == KEY_ENTER):
			_advance()
