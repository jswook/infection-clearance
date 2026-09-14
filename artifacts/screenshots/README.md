# S1 런타임 스크린샷 (실제 인게임 프레임)

목업·컨셉 아트가 아니다. 다섯 장 모두 `res://scenes/App.tscn` (= `project.godot` 의
`application/run/main_scene`, F5 로 뜨는 그 씬)을 실제로 구동해서 얻은 루트 뷰포트
프레임을 그대로 저장한 것이다. 게임 코드는 한 줄도 바꾸지 않았다.

- 엔진: Godot 4.7.2.stable (`config/features` = 4.7)
- 렌더러: `gl_compatibility` / OpenGL 4.5 Mesa llvmpipe (GPU 없음, Xvfb `:1`)
- 해상도: 1280x720 (`display/window/size/viewport_*` 과 동일)
- P0 아트: #18 배선 후, #27 프로덕션 시트는 `cursor/wire-production-art-bf02` 에서 같은 하네스로 다시 찍는다.

## 재현

```bash
DISPLAY=:1 godot --path . --resolution 1280x720 --fixed-fps 60 \
  res://tools/CaptureShots.tscn -- --out=$PWD/artifacts/screenshots
```

`--fixed-fps 60` 으로 프레임 델타를 고정하므로 결과는 결정적이다.
하네스는 `tools/CaptureShots.gd`.

## 5장

| 파일 | 상태 | 프레임에서 확인되는 것 |
| --- | --- | --- |
| `shot1_lobby.png` | S1 1-1 로비 · 탭 처치 | `S1 / 로비 · 1/5`, 머즐 플래시 + 처치/스크랩 FX(`fx_kill_scrap.png`), 남은 그런트 실루엣(`enemies_z1_b1.png`), `스크랩 8`, 자동 버튼 **자동 잠김** |
| `shot2_upgrade_blink.png` | 업글 유도 (기획 3 / UX 1) | `스크랩` 라벨 **부족 틴트(적색)** + `업그레이드 · 12 스크랩` 버튼과 `ui_upgrade.png` CTA가 **점멸 골(노랑)** 로 발광. 다른 HUD는 점멸 없음 |
| `shot3_armory_choice.png` | 무기고 배타 선택 (기획 4) | `S1 / 무기고 · 3/5`, `업글1 · 무기고` 오버레이, `화력 — 공격력 ×1.75` vs `탄약효율 — 탄소모 ×0.45 · 탄창 +8` |
| `shot4_parking_goal.png` | S1 1-4 주차장 · 목표 카드 + 자동 ON (UX 4) | `S1 / 주차장 · 4/5`, `ui_goal_exit.png` **비상구** 목표 카드, `목표: 비상구 B1 확보`, 자동 버튼 **자동 ON**, `업글1 완료 · 화력` / `화력 24.5` |
| `shot5_ibeonman.png` | S1 1-5 비상구 B1 첫 실패 → 「이번만」 (기획 5 / UX 2) | `S1 / 비상구 B1 · 5/5`, `체력 0 / 100`, B1 보스 실루엣 + 실드 아크, `ui_boost_once.png` **「이번만」** 카드, `작전 실패` / `「이번만」` · `재도전` 버튼, 토스트 `피격 -13` |

## 각 프레임 도달 방법

전부 게임 자신의 입력 경로(`_start_mission` / `_do_tap` / `_on_upgrade_pressed` / `_pick`)로만 몰았다.

1. **shot1** — 작전 개시 후 로비 웨이브 1·2를 실제 탭으로 처치. 자동은 아직 해금 전이라
   버튼이 `자동 잠김` 이다(UX-4: 목표 카드 확인 전에는 자동 ON 이 불가능하다).
2. **shot2** — 스크랩 8(=12 미달)에서 `업그레이드` 를 눌러 실제 `"poor"` 경로로 부족 틴트를
   띄우고, 같은 프레임에 세 번째 처치로 스크랩을 12로 채운다. 틴트(1초 감쇠)가 남아 있는
   동안 점멸이 켜지므로, 결핍 → CTA 전환이 한 프레임에 같이 잡힌다.
3. **shot3** — 로비 → 복도 → 무기고를 탭 사격으로 돌파. 무기고 웨이브 클리어 시
   엔진이 `needs_armory_choice` 를 emit 하고 게임이 오버레이를 띄운다.
4. **shot4** — `화력` 선택 → 게임이 목표 카드를 띄운다. 이어서 `acknowledge_goal_card()`
   (= 확인 버튼이 호출하는 그 엔진 API)로 자동을 해금하고 주차장으로 넘긴다. 오버레이를
   닫는 쪽은 버튼 핸들러이므로, 목표 카드가 떠 있는 채로 HUD만 `주차장 4/5 · 자동 ON` 으로
   갱신된 프레임을 얻을 수 있다.
5. **shot5** — 주차장 2웨이브 돌파 후 비상구 B1 진입. B1 애드 2기만 실제 탭으로 정리하고
   자동을 끄고 사격을 멈춘다. 보스가 근접까지 걸어와 `피격 -13` 을 누적해 플레이어를 죽인다.
   **체력 조작 없음** — 실패 판정은 실제 전투 틱이 낸다. 첫 실패이므로 「이번만」 카드가 뜬다.
