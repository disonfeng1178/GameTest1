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
const STORY_PATH := "res://data/story.json"
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
@onready var mono_layer: Control = $MonoLayer
@onready var mono_title: Label = $MonoLayer/Center/Title
@onready var mono_text: Label = $MonoLayer/Center/Text
@onready var mono_hint: Label = $MonoLayer/Center/Hint
@onready var text_label: RichTextLabel = $Dialogue/VBox/Text
@onready var hint: Label = $Dialogue/VBox/Hint
@onready var choices_box: VBoxContainer = $Dialogue/VBox/Choices
@onready var loc_label: Label = $LocationTag
@onready var bgm_main: AudioStreamPlayer = $BGMMain
@onready var bgm_tense: AudioStreamPlayer = $BGMTense
@onready var sfx_advance: AudioStreamPlayer = $SFXAdvance
@onready var sfx_select: AudioStreamPlayer = $SFXSelect
@onready var sfx_mono: AudioStreamPlayer = $SFXMono
@onready var sfx_chapter: AudioStreamPlayer = $SFXChapter
@onready var sfx_death: AudioStreamPlayer = $SFXDeath
@onready var sfx_clear: AudioStreamPlayer = $SFXClear
var _last_chapter: String = ""
var _tense_on: bool = false

func _ready() -> void:
	_load_story()

func _load_story() -> void:
	var f: FileAccess = FileAccess.open(STORY_PATH, FileAccess.READ)
	var data: Variant = JSON.parse_string(f.get_as_text())
	scenes = data["scenes"]
	title_label.text = str(data.get("title", ""))
	idx = 0
	affinity = {"求知": 0, "体面": 0, "因果": 0}
	current_bg = ""
	_last_chapter = ""
	_tense_on = false
	_update_affinity()
	_show(idx)
	_play_bgm(false)

func _play_bgm(tense: bool) -> void:
	if tense == _tense_on and (bgm_main.playing or bgm_tense.playing):
		return
	_tense_on = tense
	if tense:
		bgm_main.stop()
		if not bgm_tense.playing:
			bgm_tense.play()
	else:
		bgm_tense.stop()
		if not bgm_main.playing:
			bgm_main.play()

func _is_tense_scene(s: Dictionary) -> bool:
	var ch: String = str(s.get("chapter", ""))
	if s.get("mono", false):
		var t: String = str(s.get("mono_title", ""))
		return "预警" in t
	if opt_death_ahead(s):
		return true
	return ch in ["第六章 突然的劫杀", "第七章 六旬老汉大显威风", "第八章 总有人想害我"]

func opt_death_ahead(s: Dictionary) -> bool:
	if not s.has("choice"):
		return false
	for opt in s["choice"]:
		if (opt as Dictionary).has("death"):
			return true
	return false

func _update_affinity() -> void:
	aff_label.text = "求知 %d   体面 %d   因果 %d" % [affinity["求知"], affinity["体面"], affinity["因果"]]

func _clear_mono_choices() -> void:
	var center: Control = mono_layer.get_node("Center")
	for c in center.get_children():
		if c is Button:
			c.queue_free()
	mono_hint.visible = true

func _make_choice_button(opt: Dictionary) -> Button:
	var b := Button.new()
	b.text = "◆  " + str(opt["label"])
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.add_theme_font_size_override("font_size", 24)
	b.add_theme_color_override("font_color", Color(0.96, 0.9, 0.76))
	b.add_theme_color_override("font_hover_color", Color(1.0, 0.95, 0.8))
	b.custom_minimum_size = Vector2(1000, 64)
	var sb := StyleBoxTexture.new()
	sb.texture = load(CHOICE_BG)
	sb.content_margin_left = 56.0
	sb.content_margin_right = 20.0
	sb.content_margin_top = 8.0
	sb.content_margin_bottom = 8.0
	b.add_theme_stylebox_override("normal", sb)
	b.add_theme_stylebox_override("hover", sb)
	b.add_theme_stylebox_override("pressed", sb)
	b.add_theme_stylebox_override("focus", sb)
	b.mouse_entered.connect(func() -> void:
		var t: Tween = b.create_tween()
		t.tween_property(b, "scale", Vector2(1.02, 1.02), 0.12)
	)
	b.mouse_exited.connect(func() -> void:
		var t: Tween = b.create_tween()
		t.tween_property(b, "scale", Vector2.ONE, 0.12)
	)
	b.pressed.connect(_on_choice.bind(opt))
	return b

func _spawn_choices_in(s: Dictionary, parent: Control) -> void:
	for opt in s["choice"]:
		parent.add_child(_make_choice_button(opt))

func _show(i: int) -> void:
	for c in stage.get_children():
		c.queue_free()
	for c in choices_box.get_children():
		c.queue_free()
	_clear_mono_choices()
	var s: Dictionary = scenes[i]
	mono_layer.visible = bool(s.get("mono", false))
	_play_bgm(_is_tense_scene(s))
	var ch0: String = str(s.get("chapter", ""))
	if ch0 != "" and ch0 != _last_chapter and not s.get("mono", false):
		_last_chapter = ch0
		sfx_chapter.play()
	if mono_layer.visible:
		bg.modulate = Color(1, 1, 1, 1)
		sfx_mono.play()
		mono_title.text = str(s.get("mono_title", "【 独白 】"))
		mono_text.text = str(s.get("text", ""))
		mono_hint.text = "···"
		speaker.text = ""
		text_label.text = ""
		hint.visible = true
		loc_label.visible = false
		typing = false
		if s.has("choice"):
			mono_hint.visible = false
			_spawn_choices_in(s, mono_layer.get_node("Center"))
		return
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
	var ch: String = str(s.get("chapter", ""))
	var loc: String = _loc_name(bg_path)
	loc_label.text = (ch + " · " + loc) if ch != "" else loc
	loc_label.visible = true
	var tw: Tween = create_tween()
	loc_label.modulate.a = 0.0
	tw.tween_property(loc_label, "modulate:a", 1.0, 0.4)
	tw.tween_interval(1.2)
	tw.tween_property(loc_label, "modulate:a", 0.0, 0.6)
	if s.has("choice"):
		hint.visible = false
		for opt in s["choice"]:
			choices_box.add_child(_make_choice_button(opt))
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
		bg.scale = Vector2(1.06, 1.06)
		bg.pivot_offset = Vector2(960, 540)
		var tw2: Tween = create_tween().set_parallel(true)
		tw2.tween_property(bg, "modulate:a", 1.0, 0.45)
		tw2.tween_property(bg, "scale", Vector2.ONE, 2.5).set_trans(Tween.TRANS_SINE)
	)

func _spawn_chars(s: Dictionary) -> void:
	var names: Array = s.get("chars", [])
	var focus: String = str(s.get("focus", ""))
	var n: int = names.size()
	var vw: float = 1920.0
	for k in range(n):
		var char_name: String = str(names[k])
		var holder := Control.new()
		holder.custom_minimum_size = Vector2(300, 620)
		holder.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var shadow := ColorRect.new()
		shadow.color = Color(0, 0, 0, 0.35)
		shadow.position = Vector2(55, 560)
		shadow.size = Vector2(190, 30)
		shadow.mouse_filter = Control.MOUSE_FILTER_IGNORE
		holder.add_child(shadow)
		var tr := TextureRect.new()
		tr.texture = load(CHAR_PATH % char_name)
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tr.custom_minimum_size = Vector2(300, 560)
		tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		holder.add_child(tr)
		var pos_x: float
		if n == 1:
			pos_x = vw / 2.0 - 150.0
		elif n == 2:
			pos_x = vw / 2.0 - 380.0 if k == 0 else vw / 2.0 + 80.0
		else:
			pos_x = vw / 2.0 - float(n) * 170.0 + k * 340.0
		holder.position = Vector2(pos_x, 130)
		holder.size = Vector2(300, 620)
		if focus != "" and char_name != focus:
			holder.modulate = Color(0.45, 0.45, 0.5, 1.0)
		else:
			holder.modulate = Color(1, 1, 1, 0)
		stage.add_child(holder)
		var tw: Tween = create_tween().set_parallel(true)
		tw.tween_property(holder, "modulate:a", 1.0 if (focus == "" or char_name == focus) else 0.85, 0.4)
		tw.tween_property(holder, "position:y", 110.0, 0.4).from(140.0)
		var target_scale := Vector2(1.04, 1.04) if (focus == "" or char_name == focus) else Vector2(0.96, 0.96)
		holder.pivot_offset = Vector2(150, 620)
		tw.tween_property(holder, "scale", target_scale, 0.4)
		if focus == "" or char_name == focus:
			_breathe(holder)

func _breathe(holder: Control) -> void:
	var tw: Tween = create_tween().set_loops()
	tw.tween_property(holder, "position:y", 104.0, 2.2).set_trans(Tween.TRANS_SINE)
	tw.tween_property(holder, "position:y", 110.0, 2.2).set_trans(Tween.TRANS_SINE)

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
		sfx_advance.play()
		_show(idx)

func _on_choice(opt: Dictionary) -> void:
	if bool(opt.get("restart", false)):
		_load_story()
		return
	if bool(opt.get("ending", false)):
		sfx_clear.play()
		_play_bgm(false)
		speaker.text = "系统"
		speaker.add_theme_color_override("font_color", SPEAKER_COLOR["系统"])
		full_text = "通关！属性：%s\n再开一局请重进。" % [str(affinity)]
		text_label.text = full_text
		typing = false
		for c in choices_box.get_children():
			c.queue_free()
		hint.visible = false
		return
	if opt.has("death"):
		_die(str(opt["death"]))
		return
	sfx_select.play()
	for k in (opt.get("affinity", {}) as Dictionary).keys():
		affinity[k] = int(affinity.get(k, 0)) + int(opt["affinity"][k])
	_update_affinity()
	mono_layer.visible = false
	_clear_mono_choices()
	speaker.text = "系统"
	speaker.add_theme_color_override("font_color", SPEAKER_COLOR["系统"])
	full_text = "你选择了【%s】\n属性已更新：%s" % [str(opt["label"]), str(affinity)]
	text_label.text = full_text
	typing = false
	for c in choices_box.get_children():
		c.queue_free()
	hint.visible = false

func _die(reason: String) -> void:
	for c in choices_box.get_children():
		c.queue_free()
	_clear_mono_choices()
	for c in stage.get_children():
		c.queue_free()
	mono_layer.visible = false
	_play_bgm(false)
	sfx_death.play()
	bg.modulate = Color(0.35, 0.05, 0.05, 1.0)
	speaker.text = "☠ 你死了"
	speaker.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))
	full_text = reason
	text_label.text = full_text
	typing = false
	hint.visible = false
	var b := Button.new()
	b.text = "◆  从头再来"
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.add_theme_font_size_override("font_size", 24)
	b.add_theme_color_override("font_color", Color(1.0, 0.6, 0.6))
	b.custom_minimum_size = Vector2(1000, 64)
	var sb := StyleBoxTexture.new()
	sb.texture = load(CHOICE_BG)
	sb.content_margin_left = 56.0
	sb.content_margin_right = 20.0
	sb.content_margin_top = 8.0
	sb.content_margin_bottom = 8.0
	b.add_theme_stylebox_override("normal", sb)
	b.add_theme_stylebox_override("hover", sb)
	b.add_theme_stylebox_override("pressed", sb)
	b.add_theme_stylebox_override("focus", sb)
	b.pressed.connect(_on_restart)
	choices_box.add_child(b)

func _on_restart() -> void:
	bg.modulate = Color(1, 1, 1, 1)
	_load_story()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event
		if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			_advance()
	elif event is InputEventKey:
		var ke: InputEventKey = event
		if ke.pressed and not ke.echo and (ke.keycode == KEY_SPACE or ke.keycode == KEY_ENTER):
			_advance()
