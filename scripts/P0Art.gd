class_name P0Art
extends RefCounted
## P0 훅 경로·아틀라스. 전투 수치와 무관하다.
## #12 실에셋 드롭인: 같은 파일명으로 art/ui, art/enemies, art/fx, art/characters 에 덮어쓴다.
## 1280×720 시트만 아틀라스 크롭. 타이트(비-1280) PNG는 전체 Texture2D를 쓴다.

const P0_SHEET := Vector2i(1280, 720)
const DIR_UI := "res://art/ui"
const DIR_ENEMIES := "res://art/enemies"
const DIR_FX := "res://art/fx"
const DIR_CHARACTERS := "res://art/characters"

const UPGRADE_BLINK := "res://art/ui/ui_upgrade.png"
const BOOST_ONCE := "res://art/ui/ui_boost_once.png"
const GOAL_EXIT := "res://art/ui/ui_goal_exit.png"
const ENEMIES_SHEET := "res://art/enemies/enemies_z1_b1.png"
const FX_KILL_SCRAP := "res://art/fx/fx_kill_scrap.png"
const PLAYER := "res://art/characters/player.png"

## #27 프로덕션 시트 실측. 타이트 PNG면 sheet_texture()가 이 값을 무시한다.
const UPGRADE_REGION := Rect2(174, 170, 931, 356)
const BOOST_REGION := Rect2(107, 41, 1060, 622)
## 프로덕션 「이번만」 카드에 골드 줄이 없다. 크롭이 시트 밖으로 안 나가게만 본다.
const BOOST_GOLD_STATS_Y := 720.0
const GOAL_REGION := Rect2(57, 182, 1167, 341)
const PLAYER_REGION := Rect2(450, 11, 302, 679)

const FX_KILL_REGION := Rect2(88, 57, 526, 575)
const FX_SCRAP_REGION := Rect2(767, 140, 401, 410)

## Z1–Z6 · B1 (enemies_z1_b1.png, 상단 6 + 하단 보스).
const Z1 := Rect2(35, 54, 162, 230)
const Z2 := Rect2(235, 64, 158, 221)
const Z3 := Rect2(428, 32, 158, 253)
const Z4 := Rect2(614, 73, 187, 211)
const Z5 := Rect2(814, 104, 246, 183)
const Z6 := Rect2(1084, 54, 158, 232)
const B1 := Rect2(419, 315, 421, 338)

const ALL_PATHS: PackedStringArray = [
	UPGRADE_BLINK,
	BOOST_ONCE,
	GOAL_EXIT,
	ENEMIES_SHEET,
	FX_KILL_SCRAP,
	PLAYER,
]


static func tex(path: String) -> Texture2D:
	if ResourceLoader.exists(path):
		return load(path) as Texture2D
	return null


static func atlas(path: String, region: Rect2) -> AtlasTexture:
	var src := tex(path)
	if src == null:
		return null
	var at := AtlasTexture.new()
	at.atlas = src
	at.region = region
	at.filter_clip = true
	return at


static func is_p0_sheet(src: Texture2D) -> bool:
	return src != null and src.get_width() == P0_SHEET.x and src.get_height() == P0_SHEET.y


## 드롭인. P0 1280×720 시트만 아틀라스 크롭. #12 타이트 PNG는 전체 텍스처.
static func sheet_texture(path: String, region: Rect2) -> Texture2D:
	var src := tex(path)
	if src == null:
		return null
	if not is_p0_sheet(src):
		return src
	return atlas(path, region)


static func ui_texture(path: String, region: Rect2) -> Texture2D:
	return sheet_texture(path, region)


static func upgrade_blink() -> Texture2D:
	return sheet_texture(UPGRADE_BLINK, UPGRADE_REGION)


static func boost_card() -> Texture2D:
	return sheet_texture(BOOST_ONCE, BOOST_REGION)


static func goal_card() -> Texture2D:
	return sheet_texture(GOAL_EXIT, GOAL_REGION)


static func player() -> Texture2D:
	return sheet_texture(PLAYER, PLAYER_REGION)


static func fx_kill() -> Texture2D:
	return sheet_texture(FX_KILL_SCRAP, FX_KILL_REGION)


static func fx_scrap() -> Texture2D:
	return sheet_texture(FX_KILL_SCRAP, FX_SCRAP_REGION)


static func enemy_region(kind: String, enemy_id: int) -> Rect2:
	match kind:
		"runner":
			return Z5
		"brute":
			return Z6
		"add":
			return Z4
		"boss":
			return B1
		_:
			var grunt_frames: Array[Rect2] = [Z1, Z2, Z3]
			return grunt_frames[abs(enemy_id) % grunt_frames.size()]


static func chroma_material() -> ShaderMaterial:
	var sh := Shader.new()
	sh.code = """
shader_type canvas_item;
render_mode unshaded;
uniform float luma_cut : hint_range(0.0, 1.0) = 0.13;
uniform float sat_cut : hint_range(0.0, 1.0) = 0.07;
void fragment() {
	vec4 c = texture(TEXTURE, UV);
	float mx = max(c.r, max(c.g, c.b));
	float mn = min(c.r, min(c.g, c.b));
	if (mx < luma_cut && (mx - mn) < sat_cut) {
		discard;
	}
	COLOR = c;
}
"""
	var mat := ShaderMaterial.new()
	mat.shader = sh
	return mat


static func fx_material() -> ShaderMaterial:
	var mat := chroma_material()
	mat.set_shader_parameter("luma_cut", 0.06)
	mat.set_shader_parameter("sat_cut", 0.05)
	return mat
