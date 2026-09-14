extends Node
## S1 런타임 스크린샷 하네스.
##
## 목업이 아니다. `res://scenes/App.tscn` (실제 엔트리 씬)을 그대로 인스턴스화하고,
## 게임 자신의 입력 경로(`_start_mission` / `_do_tap` / `_on_upgrade_pressed` / `_pick`)로
## 상태를 몰아간 뒤 루트 뷰포트 프레임을 그대로 PNG로 저장한다.
##
## 실행:
##   DISPLAY=:1 godot --path . --resolution 1280x720 --fixed-fps 60 \
##     res://tools/CaptureShots.tscn -- --out=/abs/out/dir

const CE = preload("res://scripts/CombatEngine.gd")

## App.gd `_blink_upgrade_only()` 의 점멸 각속도. 점멸 골(=가장 노란 프레임)을 노린다.
const BLINK_RATE := 9.0
const FPS := 60.0

var app: Control
var out_dir := ""
var report: PackedStringArray = PackedStringArray()


func _ready() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			out_dir = arg.substr(6)
	if out_dir == "":
		push_error("CaptureShots: --out=<dir> 필요")
		get_tree().quit(2)
		return
	DirAccess.make_dir_recursive_absolute(out_dir)

	# 「이번만」 가용 + 보급 레벨 0 에서 시작해야 5번 샷이 성립한다.
	MetaSave.reset_for_tests()

	app = load("res://scenes/App.tscn").instantiate()
	add_child(app)
	await _frames(4)

	await _shot1_lobby_tap()
	await _shot2_upgrade_blink()
	await _shot3_armory_choice()
	await _shot4_parking_goal()
	await _shot5_ibeonman()

	print("\n=== CaptureShots report ===")
	for line in report:
		print(line)
	get_tree().quit(0)


# --- 프레임 / 시간 제어 -------------------------------------------------------

func _frames(count: int) -> void:
	for _i in range(count):
		await get_tree().process_frame


## 게임 시간 `seconds` 만큼 진행한다. `scale` 로 렌더 프레임 수를 줄인다.
func _advance(seconds: float, scale: float = 4.0) -> void:
	Engine.time_scale = scale
	await _frames(int(ceil(seconds * FPS / scale)))
	Engine.time_scale = 1.0


## 이번 프레임이 그려질 때 App 이 쓰게 될 점멸 위상.
func _blink_sin_next() -> float:
	return sin((app.blink_t + 1.0 / FPS) * BLINK_RATE)


## 점멸 골까지 남은 프레임 수.
func _frames_to_blink_trough() -> float:
	var phase := fposmod((app.blink_t + 1.0 / FPS) * BLINK_RATE, TAU)
	return fposmod(PI * 1.5 - phase, TAU) / (BLINK_RATE / FPS)


func _grab(file_name: String, note: String) -> void:
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	var path := out_dir.path_join(file_name)
	var err := img.save_png(path)
	var e = app.engine
	var auto_state := "잠김"
	if e.auto_unlocked:
		auto_state = "ON" if e.auto_on else "OFF"
	report.append("%s  %dx%d err=%d | %s" % [
		file_name, img.get_size().x, img.get_size().y, err, note,
	])
	report.append("    zone=%d(%s) wave=%d phase=%s scrap=%d hp=%.0f auto=%s upgrade=%s overlay=%s/%s ibeonman_left=%s" % [
		e.zone_index, e.zone_name(), e.wave_index, e.phase, e.scrap, e.player.hp,
		auto_state, str(e.upgrade_bought), str(app.overlay.visible), app.overlay_mode,
		str(MetaSave.ibeonman_available),
	])
	var alive: PackedStringArray = PackedStringArray()
	for en in e.living_enemies():
		alive.append("%s@%.0f" % [en.kind, en.x])
	report.append("    living=[%s]" % ", ".join(alive))


## 목표 조건이 만족될 때까지 실제 탭 사격으로 전투를 굴린다.
func _tap_until(cond: Callable, budget_frames: int, scale: float = 2.0) -> bool:
	Engine.time_scale = scale
	var guard := 0
	while guard < budget_frames:
		if cond.call():
			Engine.time_scale = 1.0
			return true
		if not app.overlay.visible:
			app._do_tap()
		await get_tree().process_frame
		guard += 1
	Engine.time_scale = 1.0
	return cond.call()


# --- 샷 1: 1-1 로비 탭 처치 (자동 미해금) ------------------------------------

func _shot1_lobby_tap() -> void:
	app._start_mission()
	await _frames(2)
	# 로비 웨이브 1 그런트가 화면 중앙으로 걸어 들어온다.
	await _advance(2.4)
	app._do_tap()
	# 웨이브 1 클리어 → 웨이브 2(그런트 2)가 우측에서 진입, 중앙까지 접근시킨다.
	await _advance(5.6)
	app._do_tap()
	# 머즐 플래시(0.17s)와 처치/스크랩 FX(0.4s)가 살아 있는 프레임.
	await _frames(2)
	await _grab("shot1_lobby.png", "S1 1-1 로비 · 탭 처치 + 처치/스크랩 FX · 자동 미해금")


# --- 샷 2: 업글 버튼 점멸 + 스크랩 부족 연출 ---------------------------------

func _shot2_upgrade_blink() -> void:
	# 남은 로비 그런트를 조금 더 접근시킨다. 이 시점 스크랩 8 < 12.
	await _advance(2.0)

	# 점멸 골이 2~5프레임 뒤에 오도록 위상을 맞춘다.
	# (부족 틴트는 1초에 걸쳐 사라지므로, 골에 최대한 붙여야 둘이 같이 진하게 잡힌다.)
	var guard := 0
	while guard < 200:
		var lead := _frames_to_blink_trough()
		if lead >= 2.0 and lead <= 5.0:
			break
		await get_tree().process_frame
		guard += 1

	# 부족 연출: 스크랩 8로 업글을 눌러 실제 "poor" 경로를 태운다.
	app._on_upgrade_pressed()
	# 같은 프레임에 마지막 로비 그런트를 처치해 스크랩 12(=구매 가능)로 올린다.
	# → 스크랩 라벨 부족 틴트가 남아 있는 동안 업글 버튼 점멸이 켜진다.
	app._do_tap()

	guard = 0
	while guard < 60 and _blink_sin_next() > -0.97:
		await get_tree().process_frame
		guard += 1
	await _grab("shot2_upgrade_blink.png", "업글 버튼 점멸(구매 가능) + 스크랩 라벨 부족 틴트")


# --- 샷 3: 무기고 선택 화력 vs 탄약효율 --------------------------------------

func _shot3_armory_choice() -> void:
	var reached := await _tap_until(
		func() -> bool: return app.overlay.visible and app.overlay_mode == "choice",
		1800,
	)
	if not reached:
		push_error("CaptureShots: 무기고 선택 오버레이 도달 실패")
	await _frames(2)
	await _grab("shot3_armory_choice.png", "무기고 · 화력 vs 탄약효율 (배타 선택)")


# --- 샷 4: 1-4 주차장 + 목표 카드(비상구) + 자동 ON -------------------------

func _shot4_parking_goal() -> void:
	# 무기고에서 화력을 고른다 → 게임이 목표 카드를 띄운다.
	app._pick(CE.UPGRADE_FIREPOWER)
	await _frames(2)
	# 목표 카드 확인 = 자동 해금(ON) + 다음 구역(주차장) 진입.
	# 오버레이를 닫는 버튼 핸들러 대신 엔진 API를 직접 호출해,
	# 목표 카드가 떠 있는 채로 HUD가 주차장 4/5 · 자동 ON 으로 갱신된 프레임을 얻는다.
	app.engine.acknowledge_goal_card()
	await _frames(3)
	await _grab("shot4_parking_goal.png", "S1 1-4 주차장 · 목표 카드 비상구 B1 + 자동 ON")


# --- 샷 5: 1-5 비상구 B1 실패 → 「이번만」 무료 부스트 카드 ------------------

func _shot5_ibeonman() -> void:
	# 목표 카드를 실제 버튼 경로로 닫는다.
	app._on_overlay_primary()
	await _frames(2)

	var reached := await _tap_until(
		func() -> bool: return app.engine.zone_index >= 4,
		2400,
	)
	if not reached:
		push_error("CaptureShots: 비상구 B1 구역 도달 실패")

	# B1 웨이브는 애드 2 + 보스다. 애드만 실제 탭으로 정리한다.
	var adds_cleared := await _tap_until(
		func() -> bool: return app.engine.living_enemies().size() <= 1,
		600,
	)
	if not adds_cleared:
		push_error("CaptureShots: B1 애드 정리 실패")

	# 사격을 멈추고 보스가 근접까지 걸어와 플레이어를 죽이게 둔다.
	# 체력 조작 없음 — 실패 판정은 실제 전투 틱(보스 근접 피해)이 낸다.
	app.engine.set_auto(false)
	app._sync_hud()
	var guard := 0
	Engine.time_scale = 8.0
	while guard < 900 and app.engine.phase != "fail":
		await get_tree().process_frame
		guard += 1
	Engine.time_scale = 1.0
	await _frames(3)
	await _grab("shot5_ibeonman.png", "S1 1-5 비상구 B1 첫 실패 → 「이번만」 1회성 무료 부스트 카드")
