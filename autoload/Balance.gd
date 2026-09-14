extends Node
## 감염 클리어런스 / S1 경찰서 지구 — 수치 단일 출처.
## QA 체크리스트의 모든 판정은 이 파일의 상수를 따른다.

const PUBLIC_TITLE := "봉쇄구역: 제로"
const MISSION_NAME := "감염 클리어런스"
const ZONE_NAME := "경찰서 지구"
const STAGE_ID := "S1"

## O1: 첫 처치·피드백 목표 창(초).
const O1_FIRST_KILL_MIN_SEC := 1.0
const O1_FIRST_KILL_MAX_SEC := 5.0

## 전투 틱. 자동 사격·이동·근접 피해가 이 주기로 처리된다.
const TICK_INTERVAL := 0.45
const TAP_COOLDOWN := 0.14
const RELOAD_SEC := 1.55

## 플레이어 기본값 (보급 레벨 0, 업글 없음).
const PLAYER_MAX_HP := 100.0
const BASE_DAMAGE := 14.0
const BASE_AMMO := 20.0
const AMMO_PER_SHOT := 1.0

## 업글1 — 화력 vs 탄약효율, 상호 배타, 스크랩 비용.
## 탄약효율 UI/문서는 아래 세 상수를 그대로 쓴다. 하드코딩 금지.
const UPGRADE1_SCRAP_COST := 12
const UPGRADE1_FIREPOWER_MULT := 1.75
const UPGRADE1_AMMO_COST_MULT := 0.45
const UPGRADE1_AMMO_MAG_BONUS := 8.0

## 「이번만」 1회성 무료 보급 (첫 실패 카드). 골드/상점 보상 아님.
const IBEONMAN_DAMAGE_MULT := 1.4
const IBEONMAN_HP_BONUS := 20.0
const IBEONMAN_AMMO_BONUS := 10.0

## 보급 레벨 1 — S1 정식 클리어 해금. 상점/가챠/오프라인 없음.
const SUPPLY_LEVEL_ON_CLEAR := 1
const SUPPLY1_MAX_HP_BONUS := 15.0
const SUPPLY1_AMMO_BONUS := 4.0

## B1 실드: 받는 피해 50%. 표시확률 = 실제(확정 50%).
const B1_SHIELD_DAMAGE_TAKEN := 0.5
const B1_SHIELD_DISPLAY := "실드 피해 50%"

## 적 원형.
const ENEMY := {
	"grunt": {"hp": 12.0, "dmg": 4.0, "speed": 70.0, "melee": 42.0, "scrap": 4, "radius": 16.0},
	"runner": {"hp": 16.0, "dmg": 6.0, "speed": 150.0, "melee": 36.0, "scrap": 6, "radius": 14.0},
	"brute": {"hp": 42.0, "dmg": 11.0, "speed": 62.0, "melee": 48.0, "scrap": 10, "radius": 22.0},
	"add": {"hp": 18.0, "dmg": 7.0, "speed": 100.0, "melee": 40.0, "scrap": 5, "radius": 15.0},
	"boss": {"hp": 180.0, "dmg": 13.0, "speed": 54.0, "melee": 52.0, "scrap": 24, "radius": 28.0, "shielded": true},
}

## 아레나 (px). 플레이어는 좌측 고정.
const ARENA_PLAYER_X := 170.0
const ARENA_SPAWN_X := 1120.0
const ARENA_FIRST_X := 640.0

## S1 구역: 로비 → 복도 → 무기고 → 주차장 → 비상구 B1. 한 걸음에 보스 불가.
const ZONES: Array = [
	{
		"id": "lobby",
		"name": "로비",
		"goal": "로비 감염원 제거",
		"waves": [
			[
				{"kind": "grunt", "x": ARENA_FIRST_X},
			],
			[
				{"kind": "grunt", "x": ARENA_SPAWN_X - 40.0},
				{"kind": "grunt", "x": ARENA_SPAWN_X + 120.0},
			],
		],
	},
	{
		"id": "hall",
		"name": "복도",
		"goal": "복도 돌파",
		"waves": [
			[
				{"kind": "grunt", "x": ARENA_SPAWN_X},
				{"kind": "grunt", "x": ARENA_SPAWN_X + 40.0},
				{"kind": "grunt", "x": ARENA_SPAWN_X + 90.0},
				{"kind": "runner", "x": ARENA_SPAWN_X + 140.0},
			],
			[
				{"kind": "runner", "x": ARENA_SPAWN_X},
				{"kind": "grunt", "x": ARENA_SPAWN_X + 70.0},
				{"kind": "grunt", "x": ARENA_SPAWN_X + 120.0},
			],
		],
	},
	{
		"id": "armory",
		"name": "무기고",
		"goal": "화력 또는 탄약효율 선택",
		"choice": true,
		"waves": [
			[
				{"kind": "grunt", "x": ARENA_SPAWN_X},
				{"kind": "runner", "x": ARENA_SPAWN_X + 90.0},
			],
		],
	},
	{
		"id": "parking",
		"name": "주차장",
		"goal": "주차장 돌파",
		"waves": [
			[
				{"kind": "runner", "x": ARENA_SPAWN_X},
				{"kind": "grunt", "x": ARENA_SPAWN_X + 50.0},
				{"kind": "grunt", "x": ARENA_SPAWN_X + 110.0},
				{"kind": "runner", "x": ARENA_SPAWN_X + 170.0},
			],
			[
				{"kind": "brute", "x": ARENA_SPAWN_X},
				{"kind": "grunt", "x": ARENA_SPAWN_X + 80.0},
				{"kind": "add", "x": ARENA_SPAWN_X + 150.0},
			],
		],
	},
	{
		"id": "b1",
		"name": "비상구 B1",
		"goal": "비상구 B1 확보",
		"waves": [
			[
				{"kind": "add", "x": ARENA_SPAWN_X},
				{"kind": "add", "x": ARENA_SPAWN_X + 70.0},
				{"kind": "boss", "x": ARENA_SPAWN_X + 160.0},
			],
		],
	},
]

const FINAL_GOAL := "비상구 B1 확보"
const ZONE_COUNT := 5

static func enemy_template(kind: String) -> Dictionary:
	var src: Dictionary = ENEMY[kind]
	return src.duplicate(true)


static func zone_at(index: int) -> Dictionary:
	return ZONES[index]


static func shot_damage(upgrade_kind: int, ibeonman: bool) -> float:
	var dmg := BASE_DAMAGE
	if upgrade_kind == 1:
		dmg *= UPGRADE1_FIREPOWER_MULT
	if ibeonman:
		dmg *= IBEONMAN_DAMAGE_MULT
	return dmg


static func ammo_cost(upgrade_kind: int) -> float:
	if upgrade_kind == 2:
		return AMMO_PER_SHOT * UPGRADE1_AMMO_COST_MULT
	return AMMO_PER_SHOT


static func magazine_size(upgrade_kind: int, supply_level: int, ibeonman: bool) -> float:
	var mag := BASE_AMMO
	if upgrade_kind == 2:
		mag += UPGRADE1_AMMO_MAG_BONUS
	if supply_level >= SUPPLY_LEVEL_ON_CLEAR:
		mag += SUPPLY1_AMMO_BONUS
	if ibeonman:
		mag += IBEONMAN_AMMO_BONUS
	return mag


static func max_hp(supply_level: int, ibeonman: bool) -> float:
	var hp := PLAYER_MAX_HP
	if supply_level >= SUPPLY_LEVEL_ON_CLEAR:
		hp += SUPPLY1_MAX_HP_BONUS
	if ibeonman:
		hp += IBEONMAN_HP_BONUS
	return hp


static func apply_incoming_to_enemy(raw_damage: float, shielded: bool) -> float:
	if shielded:
		return raw_damage * B1_SHIELD_DAMAGE_TAKEN
	return raw_damage


## HUD/오버레이 카피. 수치는 위 상수와 동기. 골드·상점 표현 금지.
static func firepower_choice_copy() -> String:
	return "화력  —  공격력 ×%.2f" % UPGRADE1_FIREPOWER_MULT


static func ammo_eff_choice_copy() -> String:
	return "탄약효율  —  탄소모 ×%.2f · 탄창 +%.0f" % [UPGRADE1_AMMO_COST_MULT, UPGRADE1_AMMO_MAG_BONUS]


static func ibeonman_supply_copy() -> String:
	return "긴급 보급  ·  화력 ×%.2f · 체력 +%.0f · 탄약 +%.0f" % [
		IBEONMAN_DAMAGE_MULT, IBEONMAN_HP_BONUS, IBEONMAN_AMMO_BONUS
	]


static func armory_auto_hint() -> String:
	return "하나만 선택한다. 자동 사격은 목표 카드 확인 뒤에 해금된다."
