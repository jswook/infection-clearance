# 아트 (P0 게임레디 2D)

[#11](https://github.com/jswook/infection-clearance/issues/11)용 P0 게임레디 2D 스프라이트. **게임 로직은 바꾸지 않는다.**

`art/.gdignore`는 두지 않는다. Godot이 아래 PNG를 `Texture2D`로 임포트하고, `scenes/App.tscn`(`scripts/App.gd`, `scripts/ArenaView.gd`)이 `TextureRect`/`Sprite2D`로 연결한다.

## P0 게임레디 2D

모두 1280×720 RGBA PNG. 배경은 실제 알파(투명)다.

| 파일 | 용도 |
| --- | --- |
| `ui/ui_upgrade.png` | UI 업글 버튼 배지 |
| `ui/ui_boost_once.png` | 「이번만」 무료 부스트 카드 |
| `ui/ui_goal_exit.png` | 스테이지 목표 카드 (비상구) |
| `enemies/enemies_z1_b1.png` | Z1–Z6 · B1 시트 (grunt Z1–Z3, add Z4, runner Z5, brute Z6, boss B1) |
| `fx/fx_kill_scrap.png` | 처치 버스트 + 스크랩(탄피) FX |
| `characters/player.png` | 플레이어 |

## 아틀라스 영역

`res://scripts/P0Art.gd`의 영역 상수는 이전 플레이스홀더 기준이다. 위 시트를 연결할 때 쓸 실측값(`Rect2(x, y, w, h)`):

| 프레임 | 영역 |
| --- | --- |
| Z1 | `Rect2(21, 276, 130, 220)` |
| Z2 | `Rect2(168, 282, 132, 214)` |
| Z3 | `Rect2(326, 317, 166, 179)` |
| Z4 | `Rect2(503, 276, 143, 221)` |
| Z5 | `Rect2(668, 271, 150, 227)` |
| Z6 | `Rect2(840, 265, 141, 232)` |
| B1 | `Rect2(995, 181, 274, 320)` |
| 처치 버스트 | `Rect2(90, 124, 461, 434)` |
| 스크랩(탄피) | `Rect2(804, 163, 279, 343)` |
| 업글 배지 | `Rect2(386, 113, 498, 480)` |
| 부스트 카드 | `Rect2(184, 41, 912, 623)` |
| 목표 카드 | `Rect2(85, 210, 1115, 288)` |
| 플레이어 | `Rect2(447, 101, 403, 470)` |

알파가 들어 있으므로 `P0Art.chroma_material()`의 크로마 키는 이 스프라이트에 필요하지 않다.

## 남아 있는 플레이스홀더

`ui/ui_upgrade_blink.png`는 현재 `P0Art.UPGRADE_BLINK` 연결이 쓰고 있어 그대로 둔다.
