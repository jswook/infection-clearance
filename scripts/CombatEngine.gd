class_name CombatEngine
extends RefCounted
## S1 전투 틱·웨이브·업글1·실패/클리어. UI와 분리된 순수 시뮬레이션.

const Bal = preload("res://autoload/Balance.gd")

signal toast(text: String)
signal first_kill(elapsed_sec: float)
signal player_died
signal run_cleared
signal upgrade_resolved(kind: int)
signal needs_armory_choice
signal needs_goal_card
signal auto_unlocked_changed
signal zone_changed(index: int)
signal wave_changed(index: int, count: int)

const UPGRADE_NONE := 0
const UPGRADE_FIREPOWER := 1
const UPGRADE_AMMO_EFF := 2

var phase: String = "idle"
var zone_index: int = 0
var wave_index: int = 0
var scrap: int = 0
var upgrade_kind: int = UPGRADE_NONE
var upgrade_bought: bool = false
var auto_unlocked: bool = false
var auto_on: bool = false
var ibeonman: bool = false
var supply_level: int = 0
var elapsed: float = 0.0
var first_kill_sec: float = -1.0
var tick_accum: float = 0.0
var tap_cd: float = 0.0
var reload_left: float = 0.0
var next_id: int = 1
var ticks: int = 0
var shots: int = 0
var enemies: Array[Dictionary] = []
var player: Dictionary = {}
var pending_choice: bool = false
var pending_goal_card: bool = false
var goal_card_acked: bool = false
var just_failed: bool = false
var just_cleared: bool = false
var grace: float = 0.0
var toast_log: PackedStringArray = PackedStringArray()


func start_run(p_supply: int, p_ibeonman: bool) -> void:
	supply_level = p_supply
	ibeonman = p_ibeonman
	phase = "combat"
	zone_index = 0
	wave_index = 0
	scrap = 0
	upgrade_kind = UPGRADE_NONE
	upgrade_bought = false
	auto_unlocked = false
	auto_on = false
	elapsed = 0.0
	first_kill_sec = -1.0
	tick_accum = 0.0
	tap_cd = 0.0
	reload_left = 0.0
	next_id = 1
	ticks = 0
	shots = 0
	enemies.clear()
	pending_choice = false
	pending_goal_card = false
	goal_card_acked = false
	just_failed = false
	just_cleared = false
	grace = 2.0
	toast_log = PackedStringArray()
	_reset_player()
	_spawn_current_wave()
	zone_changed.emit(zone_index)
	wave_changed.emit(wave_index, _wave_count())
	_push_toast("%s — %s 진입" % [Bal.MISSION_NAME, zone_name()])


func process(delta: float) -> void:
	if phase != "combat":
		return
	elapsed += delta
	grace = maxf(0.0, grace - delta)
	tap_cd = maxf(0.0, tap_cd - delta)
	if reload_left > 0.0:
		reload_left = maxf(0.0, reload_left - delta)
		if reload_left == 0.0:
			player.ammo = magazine()
			_push_toast("재장전 완료")
	tick_accum += delta
	while tick_accum >= Bal.TICK_INTERVAL and phase == "combat":
		tick_accum -= Bal.TICK_INTERVAL
		_combat_tick()


func tap_fire() -> bool:
	if phase != "combat":
		return false
	if tap_cd > 0.0:
		return false
	tap_cd = Bal.TAP_COOLDOWN
	return _fire(true)


func try_upgrade_open() -> String:
	if upgrade_bought:
		return "already"
	if scrap < Bal.UPGRADE1_SCRAP_COST:
		return "poor"
	pending_choice = true
	return "ok"


func choose_upgrade(kind: int) -> bool:
	if upgrade_bought:
		return false
	if kind != UPGRADE_FIREPOWER and kind != UPGRADE_AMMO_EFF:
		return false
	if scrap < Bal.UPGRADE1_SCRAP_COST:
		return false
	scrap -= Bal.UPGRADE1_SCRAP_COST
	upgrade_kind = kind
	upgrade_bought = true
	pending_choice = false
	player.ammo = magazine()
	var label := "화력" if kind == UPGRADE_FIREPOWER else "탄약효율"
	_push_toast("업글1 장착: %s  — 화력 %.1f / 탄소모 %.2f" % [label, damage(), ammo_cost()])
	upgrade_resolved.emit(kind)
	# UX-4: 자동은 목표카드 확인 뒤에만. 업글1/무기고 선택 직후 잠금 유지.
	pending_goal_card = true
	if phase == "choice":
		phase = "goal"
	needs_goal_card.emit()
	return true


func acknowledge_goal_card() -> bool:
	if not upgrade_bought or goal_card_acked:
		return goal_card_acked
	pending_goal_card = false
	goal_card_acked = true
	auto_unlocked = true
	auto_on = true
	auto_unlocked_changed.emit()
	_push_toast("목표 확인  ·  자동 해금")
	if phase == "goal" or phase == "choice":
		_advance_after_choice()
	return true


func can_afford_upgrade() -> bool:
	return not upgrade_bought and scrap >= Bal.UPGRADE1_SCRAP_COST


func damage() -> float:
	return Bal.shot_damage(upgrade_kind, ibeonman)


func ammo_cost() -> float:
	return Bal.ammo_cost(upgrade_kind)


func magazine() -> float:
	return Bal.magazine_size(upgrade_kind, supply_level, ibeonman)


func zone() -> Dictionary:
	return Bal.zone_at(zone_index)


func zone_name() -> String:
	return String(zone().get("name", "?"))


func zone_goal() -> String:
	return String(zone().get("goal", Bal.FINAL_GOAL))


func set_auto(on: bool) -> void:
	if auto_unlocked:
		auto_on = on


func _reset_player() -> void:
	var hp := Bal.max_hp(supply_level, ibeonman)
	player = {
		"hp": hp,
		"max_hp": hp,
		"ammo": magazine(),
		"x": Bal.ARENA_PLAYER_X,
	}


func _wave_count() -> int:
	var waves: Array = zone().get("waves", [])
	return waves.size()


func _spawn_current_wave() -> void:
	enemies.clear()
	var waves: Array = zone().get("waves", [])
	if wave_index < 0 or wave_index >= waves.size():
		return
	var specs: Array = waves[wave_index]
	for spec_v in specs:
		var spec: Dictionary = spec_v
		var kind := String(spec.get("kind", "grunt"))
		var tmpl := Bal.enemy_template(kind)
		var shielded := bool(tmpl.get("shielded", false))
		enemies.append({
			"id": next_id,
			"kind": kind,
			"hp": float(tmpl.hp),
			"max_hp": float(tmpl.hp),
			"dmg": float(tmpl.dmg),
			"speed": float(tmpl.speed),
			"melee": float(tmpl.melee),
			"scrap": int(tmpl.scrap),
			"radius": float(tmpl.radius),
			"shielded": shielded,
			"x": float(spec.get("x", Bal.ARENA_SPAWN_X)),
			"alive": true,
		})
		next_id += 1
	wave_changed.emit(wave_index, waves.size())
	_push_toast("%s · 웨이브 %d/%d" % [zone_name(), wave_index + 1, waves.size()])


func _combat_tick() -> void:
	ticks += 1
	if auto_on and auto_unlocked:
		_fire(false)
	var front := _closest_living()
	for e in enemies:
		if not e.alive:
			continue
		var dist: float = e.x - player.x
		if dist > e.melee:
			e.x = maxf(player.x + e.melee * 0.35, e.x - e.speed * Bal.TICK_INTERVAL)
		elif grace <= 0.0 and not front.is_empty() and int(e.id) == int(front.id):
			player.hp -= e.dmg
			_push_toast("피격 -%.0f" % e.dmg)
			if player.hp <= 0.0:
				player.hp = 0.0
				_fail()
				return
	if _living_count() == 0:
		_on_wave_cleared()


func _fire(is_tap: bool) -> bool:
	if reload_left > 0.0:
		return false
	var cost := ammo_cost()
	if player.ammo < cost:
		reload_left = Bal.RELOAD_SEC
		if is_tap:
			_push_toast("탄약 소진 — 재장전")
		return false
	var target := _closest_living()
	if target.is_empty():
		return false
	player.ammo -= cost
	shots += 1
	var raw := damage()
	var dealt := Bal.apply_incoming_to_enemy(raw, bool(target.shielded))
	target.hp -= dealt
	if target.hp <= 0.0:
		_kill(target)
	return true


func _kill(target: Dictionary) -> void:
	target.alive = false
	target.hp = 0.0
	scrap += int(target.scrap)
	if first_kill_sec < 0.0:
		first_kill_sec = elapsed
		first_kill.emit(elapsed)
		_push_toast("처치 +스크랩 %d" % int(target.scrap))
	else:
		_push_toast("처치 +%d" % int(target.scrap))


func _living_count() -> int:
	var n := 0
	for e in enemies:
		if e.alive:
			n += 1
	return n


func _closest_living() -> Dictionary:
	var best: Dictionary = {}
	var best_x := 1.0e9
	for e in enemies:
		if e.alive and e.x < best_x:
			best = e
			best_x = e.x
	return best


func _on_wave_cleared() -> void:
	if wave_index + 1 < _wave_count():
		wave_index += 1
		_spawn_current_wave()
		return
	if bool(zone().get("choice", false)) and not upgrade_bought:
		phase = "choice"
		pending_choice = true
		needs_armory_choice.emit()
		_push_toast("무기고: 화력 또는 탄약효율을 하나 선택")
		return
	_advance_zone()


func _advance_after_choice() -> void:
	phase = "combat"
	_advance_zone()


func _advance_zone() -> void:
	if zone_index + 1 >= Bal.ZONE_COUNT:
		_clear()
		return
	zone_index += 1
	wave_index = 0
	_spawn_current_wave()
	zone_changed.emit(zone_index)
	_push_toast("구역 이동: %s — 목표 %s" % [zone_name(), zone_goal()])


func _fail() -> void:
	phase = "fail"
	just_failed = true
	player_died.emit()


func _clear() -> void:
	phase = "clear"
	just_cleared = true
	run_cleared.emit()


func _push_toast(text: String) -> void:
	toast_log.append(text)
	if toast_log.size() > 6:
		toast_log.remove_at(0)
	toast.emit(text)


func living_enemies() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for e in enemies:
		if e.alive:
			out.append(e)
	return out
