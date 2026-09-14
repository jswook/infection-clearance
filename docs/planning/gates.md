# 기획 게이트 A–C (S1 / 봉쇄구역: 제로)

QA·개발 플레이테스트는 **A/B/C 번호를 로그**한다. 깨진 항목만 GitHub 이슈로 남긴다.

감정 프레임은 **「정수 지도」** (Feeling Engine): **결핍 → 기대 → 해소**.

## 목적

S1 경찰서 지구 플레이테스트에서 감정·밸런스·과금 좌석을 같은 번호로 판정한다. 통과한 항목은 적지 않는다. 깨진 게이트만 이슈로 올린다.

| 라벨 | 좌석 | 예 |
| --- | --- | --- |
| `planning` | 밸런스 / 감정 / 과금 좌석 | 성장 비율, 결핍 사이클, 상점 노출 시점 |
| `ux` | 체감 / VFX | 점멸, 연출, 「이번만」 카드 느낌 |
| `qa` | 구현 | 수치 미적용, 실드 표시≠실제, 재도전 막힘 |

이슈 제목 대외명: **봉쇄구역: 제로**. 본문 미션/구역: **감염 클리어런스** / **S1 경찰서 지구**.

## A. 감정 엔진

1. **결핍 → 기대 → 해소**가 세 층에서 돈다.
   - **초:** 처치 피드백
   - **분:** 벽·보스 (로비 → 복도 → 무기고 → 주차장 → 비상구 B1)
   - **메타:** 보급레벨 (감염 클리어런스 보급)
2. **자기귀인.** 무기고에서 화력 vs 탄약효율을 고른 뒤, 업글 체감이 「내가 고른 탓」으로 읽혀야 한다.
3. **O3 바닥.** 첫 실패는 D0 추방이 아니다. 「이번만」 무료 부스트 1회로 회복하고 재도전한다.
4. **S-17.** 주스(연출·스크린셰이크·이펙트)만 있고 실제 수치가 안 바뀌면 실패다.

## B. 밸런스

5. **O1.** 처치·피드백이 1–5초 안에 온다.
6. **S1 성장.** 업글·몹 HP는 **비율**로 커진다. 절대값 점프는 실패다.
7. **B2.** 업글 없이 보스(비상구 B1)로 건너뛸 수 없다. 업글 있으면 클리어는 약 6–8분.
8. **R0.** 목표는 항상 보인다. 재도전 마찰 ≈ 0.
9. **B1 실드.** 실드 페이즈는 피해 50%. **표시 = 실제**.

## C. 결핍 → 과금 (프로토 좌석)

10. **첫 10분.** 상점 / 가챠 / 결제 UI를 열지 않는다.
11. **이후.** 숏컷은 결핍 피크(M1–M3)에서만. 유일한 진행 경로가 되면 실패다.
12. **F2P.** 과금 없이 S1을 클리어할 수 있는 궤적이 있어야 한다.

## 표기

| 용도 | 표기 |
| --- | --- |
| 대외명 | **봉쇄구역: 제로** |
| 미션·보급 UI | **감염 클리어런스** |
| 레포 | `infection-clearance` |

내부 문서·경로·브랜치는 `docs/planning`처럼 영문이어도, 본문 카피는 위 표기를 따른다. 표기 상세는 [docs/ux/naming.md](../ux/naming.md).

## 교차 링크

- QA 체크리스트: [docs/qa/s1-checklist.md](../qa/s1-checklist.md) (기획 1–8, UX 합격 1–5)
- UX 합격: [docs/ux/acceptance.md](../ux/acceptance.md)
- UX 온보딩 와이어: [docs/ux/onboarding-s1.md](../ux/onboarding-s1.md)
- S1 표피·에셋: [s1-asset-needs.md](./s1-asset-needs.md) (#12)
- UX 인덱스: [docs/ux/README.md](../ux/README.md)

게이트 A–C가 QA 기획 1–8·UX 합격 1–5와 겹치면, 플레이테스트 로그에는 **이 문서의 A/B/C 번호**를 쓰고, 구현 버그는 `qa`로 넘긴다.

## 밸런스 수치

S1 적·업글 상수는 `autoload/Balance.gd`를 단일 출처로 한다. 탄약효율 UI는 `Balance.ammo_eff_choice_copy()` (`UPGRADE1_AMMO_COST_MULT` ×0.45, `UPGRADE1_AMMO_MAG_BONUS` +8).

판정에 쓰는 상수 (`autoload/Balance.gd`):

| 게이트 | 상수 |
| --- | --- |
| A3 「이번만」 | `IBEONMAN_DAMAGE_MULT`, `IBEONMAN_HP_BONUS`, `IBEONMAN_AMMO_BONUS` — 카피 `ibeonman_supply_copy()` (보급, 골드 아님) |
| B5 O1 | `O1_FIRST_KILL_MIN_SEC` / `O1_FIRST_KILL_MAX_SEC` (1–5초) |
| B6 비율 성장 | `UPGRADE1_FIREPOWER_MULT`, `UPGRADE1_AMMO_COST_MULT`, `UPGRADE1_AMMO_MAG_BONUS`, `ENEMY.*.hp` |
| B9 B1 실드 | `B1_SHIELD_DAMAGE_TAKEN` (0.5), `B1_SHIELD_DISPLAY` |
| 구역 | `ZONES` — 로비 → 복도 → 무기고 → 주차장 → 비상구 B1 |
