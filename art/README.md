# 아트 (P0 플레이스홀더 → #12 드롭인)

[#11](https://github.com/jswook/infection-clearance/issues/11) P0 플레이스홀더. [#12](https://github.com/jswook/infection-clearance/issues/12) 실에셋은 **같은 파일명**으로 아래 폴더에 덮어쓴다. 게임 로직·경로 상수는 바꾸지 않는다.

`art/.gdignore`는 두지 않는다. Godot이 PNG를 `Texture2D`로 임포트하고, `scripts/P0Art.gd`가 유일한 로드 훅이다 (`scenes/App.tscn`의 ext_resource는 임포트 앵커).

## 드롭인 경로

| 폴더 | 파일 | 용도 | 연결 |
| --- | --- | --- | --- |
| `ui/` | `ui_upgrade_blink.png` | UI 업글 버튼 점멸 | 업글 버튼 옆 TextureRect. 구매 가능할 때만 점멸 |
| `ui/` | `ui_boost_once.png` | 「이번만」 긴급 **보급** 카드 | 첫 실패 오버레이. 카피=스크랩/보급. **골드 금지** |
| `ui/` | `ui_goal_exit.png` | 스테이지 목표 카드 (비상구) | 업글1 선택 후, 확인 시 자동 해금 |
| `enemies/` | `enemies_z1_b1.png` | Z1–Z6 · B1 실루엣 | 아레나 Sprite2D (grunt Z1–Z3, add Z4, runner Z5, brute Z6, boss B1) |
| `fx/` | `fx_kill_scrap.png` | 처치 + 스크랩 피드백 | 처치 시 버스트·탄피 FX |

## #12 규칙

- 경로: `P0Art.ALL_PATHS` (`res://art/ui`, `res://art/enemies`, `res://art/fx`).
- UI 카드: P0는 1280×720 시트라 아틀라스 크롭. **타이트 PNG**(다른 해상도)를 넣으면 `P0Art.ui_texture()`가 전체 텍스처를 쓴다.
- 「이번만」 실에셋 카피는 `Balance.ibeonman_supply_copy()`와 맞춘다 (화력·체력·탄약 보급). 골드획득/상점 카피 없음.
- 적·FX 시트는 `P0Art` 아틀라스 좌표를 유지하거나, 시트 레이아웃이 바뀌면 좌표만 갱신한다.
- 상점/가챠/에너지/조이스틱/스킬 슬롯 아트는 S1에 넣지 않는다.

아틀라스 영역: `res://scripts/P0Art.gd`.
