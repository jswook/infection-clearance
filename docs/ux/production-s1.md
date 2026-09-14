# S1 프로덕션 비주얼 스펙 (#12)

대외명 **봉쇄구역: 제로**. 미션·보급 카피 **감염 클리어런스**. 구역: **S1 경찰서 지구**.

이슈: [#12](https://github.com/jswook/infection-clearance/issues/12) (표피·에셋 우선순위). 검증 게이트(실제 인게임 프레임)는 [#21](https://github.com/jswook/infection-clearance/pull/21)을 유지한다.

Godot 게임플레이 코드는 이 문서만으로 바꾸지 않는다. 프로덕션 PNG를 P0 훅에 갈아끼우는 표피 파이프라인만 고정한다.

## 목표

완성 톤(**RE·암·고퀄**) 표피. 레지던트 이블 계열 분위기(원작 IP, 카피·에셋·고유명 인용 없음).

- **검증 게이트는 #21 유지.** QA는 같은 5장 런타임 프레임으로 A/B/C·UX 1–5를 판정한다.
- **HUD 100% 목업 복제 금지.** 레이아웃·카피·게이트는 유지하고, 비주얼만 프로덕션 톤으로 올린다.

## 유지 (게이트)

프로덕션 아트가 들어가도 아래는 깨지면 실패다.

- **G2:** 탭·업글·선택만. 조이스틱 / 구르기 / 액티브 스킬 슬롯 없음.
- **C10:** 첫 10분 상점·재화+·에너지/스테미나 게이트·웨이브 스킵 없음. ([gates.md](../planning/gates.md) C10)
- **UX 1–5:** 업글 버튼만 점멸, 「이번만」 1회, 목표 비상구, 순서 탭→업글→선택→목표→자동→메타. ([acceptance.md](./acceptance.md))
- **네이밍:** 대외 **봉쇄구역: 제로** / 미션·보급 **감염 클리어런스**. ([naming.md](./naming.md))

## S1 첫 10분 HUD에 넣지 말 것

첫 10분 표피·HUD에 다음을 넣지 않는다. 목업에 있어도 프로덕션에 이식하지 않는다.

- 편성·기지 허브
- 결제+
- 스킬 바
- 골드 카피

## 프로덕션 에셋 경로 (교체 대상)

P0 훅 경로를 그대로 쓴다. 새 슬롯·새 HUD를 만들지 않는다. 현재 시트 안내는 [art/README.md](../../art/README.md).

| 경로 | 교체 대상 |
| --- | --- |
| `art/ui/ui_upgrade.png` | 업글 CTA (점멸은 이 훅만) |
| `art/ui/ui_boost_once.png` | 「이번만」 (카피: **스크랩/보급**, 골드 금지) |
| `art/ui/ui_goal_exit.png` | 목표: **비상구** |
| `art/enemies/enemies_z1_b1.png` | Z1–Z6·B1 |
| `art/fx/fx_kill_scrap.png` | 처치/스크랩 |
| `art/characters/player.png` | 플레이어 (있으면) |

「이번만」과 HUD 재화 카피는 **스크랩·보급**만 쓴다. 골드는 금지.

## 수용 기준

P0 훅을 그대로 갈아끼웠을 때 QA가 **A/B/C·UX 1–5 회귀 PASS**.

- 이펙트는 단계적으로 올려도 된다 (한 PR에서 풀 VFX를 요구하지 않는다).
- 점멸·카드·실루엣·처치/스크랩이 #21과 같은 장면에서 읽히면 통과다.
- G2·C10·네이밍이 표피로 깨지면 실패다.

## 단계

1. **스펙 머지** — 이 문서 (`docs/ux/production-s1.md`)를 `develop`에 머지한다.
2. **프로덕션 PNG를 `art/`에 PR** — 위 경로만 교체. 게임 로직 없음.
3. **개발 임포트·연출** — 기존 P0 훅(`TextureRect` / `Sprite2D` / `P0Art.gd` 영역)에 임포트. HUD 목업 재배치 없음.
4. **QA 회귀** — #21 캡처 하네스 + [s1-checklist.md](../qa/s1-checklist.md)로 A/B/C·UX 1–5 PASS.

## 교차 링크

- 표피·에셋 우선순위: [s1-asset-needs.md](../planning/s1-asset-needs.md) (#12)
- 기획 게이트 A–C: [gates.md](../planning/gates.md)
- 온보딩 와이어: [onboarding-s1.md](./onboarding-s1.md)
- UX 합격 1–5: [acceptance.md](./acceptance.md)
- 표기: [naming.md](./naming.md)
- QA 체크리스트: [s1-checklist.md](../qa/s1-checklist.md)
- P0 훅·아틀라스: [art/README.md](../../art/README.md)
- 검증 프레임: [#21](https://github.com/jswook/infection-clearance/pull/21)
