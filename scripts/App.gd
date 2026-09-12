extends Control
## 엔트리 씬. 타이틀 ↔ S1 미션. HUD 점멸은 업글 버튼만.

const FONT_PATH := "res://assets/fonts/NotoSansKR-Regular.ttf"

const CombatEngineScript = preload("res://scripts/CombatEngine.gd")

var engine = CombatEngineScript.new()
var font: Font
var screen := "title"
var blink_t := 0.0
var toast_text := ""
var toast_t := 0.0
var shortage_t := 0.0

var title_root: Control
var mission_root: Control
var arena: Node2D
var arena_host: Control

var lab_supply: Label
var lab_goal: Label
var lab_zone: Label
var lab_hp: Label
var lab_ammo: Label
var lab_scrap: Label
var lab_stats: Label
var lab_toast: Label
var btn_upgrade: Button
var btn_auto: Button
var overlay: ColorRect
var overlay_box: VBoxContainer
var overlay_title: Label
var overlay_body: Label
var overlay_primary: Button
var overlay_secondary: Button
var choice_box: VBoxContainer
var overlay_mode := ""


func _ready() -> void:
	set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	font = load(FONT_PATH)
	_build_chrome()
	_build_title()
	_build_mission()
	engine.toast.connect(_on_toast)
	engine.first_kill.connect(_on_first_kill)
	engine.player_died.connect(_on_fail)
	engine.run_cleared.connect(_on_clear)
	engine.upgrade_resolved.connect(_on_upgrade)
	engine.needs_armory_choice.connect(_show_choice)
	engine.zone_changed.connect(func(_i: int) -> void: _sync_hud())
	_show_title()


func _process(delta: float) -> void:
	blink_t += delta
	if toast_t > 0.0:
		toast_t = maxf(0.0, toast_t - delta)
		lab_toast.modulate.a = clampf(toast_t / 0.25, 0.0, 1.0) if toast_t < 0.25 else 1.0
	if shortage_t > 0.0:
		shortage_t = maxf(0.0, shortage_t - delta)
		lab_scrap.modulate = Color(1.0, 0.35, 0.35).lerp(Color.WHITE, 1.0 - shortage_t)
	if screen == "mission":
		if not overlay.visible:
			engine.process(delta)
			if Input.is_key_pressed(KEY_SPACE):
				_do_tap()
		_sync_hud()
		_blink_upgrade_only()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and screen == "mission" and overlay.visible:
		return
	if screen == "title" and event.is_action_pressed("ui_accept"):
		_start_mission()
		return
	if screen != "mission" or overlay.visible:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if _is_arena_click(event.position):
			_do_tap()
	elif event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_SPACE:
			_do_tap()
		elif event.keycode == KEY_U:
			_on_upgrade_pressed()
		elif event.keycode == KEY_A:
			_toggle_auto()


func _is_arena_click(pos: Vector2) -> bool:
	if arena_host == null:
		return false
	return arena_host.get_global_rect().has_point(pos)


func _do_tap() -> void:
	if engine.tap_fire():
		arena.kick(true)


func _font_var(size: int, bold: bool = false) -> FontVariation:
	var fv := FontVariation.new()
	fv.base_font = font
	fv.variation_opentype = {0x77676874: 700 if bold else 500}
	return fv


func _label(text: String, size: int, color: Color, bold: bool = false) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_override("font", _font_var(size, bold))
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	return l


func _button(text: String, size: int = 20) -> Button:
	var b := Button.new()
	b.text = text
	b.add_theme_font_override("font", _font_var(size, true))
	b.add_theme_font_size_override("font_size", size)
	b.add_theme_color_override("font_color", Color(0.07, 0.09, 0.1))
	b.add_theme_color_override("font_hover_color", Color(0.07, 0.09, 0.1))
	b.add_theme_color_override("font_pressed_color", Color(0.07, 0.09, 0.1))
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.84, 0.89, 0.29)
	sb.corner_radius_top_left = 6
	sb.corner_radius_top_right = 6
	sb.corner_radius_bottom_left = 6
	sb.corner_radius_bottom_right = 6
	sb.content_margin_left = 18
	sb.content_margin_right = 18
	sb.content_margin_top = 10
	sb.content_margin_bottom = 10
	b.add_theme_stylebox_override("normal", sb)
	var sbh := sb.duplicate()
	sbh.bg_color = Color(0.93, 0.96, 0.5)
	b.add_theme_stylebox_override("hover", sbh)
	b.add_theme_stylebox_override("pressed", sbh)
	var sbd := sb.duplicate()
	sbd.bg_color = Color(0.28, 0.3, 0.32)
	b.add_theme_stylebox_override("disabled", sbd)
	return b


func _ghost_button(text: String, size: int = 18) -> Button:
	var b := _button(text, size)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.16, 0.2, 0.24, 0.95)
	sb.border_color = Color(0.24, 0.89, 0.78, 0.5)
	sb.set_border_width_all(1)
	sb.corner_radius_top_left = 6
	sb.corner_radius_top_right = 6
	sb.corner_radius_bottom_left = 6
	sb.corner_radius_bottom_right = 6
	sb.content_margin_left = 16
	sb.content_margin_right = 16
	sb.content_margin_top = 8
	sb.content_margin_bottom = 8
	b.add_theme_stylebox_override("normal", sb)
	b.add_theme_color_override("font_color", Color(0.86, 0.91, 0.93))
	b.add_theme_color_override("font_hover_color", Color.WHITE)
	return b


func _build_chrome() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.043, 0.055, 0.07)
	bg.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	add_child(bg)


func _build_title() -> void:
	title_root = Control.new()
	title_root.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	add_child(title_root)
	var title_bg := ColorRect.new()
	title_bg.color = Color(0.043, 0.055, 0.07)
	title_bg.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	title_root.add_child(title_bg)

	var col := VBoxContainer.new()
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_theme_constant_override("separation", 10)
	col.set_anchors_preset(PRESET_FULL_RECT)
	col.offset_left = 80
	col.offset_right = -80
	title_root.add_child(col)

	var tag := _label("S1  ·  %s" % Balance.ZONE_NAME, 18, Color(0.24, 0.89, 0.78))
	tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(tag)

	var title := _label(Balance.PUBLIC_TITLE, 56, Color(0.96, 0.96, 0.9), true)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(title)

	var mission := _label(Balance.MISSION_NAME, 28, Color(0.84, 0.89, 0.29), true)
	mission.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(mission)

	var rule := ColorRect.new()
	rule.custom_minimum_size = Vector2(280, 3)
	rule.color = Color(0.84, 0.89, 0.29, 0.7)
	rule.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	col.add_child(rule)

	var brief := _label("탭으로 감염원을 처치하고, 스크랩으로 업글1을 장착하라.\n무기고에서 화력 또는 탄약효율 중 하나만 고른 뒤 비상구 B1을 확보한다.", 16, Color(0.7, 0.76, 0.8))
	brief.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(brief)

	lab_supply = _label("", 20, Color(0.24, 0.89, 0.78), true)
	lab_supply.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(lab_supply)

	var start := _button("작전 개시", 24)
	start.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	start.pressed.connect(_start_mission)
	col.add_child(start)

	var hint := _label("클릭 / Enter  ·  전투 중 Space 사격  ·  U 업글  ·  A 자동", 14, Color(0.45, 0.5, 0.55))
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(hint)


func _band(color: Color, height: float) -> ColorRect:
	var band := ColorRect.new()
	band.color = color
	band.custom_minimum_size = Vector2(0, height)
	band.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return band


func _build_mission() -> void:
	mission_root = Control.new()
	mission_root.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	mission_root.visible = false
	add_child(mission_root)

	var vbox := VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 0)
	mission_root.add_child(vbox)

	var top := _band(Color(0.07, 0.09, 0.12, 0.96), 52)
	vbox.add_child(top)
	var top_row := HBoxContainer.new()
	top_row.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	top_row.offset_left = 20
	top_row.offset_right = -20
	top_row.add_theme_constant_override("separation", 16)
	top.add_child(top_row)
	lab_goal = _label("", 20, Color(0.96, 0.96, 0.9), true)
	lab_goal.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_row.add_child(lab_goal)
	lab_zone = _label("", 16, Color(0.24, 0.89, 0.78))
	lab_zone.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	top_row.add_child(lab_zone)

	var stats := _band(Color(0.09, 0.11, 0.14, 0.94), 48)
	vbox.add_child(stats)
	var stat_row := HBoxContainer.new()
	stat_row.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	stat_row.offset_left = 20
	stat_row.offset_right = -20
	stat_row.add_theme_constant_override("separation", 20)
	stats.add_child(stat_row)
	lab_hp = _label("", 18, Color(0.24, 0.88, 0.78))
	stat_row.add_child(lab_hp)
	lab_ammo = _label("", 18, Color(0.84, 0.89, 0.29))
	stat_row.add_child(lab_ammo)
	lab_scrap = _label("", 18, Color(0.95, 0.95, 0.9))
	stat_row.add_child(lab_scrap)
	lab_stats = _label("", 16, Color(0.7, 0.76, 0.8))
	lab_stats.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lab_stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	stat_row.add_child(lab_stats)

	arena_host = Control.new()
	arena_host.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	arena_host.size_flags_vertical = Control.SIZE_EXPAND_FILL
	arena_host.clip_contents = true
	arena_host.custom_minimum_size = Vector2(0, 280)
	vbox.add_child(arena_host)
	arena = preload("res://scripts/ArenaView.gd").new()
	arena.engine = engine
	arena_host.add_child(arena)

	var bar := _band(Color(0.07, 0.09, 0.12, 0.97), 72)
	vbox.add_child(bar)
	var bar_row := HBoxContainer.new()
	bar_row.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	bar_row.offset_left = 16
	bar_row.offset_right = -16
	bar_row.offset_top = 10
	bar_row.offset_bottom = -10
	bar_row.add_theme_constant_override("separation", 12)
	bar.add_child(bar_row)
	btn_upgrade = _button("업그레이드", 20)
	btn_upgrade.custom_minimum_size = Vector2(200, 48)
	btn_upgrade.pressed.connect(_on_upgrade_pressed)
	bar_row.add_child(btn_upgrade)
	btn_auto = _ghost_button("자동 잠김", 18)
	btn_auto.custom_minimum_size = Vector2(140, 42)
	btn_auto.disabled = true
	btn_auto.pressed.connect(_toggle_auto)
	bar_row.add_child(btn_auto)
	var tap_hint := _label("아레나 클릭 또는 Space — 탭 처치", 15, Color(0.55, 0.6, 0.64))
	tap_hint.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar_row.add_child(tap_hint)
	var back := _ghost_button("철수", 16)
	back.pressed.connect(_show_title)
	bar_row.add_child(back)

	lab_toast = _label("", 16, Color(0.84, 0.89, 0.29), true)
	lab_toast.custom_minimum_size = Vector2(0, 88)
	lab_toast.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(lab_toast)

	_build_overlay()


func _build_overlay() -> void:
	overlay = ColorRect.new()
	overlay.color = Color(0.02, 0.03, 0.04, 0.78)
	overlay.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	overlay.visible = false
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	mission_root.add_child(overlay)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(center)

	overlay_box = VBoxContainer.new()
	overlay_box.alignment = BoxContainer.ALIGNMENT_CENTER
	overlay_box.add_theme_constant_override("separation", 12)
	overlay_box.custom_minimum_size = Vector2(640, 0)
	center.add_child(overlay_box)

	overlay_title = _label("", 32, Color(0.96, 0.96, 0.9), true)
	overlay_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	overlay_box.add_child(overlay_title)

	overlay_body = _label("", 18, Color(0.78, 0.82, 0.84))
	overlay_body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	overlay_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	overlay_box.add_child(overlay_body)

	choice_box = VBoxContainer.new()
	choice_box.add_theme_constant_override("separation", 10)
	choice_box.visible = false
	overlay_box.add_child(choice_box)

	var fire := _button("화력  —  공격력 ×%.2f" % Balance.UPGRADE1_FIREPOWER_MULT, 20)
	fire.pressed.connect(func() -> void: _pick(CombatEngineScript.UPGRADE_FIREPOWER))
	choice_box.add_child(fire)

	var ammo := _button("탄약효율  —  탄소모 ×%.2f · 탄창 +%.0f" % [Balance.UPGRADE1_AMMO_COST_MULT, Balance.UPGRADE1_AMMO_MAG_BONUS], 20)
	ammo.pressed.connect(func() -> void: _pick(CombatEngineScript.UPGRADE_AMMO_EFF))
	choice_box.add_child(ammo)

	var only := _label("하나만 선택한다. 선택 후 자동 사격이 해금된다.", 14, Color(0.55, 0.6, 0.64))
	only.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	choice_box.add_child(only)

	overlay_primary = _button("확인", 20)
	overlay_primary.pressed.connect(_on_overlay_primary)
	overlay_box.add_child(overlay_primary)

	overlay_secondary = _ghost_button("재도전", 18)
	overlay_secondary.pressed.connect(_on_overlay_secondary)
	overlay_box.add_child(overlay_secondary)


func _show_title() -> void:
	screen = "title"
	title_root.visible = true
	mission_root.visible = false
	overlay.visible = false
	var sl := MetaSave.supply_level
	if sl >= Balance.SUPPLY_LEVEL_ON_CLEAR:
		lab_supply.text = "보급 레벨 %d 해금됨" % sl
	else:
		lab_supply.text = "보급 레벨 0  ·  S1 클리어 시 레벨 1 해금"


func _start_mission() -> void:
	screen = "mission"
	title_root.visible = false
	mission_root.visible = true
	overlay.visible = false
	choice_box.visible = false
	engine.start_run(MetaSave.supply_level, false)
	arena.engine = engine
	_sync_hud()
	_on_toast("목표 상시 표시: %s" % Balance.FINAL_GOAL)


func _sync_hud() -> void:
	lab_goal.text = "%s  ·  목표: %s" % [Balance.MISSION_NAME, engine.zone_goal()]
	lab_zone.text = "%s / %s  ·  %d/%d" % [Balance.STAGE_ID, engine.zone_name(), engine.zone_index + 1, Balance.ZONE_COUNT]
	lab_hp.text = "체력  %.0f / %.0f" % [engine.player.hp, engine.player.max_hp]
	var reload := "  재장전" if engine.reload_left > 0.0 else ""
	lab_ammo.text = "탄약  %.1f / %.0f%s" % [engine.player.ammo, engine.magazine(), reload]
	lab_scrap.text = "스크랩  %d" % engine.scrap
	if shortage_t <= 0.0:
		lab_scrap.modulate = Color.WHITE
	lab_stats.text = "화력 %.1f   탄소모 %.2f" % [engine.damage(), engine.ammo_cost()]
	btn_upgrade.disabled = engine.upgrade_bought
	if engine.upgrade_bought:
		var name := "화력" if engine.upgrade_kind == CombatEngineScript.UPGRADE_FIREPOWER else "탄약효율"
		btn_upgrade.text = "업글1 완료 · %s" % name
	else:
		btn_upgrade.text = "업그레이드  ·  %d 스크랩" % Balance.UPGRADE1_SCRAP_COST
	if engine.auto_unlocked:
		btn_auto.disabled = false
		btn_auto.text = "자동 ON" if engine.auto_on else "자동 OFF"
	else:
		btn_auto.disabled = true
		btn_auto.text = "자동 잠김"


func _blink_upgrade_only() -> void:
	# 다른 HUD는 점멸하지 않는다. 업글 버튼만, 구매 가능할 때.
	if engine.can_afford_upgrade() and not overlay.visible:
		var pulse := 0.5 + 0.5 * sin(blink_t * 9.0)
		btn_upgrade.modulate = Color(1, 1, 0.55 + 0.45 * pulse, 1)
	else:
		btn_upgrade.modulate = Color.WHITE


func _on_upgrade_pressed() -> void:
	if engine.upgrade_bought:
		return
	var result := engine.try_upgrade_open()
	if result == "poor":
		shortage_t = 1.0
		_on_toast("스크랩 부족  ·  %d 필요" % Balance.UPGRADE1_SCRAP_COST)
		return
	if result == "ok":
		_show_choice()


func _show_choice() -> void:
	overlay_mode = "choice"
	overlay.visible = true
	choice_box.visible = true
	overlay_primary.visible = false
	overlay_secondary.visible = false
	overlay_title.text = "업글1  ·  무기고"
	overlay_body.text = "화력과 탄약효율 중 하나만 고른다. 비용 %d 스크랩." % Balance.UPGRADE1_SCRAP_COST


func _pick(kind: int) -> void:
	if engine.choose_upgrade(kind):
		overlay.visible = false
		choice_box.visible = false
		_sync_hud()


func _toggle_auto() -> void:
	if not engine.auto_unlocked:
		return
	engine.set_auto(not engine.auto_on)
	_sync_hud()


func _on_toast(text: String) -> void:
	toast_text = text
	toast_t = 4.0
	if engine.toast_log.is_empty():
		lab_toast.text = text
	else:
		lab_toast.text = "\n".join(engine.toast_log)
	lab_toast.modulate.a = 1.0


func _on_first_kill(sec: float) -> void:
	arena.kick(false)
	_on_toast("처치 피드백  %.1f초  ·  스크랩 확보" % sec)


func _on_upgrade(_kind: int) -> void:
	_sync_hud()


func _on_fail() -> void:
	overlay_mode = "fail"
	overlay.visible = true
	choice_box.visible = false
	overlay_title.text = "작전 실패"
	if MetaSave.ibeonman_available:
		overlay_body.text = "첫 실패. 「이번만」 긴급 보급 카드를 1회 사용할 수 있다."
		overlay_primary.visible = true
		overlay_primary.text = "「이번만」"
		overlay_secondary.visible = true
		overlay_secondary.text = "재도전"
	else:
		overlay_body.text = "재도전 마찰 없음. 즉시 다시 로비부터 시작한다."
		overlay_primary.visible = false
		overlay_secondary.visible = true
		overlay_secondary.text = "재도전"


func _on_clear() -> void:
	var first := MetaSave.unlock_supply_on_clear()
	overlay_mode = "clear"
	overlay.visible = true
	choice_box.visible = false
	overlay_title.text = "비상구 B1 확보"
	if first:
		overlay_body.text = "정식 클리어. 보급 레벨 1 해금.\n상점 / 가챠 / 오프라인은 노출하지 않는다."
	else:
		overlay_body.text = "클리어. 보급 레벨 %d 유지." % MetaSave.supply_level
	overlay_primary.visible = true
	overlay_primary.text = "복귀"
	overlay_secondary.visible = true
	overlay_secondary.text = "다시 작전"


func _on_overlay_primary() -> void:
	if overlay_mode == "fail" and MetaSave.ibeonman_available:
		MetaSave.consume_ibeonman()
		overlay.visible = false
		engine.start_run(MetaSave.supply_level, true)
		_on_toast("「이번만」 소모  ·  긴급 보급 적용 후 재도전")
		_sync_hud()
	elif overlay_mode == "clear":
		_show_title()


func _on_overlay_secondary() -> void:
	if overlay_mode == "fail" or overlay_mode == "clear":
		overlay.visible = false
		engine.start_run(MetaSave.supply_level, false)
		_sync_hud()
		_on_toast("재도전  ·  로비부터")
