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
	_check_p0_art()
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
	_assert(is_equal_approx(Bal.UPGRADE1_AMMO_COST_MULT, 0.45), "탄약효율 cost mult")
	_assert(is_equal_approx(Bal.UPGRADE1_AMMO_MAG_BONUS, 8.0), "탄약효율 mag bonus")
	var ammo_copy := Bal.ammo_eff_choice_copy()
	_assert(ammo_copy.contains("%.2f" % Bal.UPGRADE1_AMMO_COST_MULT) or ammo_copy.contains("0.45"), "탄약효율 copy uses Balance cost")
	_assert(ammo_copy.contains("8"), "탄약효율 copy uses mag bonus")
	_assert(ammo_copy.contains("탄약효율") and ammo_copy.contains("탄소모"), "탄약효율 copy labels")
	_assert(not ammo_copy.contains("골드") and not ammo_copy.to_lower().contains("gold"), "탄약효율 copy has no gold")
	var boost_copy := Bal.ibeonman_supply_copy()
	_assert(boost_copy.contains("보급"), "이번만 copy is 보급")
	_assert(not boost_copy.contains("골드") and not boost_copy.to_lower().contains("gold"), "이번만 copy has no gold")
	_assert(boost_copy.contains("%.2f" % Bal.IBEONMAN_DAMAGE_MULT) or boost_copy.contains("1.40") or boost_copy.contains("1.4"), "이번만 copy uses damage mult")
	_assert(Bal.armory_auto_hint().contains("목표 카드 확인"), "armory hint: auto after goal card")
	_assert(not Bal.armory_auto_hint().contains("선택 후 자동"), "armory hint does not unlock auto on choice")


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
	_assert(is_equal_approx(e2.magazine(), Bal.BASE_AMMO + Bal.UPGRADE1_AMMO_MAG_BONUS), "mag bonus equals Balance")

	var short := CombatEngineScript.new()
	short.start_run(0, false)
	short.scrap = Bal.UPGRADE1_SCRAP_COST - 1
	_assert(short.scrap_is_short(), "scrap short below upgrade cost")
	_assert(not short.can_afford_upgrade(), "cannot afford below cost")
	short.scrap = Bal.UPGRADE1_SCRAP_COST
	_assert(not short.scrap_is_short(), "scrap not short at upgrade cost")
	short.upgrade_bought = true
	short.scrap = 0
	_assert(not short.scrap_is_short(), "scrap not short after upgrade bought")


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


func _check_p0_art() -> void:
	var ignored := FileAccess.file_exists("res://art/.gdignore")
	_assert(not ignored, "art/.gdignore absent so Godot can import PNG")
	var art_dir := DirAccess.open("res://art")
	_assert(art_dir != null, "art/ visible to Godot")
	for path in P0Art.ALL_PATHS:
		_assert(ResourceLoader.exists(path), "texture import %s" % path)
	_assert(P0Art.upgrade_blink() != null, "upgrade blink atlas")
	_assert(P0Art.boost_card() != null, "이번만 card atlas")
	_assert(P0Art.BOOST_REGION.position.y + P0Art.BOOST_REGION.size.y <= P0Art.BOOST_GOLD_STATS_Y, "이번만 P0 crop hides gold stats")
	_assert(P0Art.goal_card() != null, "goal card atlas")
	_assert(P0Art.fx_kill() != null and P0Art.fx_scrap() != null, "kill/scrap FX atlas")
	_assert(P0Art.upgrade_blink() is AtlasTexture, "P0 1280 sheet uses atlas crop")
	_assert(P0Art.boost_card() is AtlasTexture, "P0 이번만 sheet uses gold-hiding crop")
	_assert(P0Art.ALL_PATHS.has(P0Art.UPGRADE_BLINK), "swap hook ui upgrade")
	_assert(P0Art.ALL_PATHS.has(P0Art.BOOST_ONCE), "swap hook ui boost")
	_assert(P0Art.ALL_PATHS.has(P0Art.GOAL_EXIT), "swap hook ui goal")
	_assert(P0Art.ALL_PATHS.has(P0Art.ENEMIES_SHEET), "swap hook enemies")
	_assert(P0Art.ALL_PATHS.has(P0Art.FX_KILL_SCRAP), "swap hook fx")
	_assert(P0Art.DIR_UI == "res://art/ui" and P0Art.DIR_ENEMIES == "res://art/enemies" and P0Art.DIR_FX == "res://art/fx", "swap dirs")
	var tight := ImageTexture.create_from_image(Image.create(64, 48, false, Image.FORMAT_RGBA8))
	_assert(not P0Art.is_p0_sheet(tight), "#12 tight PNG skips P0 atlas crop")
	_assert(P0Art.enemy_region("grunt", 1) == P0Art.Z2, "grunt cycles Z1–Z3")
	_assert(P0Art.enemy_region("runner", 0) == P0Art.Z5, "runner is Z5")
	_assert(P0Art.enemy_region("brute", 0) == P0Art.Z6, "brute is Z6")
	_assert(P0Art.enemy_region("add", 0) == P0Art.Z4, "add is Z4")
	_assert(P0Art.enemy_region("boss", 0) == P0Art.B1, "boss is B1")
