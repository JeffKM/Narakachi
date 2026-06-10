# 멜 보이스 스크립트 (강시 메이드)

> 멜 본배선 #14 — 멜 전용 대사. **실데이터는 `data/ticker.json`(`mel`·`mel_cutin`) · `data/talk.json`(`mel`) · `data/gifts.json`(`mel`)** 에 있고(콘텐츠 스튜디오/JSON 편집), 이 문서는 **톤 가이드 + 설계 근거**다.
> 관련: [CONTEXT.md](../CONTEXT.md) 도메인 용어 · [docs/script-okja.md](./script-okja.md) 옥자 대비 · [docs/script-miho.md](./script-miho.md) 미호 대비 · [docs/script-bana.md](./script-bana.md) 바나 대비 · [gemini-prompts-mel.md](./gemini-prompts-mel.md) 비주얼 · 추적 이슈 [#14](https://github.com/JeffKM/Narakuchi/issues/14).

## 🧧 캐릭터 톤

- **정체성**: 강시 메이드(중국 강시 컨셉). 반려견 **선아**(갈색 푸들)·**수아**(베이지 닥스훈트, 펫 슬라이스 #15/#16). 시그니처 음료 **청운 에이드**(푸른 구름처럼 맑은 청록빛 한 잔).
- **무드**: **단정·새초롬 + 동양적 정갈함.** 옥자(시크·츤데레)·미호(애교·여우)·바나(나른·우아)와 또 다른 축 — 멜은 **반듯하고 새침하되, 단정함이 흐트러질 때 살짝 부끄러워한다.**
  - 옥자: "기다린 건 아니고…" (츤데레)
  - 미호: "오실 줄 알았어요. 후훗." (애교·자신감)
  - 바나: "해가 지면 오실 줄 알았어요." (나른·우아)
  - 멜: "부적에 귀한 손님 오신다 적혀 있더니, 정말이었네요." (단정·동양적)
- **셀프 모티프**(대사에 자연스럽게 녹임): **부적**·**달·달빛**·**청운 에이드**(푸른 구름)·**강시 폴짝**(점프)·**옷매무새/옷고름/관모**·**차가운 손**(강시)·**볼 빨간 점**·반려견 **선아·수아**.
- **말버릇**: "~답니다", "~네요", "~지요", "후훗". 단정하게 끝을 여민다. 반말 단계에선 "새초롬한 척"·"단정해야 하는데"로 정체성 유지.

## 🗣 말투 분기 (옥자·미호·바나와 동일 규칙)

| 단계 | 임계(누적) | 말투 | 비고 |
|---|---|---|---|
| 손님 guest | 0 | 존댓말 + "{nick}님" | 단정한 존댓말 |
| 단골 regular | 200 | **아직 존댓말**(살가운) | 단골 등극 컷인 |
| 편해진 사이 comfy | 600 | **반말 전환** | 반말 해금 컷인(핵심 보상) |
| 마음 연 사이 close | 2000 | 반말(속내) | 전용 연출 후속 |

> 분기 단일 출처 `Balance.is_casual(stage)` — character별 `affinity_total` 로 stage 만 계산해 넘기면 옥자/미호/바나/멜이 독립 분기(서로 말투 누설 없음). 데이터는 ticker/talk/gifts 의 `guest`(존댓말)·`regular`(반말) 풀.

## 📟 티커 (상황 × 단계) — `ticker.json` `mel`

옥자와 **같은 상황 키 미러**: `enter`·`neglect`·`cheki`·`drink`·`talk`·`gift`·`touch`·`touch_cap`·`no_stamina`·`cheki_get`·`idle`. (코드 연동이라 키 추가/삭제 금지, 내용만 편집)

- **drink = 청운 에이드 제조 보이스**(시그니처). 별도 음료 데이터 없이 이 풀로 표현 — 라이브는 `mel_brew` 표정(청록 음료 잔 든 손) + brew 연출 공유(`buttons.json` `mel.emotion.drink = brew`).
- 대표 라인:
  - enter(guest): "어서 오세요, {nick}님. 부적에 귀한 손님 오신다 적혀 있더니, 정말이었네요."
  - drink(guest): "청운 에이드, 정성껏 내어드릴게요. 푸른 구름처럼 맑은 한 잔이에요."
  - touch(guest): "어머, 손이 차죠? 강시라 그래요. 놀라지 마세요."
  - gift(guest): "저 주시는 거예요? 어머… 옷깃이 다 여며지질 않네요, 두근거려서."
  - idle(guest): "선아랑 수아가 또 제 치맛자락에서 잠들었네요."

## 💬 대화 토막 — `talk.json` `mel`

`대화` 버튼 2~3지선다(guest/regular 각 3토막). 멜 모티프로 분기: 부적·강시 폴짝·관모·선아/수아. `good`(↑↑) 선택은 단정함이 풀리는 부끄럼, `plain`(↑)은 새초롬한 정갈함.

## 🎁 선물 선호표 — `gifts.json` `mel`

옥자와 **동일 라인업·tier·아이콘**, reply 만 멜 톤. 반려견(선아·수아)용 **강아지 간식**이 `sion` tier(가장 좋아함 — 바나의 고양이 츄르 자리). 시그니처 취향은 달·맑음·단정 모티프로 reply 에 반영.

## 🎬 단계 컷인 — `ticker.json` `mel_cutin`

`StageCutin` 오버레이(다음 입장 1회). `regular`=단골 등극(존댓말 유지), `comfy`=반말 해금(핵심 보상).

- regular reveal: "{nick}님, 또 와주셨네요." → 단골 등극 톤
- comfy reveal: "이제부터 반말할게, {nick}." / badge "✦ 반말 해금 ✦"
  - 컷인 3줄: "{nick}님. ……아니." → "이제 그냥 {nick}이라고 부를래. 우리, 그 정도는 됐잖아?" → "강시가 곁을 내준 거야. 새초롬한 척해도, 진심이야."

> 옥자(츤데레)·미호(솔직·당당)·바나(우아하게 곁을 내줌) 컷인과 대비되는 **단정함을 풀고 곁을 허락하는** 톤이 멜다움 — 반듯하던 강시 아가씨가 새초롬한 척 진심을 내미는 무게.

## 🔌 배선 (코드)

- `data/characters.gd`: 멜 `dialogue: "mel"`·`sprite: "mel"`·`buttons: "mel"`·`accent: Palette.TEAL`·`intro_event: "mine"` (6표정은 `mel_{idle/smile/shy/sad/brew/talk}` 누끼).
- `data/buttons.json`: 멜 `emotion`(cheki=smile·drink=brew·touch=[shy,smile]·touch_cap=sad) 전용. 라벨·순서는 okja.actions 공유(잠금).
- `data/balance.gd`: `GAUGE_MEL = 300`(옥자·미호·바나 미러) → `Characters.gauge_full("mel")`.
- `data/events.gd`: `mine`(지뢰계) `mel: true` 참여 → 컬렉션북 비대칭 그리드 정상(다른 이벤트 의상은 점증).
- `data/dialogue.gd`: 전 함수가 `dialogue_key` 첫 인자. ticker 는 키 직접, talk/gifts 는 `_section` 폴백 — **content_studio 무손상**.
- `cafe.gd`(`_dialogue_key()`) · `splash.gd`(`_main_id()`) · `stage_cutin.gd`(`setup(…, character)`) 가 active_main 을 따라 멜 대사·렌더.
- 컬렉션북: `collection_book.gd` `TABS` 멜 **메인 섹션** `locked: false`(바나 뒤) — 잠긴 예고 → 실제 지뢰계 그리드.
