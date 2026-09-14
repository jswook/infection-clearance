# 아트 (SERVICE / #12 프로덕션)

[#12](https://github.com/jswook/infection-clearance/issues/12) P0 훅 경로를 **서비스 레벨 프로덕션** PNG로 교체한다. 파이프라인: [#24](https://github.com/jswook/infection-clearance/issues/24) 단계 3 (임포트·연출). PNG는 PR #27 경로 그대로다.

HUD 다이어트(첫 10분 HUD에 편성·기지 허브, 결제+, 스킬 바, 골드 카피 금지. 「이번만」 카피는 스크랩/보급만)는 [`docs/ux/production-s1.md`](../docs/ux/production-s1.md)를 따른다.

`art/.gdignore`는 두지 않는다. Godot이 PNG를 `Texture2D`로 임포트하고, `scripts/P0Art.gd`가 유일한 로드 훅이다 (`scenes/App.tscn`의 ext_resource는 임포트 앵커). 새 슬롯·새 HUD를 만들지 않는다.

## 프로덕션 시트 (P0 훅)

모두 1280×720 RGBA. 타이트(비-1280) PNG를 넣으면 `P0Art.sheet_texture()`가 아틀라스 크롭 없이 전체 텍스처를 쓴다.

| 파일 | 용도 | 연결 |
| --- | --- | --- |
| `ui/ui_upgrade.png` | 업글 CTA (점멸은 이 훅만) | 업글 버튼 옆 TextureRect |
| `ui/ui_boost_once.png` | 「이번만」 (스크랩/보급, 골드 금지) | 첫 실패 오버레이 |
| `ui/ui_goal_exit.png` | 목표: 비상구 | 업글1 선택 후 목표 카드 |
| `enemies/enemies_z1_b1.png` | Z1–Z6 · B1 | 아레나 Sprite2D |
| `fx/fx_kill_scrap.png` | 처치/스크랩 | 처치 버스트·탄피 FX |
| `characters/player.png` | 플레이어 | 아레나 `PlayerSprite` |

## 아틀라스 영역

`scripts/P0Art.gd` 실측값 (`Rect2(x, y, w, h)`). 시트가 1280×720일 때만 적용.

| 프레임 | 영역 |
| --- | --- |
| Z1 | `Rect2(35, 54, 162, 230)` |
| Z2 | `Rect2(235, 64, 158, 221)` |
| Z3 | `Rect2(428, 32, 158, 253)` |
| Z4 | `Rect2(614, 73, 187, 211)` |
| Z5 | `Rect2(814, 104, 246, 183)` |
| Z6 | `Rect2(1084, 54, 158, 232)` |
| B1 | `Rect2(419, 315, 421, 338)` |
| 처치 버스트 | `Rect2(88, 57, 526, 575)` |
| 스크랩(탄피) | `Rect2(767, 140, 401, 410)` |
| 업글 CTA | `Rect2(174, 170, 931, 356)` |
| 부스트 카드 | `Rect2(107, 41, 1060, 622)` |
| 목표 카드 | `Rect2(57, 182, 1167, 341)` |
| 플레이어 | `Rect2(450, 11, 302, 679)` |

알파가 들어 있으므로 `P0Art.chroma_material()` 크로마 키는 이 스프라이트에 쓰지 않는다.

## 남아 있는 플레이스홀더

`ui/ui_upgrade_blink.png`는 예전 P0 점멸 시트다. 점멸 훅은 `ui_upgrade.png`로 옮겼다.
