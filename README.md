# 봉쇄구역: 제로

Godot **4.7** (GDScript) 수직 슬라이스. 대외 타이틀은 **봉쇄구역: 제로**, 미션/보급 UI 카피는 **감염 클리어런스**, 구역은 **S1 경찰서 지구**.

`docs/` 는 이 브랜치에서 다루지 않는다.

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
2. **스크랩** — 처치 시 획득. 부족하면 업글 클릭 시 스크랩 라벨만 부족 연출.
3. **업글1** — 화력 **또는** 탄약효율. 업글 버튼만 점멸. 강제 클릭 없음.
4. **S1 웨이브** — 로비 → 복도 → 무기고 → 주차장 → 비상구 B1. 한 걸음에 보스 불가.
5. **「이번만」** — 첫 실패 시 1회성 카드. 소모 후 재도전.
6. **보급 레벨** — S1 정식 클리어 시 레벨 1 해금·저장. 상점/가챠/오프라인 없음.

조작: Enter 시작, Space 사격, U 업글, A 자동(업글1 이후), 철수/재도전.

## 헤드리스 검증

```bash
godot --path . --headless res://tests/Verify.tscn
```

요구 버전: Godot 4.7.x (4.x 계열에서 열리도록 `config/features` 는 4.7).
