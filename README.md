# 봉쇄구역: 제로

Godot **4.7** (GDScript) 수직 슬라이스. 대외 타이틀은 **봉쇄구역: 제로**, 미션/보급 UI 카피는 **감염 클리어런스**, 구역은 **S1 경찰서 지구**.

## 엔트리 씬

| | |
|---|---|
| 메인 씬 | `res://scenes/App.tscn` (`project.godot` → `application/run/main_scene`) |
| 스크립트 | `res://scripts/App.gd` |
| 수치 | `res://autoload/Balance.gd` (QA 판정 단일 출처) |
| 메타 세이브 | `res://autoload/MetaSave.gd` → `user://infection_clearance_meta.json` |

Godot 4.x에서 이 저장소를 열고 **F5**. 엔트리 씬이 타이틀(작전 개시)로 시작한다.

## 코어 루프

1. **탭 처치** — 아레나 클릭 또는 Space. 전투는 `Balance.TICK_INTERVAL` 틱.
2. **스크랩** — 처치 시 획득. 적색 틴트는 **스크랩 < 업글 비용**일 때만 (업글 클릭 부족 연출). 구매 가능하면 흰색.
3. **업글1** — 화력 **또는** 탄약효율. 업글 버튼만 점멸. 강제 클릭 없음.
4. **S1 웨이브** — 로비 → 복도 → 무기고 → 주차장 → 비상구 B1. 한 걸음에 보스 불가.
5. **「이번만」** — 첫 실패 시 1회성 **긴급 보급** 카드 (스크랩/보급. 골드 아님). 소모 후 재도전.
6. **보급 레벨** — S1 정식 클리어 시 레벨 1 해금·저장.

탄약효율 수치는 `Balance.gd`와 같다. UI는 `Balance.ammo_eff_choice_copy()`를 쓴다.

| | |
|---|---|
| 탄소모 | `AMMO_PER_SHOT * UPGRADE1_AMMO_COST_MULT` (×0.45) |
| 탄창 | `BASE_AMMO + UPGRADE1_AMMO_MAG_BONUS` (+8) |

자동 사격은 무기고 **선택 직후가 아니라** 목표 카드 **확인** 뒤에 해금된다.

## HUD (S1 diet)

보이는 것: 목표, 구역, 체력, 탄약, 스크랩, 업글1, 자동(목표 카드 확인 후).

S1에 **두지 않는다:** 상점, 가챠, 에너지 페이월, 조이스틱, 액티브 스킬 슬롯, 허브.

조작: Enter 시작, Space 사격, U 업글, A 자동(목표 확인 이후), 철수/재도전.

## P0 아트 / #12 드롭인

`art/.gdignore` 없음. Godot이 PNG를 `Texture2D`로 임포트한다. HUD/아레나는 `P0Art` → `TextureRect`·`Sprite2D`. 전투 로직·UX-4 순서(업글1 → 선택 → 목표 카드 → 자동)는 그대로다.

#12 실에셋은 **같은 경로**에 덮어쓴다. 1280×720 시트는 아틀라스 크롭, 타이트 PNG는 전체 텍스처.

| 경로 | 연결 |
| --- | --- |
| `art/ui/ui_upgrade.png` | 업글 버튼 옆 `TextureRect` 점멸 (이 훅만) |
| `art/ui/ui_boost_once.png` | 첫 실패 「이번만」 보급 오버레이. 카피=스크랩/보급 (골드 금지) |
| `art/ui/ui_goal_exit.png` | 업글1 이후 목표(비상구) 카드 |
| `art/enemies/enemies_z1_b1.png` | Z1–Z6 · B1 `Sprite2D` |
| `art/fx/fx_kill_scrap.png` | 처치 버스트 + 스크랩 획득 FX |
| `art/characters/player.png` | 아레나 `PlayerSprite` |

목록·드롭인 규칙: `art/README.md`. 아틀라스 좌표는 `scripts/P0Art.gd`.

## Android export (stub)

`export_presets.cfg`에 Android 프리셋만 넣었다. **사이닝 키스토어는 비움** (나중에).

APK를 뽑으려면 Godot 4.7.x **Android export templates**, Android SDK, JDK가 필요하다. 템플릿이 없으면 에디터 Export가 APK를 만들지 못한다. 아트 배선은 Android 빌드와 무관하다.

```bash
# 템플릿·SDK 설치 후
godot --path . --headless --export-release Android export/android/infection-clearance.apk
```

## 헤드리스 검증

```bash
godot --path . --headless res://tests/Verify.tscn
```

요구 버전: Godot 4.7.x (4.x 계열에서 열리도록 `config/features` 는 4.7).
