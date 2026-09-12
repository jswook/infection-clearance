# 아트 (P0 플레이스홀더)

[#11](https://github.com/jswook/infection-clearance/issues/11)용 최소 플레이스홀더. **게임 로직은 바꾸지 않는다.**

`art/.gdignore`는 두지 않는다. Godot이 아래 PNG를 `Texture2D`로 임포트하고, `scenes/App.tscn`(`scripts/App.gd`, `scripts/ArenaView.gd`)이 `TextureRect`/`Sprite2D`로 연결한다.

| 파일 | 용도 | 연결 |
| --- | --- | --- |
| `ui/ui_upgrade_blink.png` | UI 업글 버튼 점멸 | 업글 버튼 옆 TextureRect. 구매 가능할 때만 점멸 |
| `ui/ui_boost_once.png` | 「이번만」 무료 부스트 카드 | 첫 실패 오버레이 |
| `ui/ui_goal_exit.png` | 스테이지 목표 카드 (비상구) | 업글1 선택 직후 목표 카드 |
| `enemies/enemies_z1_b1.png` | Z1–Z6 · B1 실루엣 | 아레나 Sprite2D (grunt Z1–Z3, add Z4, runner Z5, brute Z6, boss B1) |
| `fx/fx_kill_scrap.png` | 처치 + 스크랩 피드백 | 처치 시 버스트·탄피 FX |

아틀라스 영역: `res://scripts/P0Art.gd`.
