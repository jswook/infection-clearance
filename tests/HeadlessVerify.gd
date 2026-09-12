extends Node
## 코어 루프 헤드리스 검증. 수치 기준은 Balance.gd.
## 실행: godot --path . --headless res://tests/Verify.tscn

const Bal = preload("res://autoload/Balance.gd")
const CombatEngineScript = preload("res://scripts/CombatEngine.gd")

var failed := 0


func _ready() -> void:
	print("HeadlessVerify: 봉쇄구역: 제로 / 감염 클리어런스")
	_check_balance()
	_check_combat_loop()
	_check_upgrade_exclusive()
	_check_shield()
	_check_meta()
	_check_zone_order()
	_check_onboarding_auto_order()
	_check_simulated_clear()
	if failed == 0:
		print("HeadlessVerify: ALL PASSED")
		get_tree().quit(0)
	else:
		print("HeadlessVerify: FAILED %d" % failed)
		get_tree().quit(1)


func _assert(cond: bool, msg: String) -> void:
	if cond:
		print("  OK  ", msg)
	else:
		failed += 1
		print("  FAIL  ", msg)


func _check_balance() -> void:
	_assert(Bal.PUBLIC_TITLE == "봉쇄구역: 제로", "public title")
	_assert(Bal.MISSION_NAME == "감염 클리어런스", "mission name")
	_assert(Bal.ZONE_NAME == "경찰서 지구", "zone name")
	_assert(Bal.ZONE_COUNT == 5, "five S1 zones")
	_assert(is_equal_approx(Bal.B1_SHIELD_DAMAGE_TAKEN, 0.5), "B1 shield 50%")
	_assert(Bal.ZONES[0].id == "lobby", "zone0 lobby")
	_assert(Bal.ZONES[1].id == "hall", "zone1 hall")
	_assert(Bal.ZONES[2].id == "armory", "zone2 armory")
	_assert(Bal.ZONES[3].id == "parking", "zone3 parking")
	_assert(Bal.ZONES[4].id == "b1", "zone4 b1")
	_assert(bool(Bal.ZONES[2].get("choice", false)), "armory is choice gate")
	_assert(bool(Bal.ENEMY.boss.get("shielded", false)), "boss shielded")
	_assert(Bal.SUPPLY_LEVEL_ON_CLEAR == 1, "supply unlocks at 1")


func _check_combat_loop() -> void:
	var e := CombatEngineScript.new()
	e.start_run(0, false)
	_assert(e.zone_index == 0, "starts in lobby")
	_assert(e.living_enemies().size() > 0, "lobby wave spawned")
	var first: Dictionary = e.living_enemies()[0]
	_assert(first.kind == "grunt", "first target is grunt")
	_assert(e.damage() + 0.01 >= first.hp, "O1: first tap can kill")
	var ok := e.tap_fire()
	_assert(ok, "tap fires")
	_assert(e.first_kill_sec >= 0.0, "first kill recorded")
	_assert(e.first_kill_sec <= Bal.O1_FIRST_KILL_MAX_SEC, "O1 kill inside 5s")
	_assert(e.scrap == int(Bal.ENEMY.grunt.scrap), "scrap on kill")


func _check_upgrade_exclusive() -> void:
	var e := CombatEngineScript.new()
	e.start_run(0, false)
	e.scrap = Bal.UPGRADE1_SCRAP_COST
	_assert(e.try_upgrade_open() == "ok", "upgrade opens when funded")
	_assert(e.choose_upgrade(CombatEngineScript.UPGRADE_FIREPOWER), "pick firepower")
	var dmg := e.damage()
	_assert(is_equal_approx(dmg, Bal.BASE_DAMAGE * Bal.UPGRADE1_FIREPOWER_MULT), "firepower mult applied")
	_assert(not e.choose_upgrade(CombatEngineScript.UPGRADE_AMMO_EFF), "cannot pick second upgrade")
	_assert(e.upgrade_kind == CombatEngineScript.UPGRADE_FIREPOWER, "exclusive firepower")
	_assert(not e.auto_unlocked and not e.auto_on, "auto stays locked after upgrade1")

	var e2 := CombatEngineScript.new()
	e2.start_run(0, false)
	e2.scrap = Bal.UPGRADE1_SCRAP_COST
	_assert(e2.choose_upgrade(CombatEngineScript.UPGRADE_AMMO_EFF), "pick ammo eff")
	_assert(is_equal_approx(e2.ammo_cost(), Bal.AMMO_PER_SHOT * Bal.UPGRADE1_AMMO_COST_MULT), "ammo cost reduced")
	_assert(e2.magazine() > Bal.BASE_AMMO, "mag bonus on ammo path")


func _check_shield() -> void:
	var raw := 40.0
	var taken: float = Bal.apply_incoming_to_enemy(raw, true)
	_assert(is_equal_approx(taken, raw * 0.5), "shield display == actual 50%")
	_assert(is_equal_approx(Bal.apply_incoming_to_enemy(raw, false), raw), "unshielded full")


func _check_meta() -> void:
	var meta: Node = load("res://autoload/MetaSave.gd").new()
	meta.reset_for_tests()
	_assert(meta.supply_level == 0, "meta starts 0")
	_assert(meta.ibeonman_available, "이번만 available")
	var first: bool = meta.unlock_supply_on_clear()
	_assert(first, "first clear unlocks")
	_assert(meta.supply_level == 1, "supply level 1 saved")
	meta.consume_ibeonman()
	_assert(not meta.ibeonman_available, "이번만 consumed once")
	meta.load_meta()
	_assert(meta.supply_level == 1, "supply persisted")
	_assert(not meta.ibeonman_available, "이번만 persist used")
	var second: bool = meta.unlock_supply_on_clear()
	_assert(not second, "repeat clear is not first unlock")
	meta.reset_for_tests()
	meta.free()


func _check_zone_order() -> void:
	var e := CombatEngineScript.new()
	e.start_run(0, false)
	_assert(e.zone().id == "lobby", "cannot start on B1")
	var before := e.zone_index
	e._advance_zone()
	_assert(e.zone_index == before + 1, "one zone per step")
	_assert(e.zone().id != "b1", "second zone is not boss")


func _check_onboarding_auto_order() -> void:
	var e := CombatEngineScript.new()
	e.start_run(0, false)
	_assert(not e.acknowledge_goal_card(), "goal card cannot ack before upgrade1")
	_assert(not e.auto_unlocked, "auto locked at run start")
	e.scrap = Bal.UPGRADE1_SCRAP_COST
	_assert(e.choose_upgrade(CombatEngineScript.UPGRADE_FIREPOWER), "upgrade1 / armory choice")
	_assert(e.upgrade_bought, "upgrade1 applied")
	_assert(not e.auto_unlocked and not e.auto_on, "UX-4: auto locked after upgrade1/choice")
	e.set_auto(true)
	_assert(not e.auto_on, "set_auto ignored before goal card")
	_assert(e.pending_goal_card, "goal card pending after choice")
	_assert(e.acknowledge_goal_card(), "stage goal card confirmed")
	_assert(e.goal_card_acked, "goal card acked")
	_assert(e.auto_unlocked and e.auto_on, "auto unlocks only after goal card")
	_assert(not e.pending_goal_card, "goal card no longer pending")


func _simulate(e: RefCounted, seconds: float) -> void:
	var t := 0.0
	var step := 0.05
	while t < seconds and e.phase != "fail" and e.phase != "clear":
		if e.pending_choice or e.phase == "choice":
			if e.scrap >= Bal.UPGRADE1_SCRAP_COST:
				e.choose_upgrade(CombatEngineScript.UPGRADE_FIREPOWER)
			else:
				break
		if e.pending_goal_card or e.phase == "goal":
			e.acknowledge_goal_card()
		e.process(step)
		e.tap_fire()
		if e.can_afford_upgrade():
			e.choose_upgrade(CombatEngineScript.UPGRADE_FIREPOWER)
		t += step


func _check_simulated_clear() -> void:
	var e := CombatEngineScript.new()
	e.start_run(0, false)
	_simulate(e, 180.0)
	_assert(e.upgrade_bought, "sim run buys upgrade1")
	if e.phase == "fail":
		e.start_run(0, true)
		_simulate(e, 180.0)
	_assert(e.phase == "clear" or e.just_cleared, "S1 is clearable with tap+upgrade1 (이번만 if needed)")
	_assert(e.zone_index >= 2 or e.phase == "clear", "reaches armory or beyond")
