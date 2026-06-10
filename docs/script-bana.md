# 바나 보이스 스크립트 (뱀파이어 메이드)

> 바나 슬라이스 #10 — 바나 전용 대사. **실데이터는 `data/ticker.json`(`bana`·`bana_cutin`) · `data/talk.json`(`bana`) · `data/gifts.json`(`bana`)** 에 있고(콘텐츠 스튜디오/JSON 편집), 이 문서는 **톤 가이드 + 설계 근거**다.
> 관련: [CONTEXT.md](../CONTEXT.md) 도메인 용어 · [docs/script-okja.md](./script-okja.md) 옥자 대비 · [docs/script-miho.md](./script-miho.md) 미호 대비 · [gemini-prompts-bana.md](./gemini-prompts-bana.md) 비주얼 · 추적 이슈 [#10](https://github.com/JeffKM/Narakuchi/issues/10).

## 🦇 캐릭터 톤

- **정체성**: 뱀파이어 메이드. 반려묘 **코코**(까맣고 마른 고양이, 펫 슬라이스 #11). 시그니처 음료 **블러디 미드나잇**(자정처럼 붉은 한 잔).
- **무드**: **우아·나른 + 은근한 새침 + 밤의 여유.** 옥자(시크·츤데레)·미호(애교·여우)와 또 다른 축 — 바나는 **느긋하고 농염하되, 가끔 새침하게 토라진다.**
  - 옥자: "기다린 건 아니고…" (츤데레)
  - 미호: "오실 줄 알았어요. 후훗." (애교·자신감)
  - 바나: "해가 지면 오실 줄 알았어요. 밤은 제 시간이거든요." (나른·우아)
- **셀프 모티프**(대사에 자연스럽게 녹임): **밤·자정·달**·**송곳니/깨물기**(장난스러운 위협)·**박쥐**·**관(棺)·영원**·**차가운 손**·**멈췄던 심장**·반려묘 **코코**·**블러디 미드나잇**.
- **말버릇**: "후훗", "~걸요", "~거든요", "~잖아". 나른하게 끝을 늘인다.

## 🗣 말투 분기 (옥자·미호와 동일 규칙)

| 단계 | 임계(누적) | 말투 | 비고 |
|---|---|---|---|
| 손님 guest | 0 | 존댓말 + "{nick}님" | 우아한 존댓말 |
| 단골 regular | 200 | **아직 존댓말**(살가운) | 단골 등극 컷인 |
| 편해진 사이 comfy | 600 | **반말 전환** | 반말 해금 컷인(핵심 보상) |
| 마음 연 사이 close | 2000 | 반말(속내) | 전용 연출 후속 |

> 분기 단일 출처 `Balance.is_casual(stage)` — character별 `affinity_total` 로 stage 만 계산해 넘기면 옥자/미호/바나가 독립 분기(서로 말투 누설 없음). 데이터는 ticker/talk/gifts 의 `guest`(존댓말)·`regular`(반말) 풀.

## 📟 티커 (상황 × 단계) — `ticker.json` `bana`

옥자와 **같은 상황 키 미러**: `enter`·`neglect`·`cheki`·`drink`·`talk`·`gift`·`touch`·`touch_cap`·`no_stamina`·`cheki_get`·`idle`. (코드 연동이라 키 추가/삭제 금지, 내용만 편집)

- **drink = 블러디 미드나잇 제조 보이스**(시그니처). 별도 음료 데이터 없이 이 풀로 표현 — 라이브는 `bana_brew` 표정(잔 든 손) + brew 연출 공유.
- 대표 라인:
  - enter(guest): "어머, {nick}님. 해가 지면 오실 줄 알았어요. 밤은 제 시간이거든요."
  - drink(guest): "블러디 미드나잇, 정성껏 만들어 드릴게요. 자정처럼 붉은 한 잔이에요."
  - touch(guest): "어머, 차갑죠? 뱀파이어 손은 원래 이래요."
  - gift(guest): "저 주시는 거예요? 어머… 멈췄던 심장이 다시 뛰는 것 같아요."
  - idle(guest): "코코가 또 제 망토 속에서 자네요."

## 💬 대화 토막 — `talk.json` `bana`

`대화` 버튼 2~3지선다(guest/regular 각 3토막). 바나 모티프로 분기: 송곳니·박쥐·코코·자정의 달. `good`(↑↑) 선택은 나른한 보상, `plain`(↑)은 은근한 새침.

## 🎁 선물 선호표 — `gifts.json` `bana`

옥자와 **동일 라인업·tier·아이콘**, reply 만 바나 톤. 고양이 츄르는 반려묘 **코코** 것(`sion` tier = 매우 좋아함). 시그니처 취향은 밤·붉은 빛 모티프로 reply 에 반영.

## 🎬 단계 컷인 — `ticker.json` `bana_cutin`

`StageCutin` 오버레이(다음 입장 1회). `regular`=단골 등극(존댓말 유지), `comfy`=반말 해금(핵심 보상).

- regular reveal: "{nick}님, 또 와주셨네요." → 단골 등극 톤
- comfy reveal: "이제부터 반말할게, {nick}." / badge "✦ 반말 해금 ✦"
  - 컷인 3줄: "{nick}님. ……아니." → "이제 그냥 {nick}이라고 부를래. 우리, 그 정도는 됐잖아?" → "뱀파이어가 곁을 내준 거야. 영광인 줄 알아? 후훗."

> 옥자(츤데레)·미호(솔직·당당) 컷인과 대비되는 **우아하게 곁을 내주는** 톤이 바나다움 — 영원을 사는 존재가 찰나의 곁을 허락하는 무게.

## 🔌 배선 (코드)

- `data/characters.gd`: 바나 `dialogue: "bana"`·`sprite: "bana"`·`buttons: "bana"`·`accent: Palette.PURPLE`·`intro_event: "mine"` (6표정은 `bana_{idle/smile/shy/sad/brew/talk}` 누끼).
- `data/balance.gd`: `GAUGE_BANA = 300`(옥자·미호 미러) → `Characters.gauge_full("bana")`.
- `data/events.gd`: `mine`(지뢰계) `bana: true` 참여 → 컬렉션북 비대칭 그리드 정상(다른 이벤트 의상은 점증).
- `data/dialogue.gd`: 전 함수가 `dialogue_key` 첫 인자. ticker 는 키 직접, talk/gifts 는 `_section` 폴백 — **content_studio 무손상**.
- `cafe.gd`(`_dialogue_key()`) · `splash.gd`(`_main_id()`) · `stage_cutin.gd`(`setup(…, character)`) 가 active_main 을 따라 바나 대사·렌더.
- 컬렉션북: `collection_book.gd` `TABS` 바나 메인 섹션 `locked: false` — 미빌드 실루엣 → 실제 지뢰계 그리드.
