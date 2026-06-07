# Gemini 도트 변환 프롬프트 — 옥자

> 워크플로우 B: **AI는 형태·색감만, 규격은 `tools/dotify.py`가 강제.** (→ [tools/README.md](../tools/README.md))
> ADR 0001 파이프라인 = **실물 사진 → AI 도트화**. 상상 생성이 아니라 **사진 변환(img2img)**이 기본이다 — 인물 고증·일관성을 위해.
> 공용 에셋(체키 프레임·배경·UI·셸)은 [공통 파일](./gemini-prompts-common.md)로 분리. 핵심 원칙도 그쪽 참조. (허브: [gemini-prompts.md](./gemini-prompts.md))

> **옥자**: 사장, 지옥의 마녀. 메인 교감·수집 캐릭터(라이브, 기본=마녀룩). 시크·츤데레·장난기.

---

## 공통 베이스 (옥자)

```
Convert the attached photo into retro pixel art / dot art, full body, front-facing standing pose.
Subject: "Okja", the witch-owner of a maid cafe — a hell witch. Chic, tsundere, playful.
Base outfit: witch-maid look (dark antique witch dress with maid accents).
Style: 8-bit pixel sprite, limited palette, hard pixel edges, NO anti-aliasing, NO gradients.
Color mood: dark antique — deep burgundy, blood red, antique gold, ink black, candle yellow.
Framing: full body centered, head near top, feet near bottom, tall vertical 4:9 portrait ratio,
         even margins, consistent crop across all expressions.
         Lower body and legs IDENTICAL across all expressions — only the FACE and ARM pose change.
Background: FLAT SOLID chroma green (#00ff00), no scenery, no props, no shadow on background.
```

### 네거티브 (공통)

```
no text, no watermark, no signature, no multiple characters, no cropped limbs,
no background scenery, no gradient background, no soft anti-aliased edges,
no realistic photo finish, no 3D render.
```

### 표정 6종 — 베이스에 한 줄만 추가

**다리·하체·프레이밍은 고정**하고, **얼굴 표정 + 팔 자세**를 바꾼다(팔도 그림에 박는다 — 리깅 아님). (표정별 사진이 있으면 각각 변환이 더 정확)

| 파일명 | 추가 문구 |
|---|---|
| `okja_idle`    | `Expression: calm, mouth closed. Arms: both hands clasped together in front (default).` |
| `okja_smile`   | `Expression: soft warm smile, eyes gently curved. Arms: both hands clasped together up near the chest, delighted / pleased.` |
| `okja_shy`     | `Expression: shy, blushing cheeks, eyes averted. Arms: one hand raised, covering the mouth.` |
| `okja_sad`     | `Expression: sulky / pouting, downturned mouth (NEVER crying). Arms: lowered and drooping limply.` |
| `okja_brew`    | `Expression: focused "brewing". Arms: holding a drink / cup in both hands.` |
| `okja_talk`    | `Expression: mouth slightly open, talking. Arms: one hand raised in a gesture.` |

> ⚠️ **6종 전부 팔 자세가 다르다** (다리·하체·프레이밍만 고정). 전환은 하드컷 + 스쿼시 정착이라 팔 차이가 커도 OK. 기쁨 "팔 벌려 폴짝" 같은 전신 포즈는 별도로 그리지 않고 `okja_smile`을 리워드 순간에 **코드 hop**으로 재사용한다. 슬픔은 **팔 처짐 시무룩까지** — 우는 그림 금지(벌 없는 설계).

---

## 옥자 SD(데포르메) 버전 ★권장 — 라이브 스탠딩용

> **왜 SD인가**: 다마고치 LCD는 작아서 1:7 실사 비율이면 얼굴이 ~35px로 쪼그라들어 **표정 차이가 안 읽힌다.** 코어 메커닉이 "표정 9할 + 표정 스왑 6종"이므로 머리를 키운 SD가 표정 가독성·공유성·제작 일관성에서 유리하다(→ 실사 정교판은 타이틀 키비주얼·★히어로 체키 등 감상용으로 분리).
> **비율**: 극단 아기치비 말고 **1:3~1:4 "미니"** — 시크·츤데레 매력은 유지하되 얼굴·눈을 또렷하게.

```
Convert the attached photo into a CUTE CHIBI / SD pixel art sprite, full body, front-facing standing pose.
Subject: "Okja", the witch-owner of a maid cafe — a hell witch. Chic, tsundere, playful.
Proportions: super-deformed, head-to-body ratio about 1:3 ~ 1:4 — BIG head, large expressive eyes,
             short rounded body and short legs. Keep her recognizable witch-maid silhouette.
Base outfit: witch-maid look (dark antique witch dress with maid accents, witch hat).
Style: 8-bit pixel sprite / dot art, limited palette, hard pixel edges, NO anti-aliasing, NO gradients.
Color mood: dark antique — deep burgundy, blood red, antique gold, ink black, candle yellow.
Framing: full body centered, big head near top, short legs near bottom, tall vertical 4:9 portrait ratio,
         even margins, consistent crop across all expressions.
         Lower body and short legs IDENTICAL across all expressions — only the FACE and ARM pose change.
Background: FLAT SOLID chroma green (#00ff00), no scenery, no props, no shadow on background.
```

### 네거티브 (SD 추가분 — 공통 네거티브에 더한다)

```
no realistic body proportions, no long thin legs, no adult tall figure,
no tiny face, no baby-only infantile style (keep her chic witch charm).
```

> 표정 6종은 **위 "표정 6종" 표를 그대로** 쓴다(베이스만 이 SD 프롬프트로 교체). 규격도 동일 — `dotify --preset okja`(128×288)로 후처리하면 머리 큰 SD가 캔버스 상단에 또렷하게 안착한다.
> 팁: SD는 눈이 큰 만큼 **표정 변화(눈 곡선·홍조·입모양)를 과장**해야 다마고치 크기에서 확 읽힌다.

---

## 옥자 지뢰계(★히어로) 의상 (이벤트 의상 1세트)

> 이벤트 데이 "지뢰계" 의상의 옥자. ★히어로 = 데모 5종 중 대표라 가장 공들인다(→ [asset-checklist.md](./asset-checklist.md) A2).
> **🔑 이건 체키 카드용 정적 아트다 — 표정 스왑 호환 불필요.** 이벤트 의상은 **교감화면에서 갈아입는 스킨이 아니라** 체키(정적 수집물)에만 들어간다(→ PRD §6·§9.1, 라이브 옥자는 마녀룩 고정). 그러니 idle 포즈·와인레드에 묶일 필요 없이 **레퍼런스 사진 그대로 카드답게 멋진 포즈·머리색**으로 뽑는다.
> **🔑 워크플로우**: 텍스트만으로 새로 뽑으면 옥자 얼굴이 흔들린다. **① 확정된 `okja_idle.png`(SD 도트 — 얼굴·정체성·등신비 락) + ② 지뢰계 레퍼런스 사진(의상·머리색·포즈 락) + ③ 신발 레퍼런스 사진(신발 락)** 세 장을 첨부하고 "1번 캐릭터를 2·3번 코디로 다시 그려라"로 요청한다(멀티 이미지 편집).
> **지뢰계 레퍼 코디**(첨부 사진): 레오파드 무늬 베레모 · 흰 시스루 시폰 블라우스(앞 리본 레이스업) · 검정 레이스 캐미솔 + 가슴 크로스 장식 · 연청 데님 미니 플리츠 · 십자가 목걸이 · 메탈하트/리본 벨트 체인 · **금발 트윈테일** · **갸루 포즈(고개 살짝 기울이고 한 손 얼굴 옆 손가락 펼침, 새침한 태도)** · **검정 통굽 플랫폼 크리퍼 스니커즈(별 장식 + 은색 체인) + 흰 슬라우치 양말**.

```
[Attach THREE images — 1: okja_idle.png (confirmed SD dot, identity lock),
 2: the jirai-kei outfit reference photo, 3: the shoes reference photo]

Keep image 1's character IDENTITY: same face shape, same eyes, same chic tsundere look,
same SD chibi proportions (head:body ≈ 1:3~1:4). RESTYLE her as the jirai-kei coordinate,
matching image 2 for outfit, HAIR and POSE, and image 3 for the shoes:
- Hair: BLONDE long TWIN-TAILS (NOT wine-red, NOT brown — bright blonde).
- Pose: a playful GYARU selfie pose — head tilted slightly, hip cocked to one side, sassy attitude,
        ONE hand raised up beside the face / temple with fingers spread (relaxed peace-ish gesture,
        like image 2), the other arm relaxed. NOT the clasped-hands idle pose.
- Headwear: a LEOPARD-PRINT beret / hunting cap.
- Top: white SHEER chiffon long-sleeve blouse with a front ribbon lace-up,
       over a BLACK LACE camisole, with a black CROSS ornament on the chest.
- Bottom: light-wash DENIM pleated mini skirt.
- Accessories: silver CROSS necklace, a metal-HEART & ribbon belt chain at the waist.
- Shoes: chunky BLACK PLATFORM creeper sneakers with STAR charms and a silver CHAIN,
         worn with WHITE SLOUCH socks (match image 3).
- Expression: calm, cool, mouth closed.
Style: 8-bit pixel sprite / dot art, hard pixel edges, NO anti-aliasing, NO gradients, flat shading.
       Keep her chic tsundere charm; jirai-kei girly-grunge mood but still the SAME Okja.
Framing: FULL body centered (head to shoes all visible), big head near top, feet near bottom,
         tall vertical 4:9 portrait, even margins.
Background: FLAT SOLID chroma green (#00ff00), no scenery, no props, no shadow on background.
```

### 네거티브 (지뢰계 — 공통 네거티브에 더한다)

```
no realistic body proportions, no long thin legs, no adult tall figure, no tiny face,
no different face, no extra characters, no cropped feet, no hidden shoes,
no witch hat, no wine-red hair, no brown hair (this cut is BLONDE), no original burgundy witch dress
(it is fully replaced by the jirai-kei outfit),
no plain flat shoes, no over-sexualized outfit (keep it cute girly-grunge, age-safe brand).
```

> ⚠️ **검수 포인트**: 체키 카드 안에 들어갈 정적 아트이므로 idle 앵커 일치는 불필요. **얼굴(옥자 정체성) 일관성 + 신발까지 프레임 안에 다 들어왔는지**를 본다. 레오파드/데님/체인은 색이 튀니 후처리 **마스터 팔레트 인덱싱 필수**. 저장: `assets/sprites/okja_jirai.png`.
> 💡 신발 사진 첨부가 안 되면(2장만 지원), `Shoes:` 줄의 텍스트 묘사만으로도 충분하다 — 3번 이미지 참조 문구만 지운다.
> 📌 **나머지 4종 의상(유치원·힙합·집사·크리스마스)도 같은 방식** — 모두 체키 카드용 정적 아트라 포즈·머리색 자유. 이 프롬프트를 베이스로 의상·신발 레퍼런스만 갈아끼우면 된다.
> 🃏 **체키 합성 레이어**: 지뢰계 옥자 체키 = `okja_jirai`(누끼) + **옥자 배경 `bg_cheki_okja_jirai`**(캐릭터×이벤트별 → ADR 0003 개정 2026-06-07) + 이벤트 공통 `frame_jirai`(→ [공통 파일](./gemini-prompts-common.md)). 옥자 배경 4종(유치원·힙합·집사·크리스마스)도 모두 `bg_cheki_okja_{slug}`.

---

## 옥자 이벤트 의상 4종 확장 (유치원·힙합·집사·크리스마스) → ROADMAP 아트트랙

> 지뢰계(★히어로)에서 확립한 방식 그대로 **나머지 4개 이벤트로 복제**한다. 파일명 접미사는 `data/events.gd`의 **slug**(유치원=`kinder` · 힙합=`hiphop` · 집사=`butler` · 크리스마스=`xmas`)를 따른다.
> **🔑 공통 규칙(재확인)**: ① 의상은 모두 **체키 카드용 정적 아트** — idle 앵커 일치 불필요, 포즈·머리색 자유(라이브 옥자는 마녀룩 고정). ② 의상 캔버스는 **`128×288`(preset okja)**, 머리 위는 비우고 발끝까지 프레임 안. ③ 전부 마스터 팔레트(~32색) 인덱싱. ④ 짝이 되는 **테마 프레임·사진 배경은 공용**(→ [공통 파일](./gemini-prompts-common.md)).
> **⚠️ 크리스마스만 크로마키 예외**: 산타 의상·홀리에 **초록이 들어가므로 크로마 그린 대신 마젠타 `#ff00ff`** 로 받는다(→ 공통 핵심 원칙 #2).

### ① 유치원 (`okja_kinder`)

> 레퍼 코디: 노란 **버킷햇** · **하늘색 카라 셔츠**(가슴 빨강 **명찰**) · 흰 **주름 스커트** · 흰 무릎양말 + 흰 신발 · **펭귄(핑구) 인형 백팩** · 보라 곱창밴드 트윈테일 · 빨강 손목밴드. 천진난만·해맑게.

```
[Attach TWO images — 1: okja_idle.png (confirmed SD dot, identity lock), 2: a kindergarten / preschool uniform reference photo]
Keep image 1's character IDENTITY: same face shape, same eyes, same chic tsundere look,
same SD chibi proportions (head:body ≈ 1:3~1:4). RESTYLE her as a cute KINDERGARTEN pupil coordinate (image 2):
- Hair: low TWIN-TAILS tied with PURPLE scrunchies, bright and youthful — NOT the witch look.
- Pose: innocent and childlike — one fist rubbing an eye (sleepy / about-to-cry cute gesture), or both hands held happily.
- Headwear: a YELLOW bucket hat.
- Top: a LIGHT-BLUE (sky blue) collared smock shirt, with a small round RED NAME TAG / badge on the chest.
- Bottom: a short WHITE PLEATED skirt.
- Accessory: a cute PENGUIN (Pingu-style) plush BACKPACK on her back with orange straps; a RED WRISTBAND.
- Shoes: WHITE knee socks and small WHITE sneakers.
- Expression: bright innocent face, slightly pouty / teary-cute.
Style: 8-bit pixel sprite / dot art, hard pixel edges, NO anti-aliasing, NO gradients, flat shading.
       Keep her recognizable as the SAME Okja, just dressed as a sweet kindergartener.
Framing: FULL body centered (head to shoes all visible), big head near top, feet near bottom, tall vertical 4:9 portrait, even margins.
Background: FLAT SOLID chroma green (#00ff00), no scenery, no props, no shadow on background.
```

네거티브(공통 + 추가): `no witch hat, no witch dress (fully replaced), no yellow suspender shorts (top is light-blue shirt, bottom is white skirt), no over-mature outfit (keep it childlike & age-safe), no different face, no cropped feet.`

### ② 힙합 (`okja_hiphop`)

> 레퍼 코디: 오버핏 **흑+실버 컬러블록 풋볼 저지**(올드잉글리시 블랙레터 레터링) + 안에 검정 티 레이어드 · 차콜 **니트 비니**(고딕 자수) · **실버 체인** · 빨강 손목시계 · 손가락 힙합 제스처. 고스 스트릿 무드.

```
[Attach TWO images — 1: okja_idle.png (identity lock), 2: a streetwear / hip-hop outfit reference photo]
Keep image 1's character IDENTITY: same face, same chic tsundere look, same SD chibi proportions (1:3~1:4).
RESTYLE her as a GOTH-STREET / HIP-HOP coordinate (image 2):
- Hair: long straight ASH-SILVER hair with blunt bangs and GREEN dip-dyed tips, plus one thin braided strand — cool and edgy.
- Pose: a confident HIP-HOP gesture — one hand throwing a relaxed finger sign near the face, swagger attitude.
- Top: an OVERSIZED football-style JERSEY in BLACK & SILVER color-block with OLD-ENGLISH / blackletter lettering, layered over a black tee, baggy fit.
- Headwear: a slouchy CHARCOAL KNIT BEANIE with small gothic embroidery (NOT a snapback).
- Bottom: BAGGY wide pants.
- Accessories: a thin SILVER CHAIN necklace, a RED wristwatch.
- Shoes: chunky sneakers.
- Expression: cool and chic, pale makeup, slight smirk.
Style: 8-bit pixel sprite / dot art, hard pixel edges, NO anti-aliasing, NO gradients, flat shading.
       Keep her clearly the SAME Okja, urban goth-street mood.
Framing: FULL body centered (head to shoes all visible), big head near top, feet near bottom, tall vertical 4:9 portrait, even margins.
Background: FLAT SOLID chroma green (#00ff00), no scenery, no props, no shadow on background.
```

네거티브(공통 + 추가): `no witch hat, no witch dress (fully replaced), no snapback cap (it's a knit beanie), no gold chain (use silver), no different face, no cropped feet, no over-sexualized outfit (keep it cool & age-safe).`

### ③ 집사 (`okja_butler`)

> 레퍼 코디: 검정 **와이드브림 페도라** · 검정 **수트 재킷/롱코트** · 흰 셔츠 + **검정 넥타이** · **검정 장갑** · 얇은 **안경** · **십자가 펜던트 체인** · 한 손 턱에 괸 시크 포즈. 다크 고딕·음울한 기품.

```
[Attach TWO images — 1: okja_idle.png (identity lock), 2: a butler / tuxedo outfit reference photo]
Keep image 1's character IDENTITY: same face, same chic tsundere look, same SD chibi proportions (1:3~1:4).
RESTYLE her as a DARK GOTHIC BUTLER coordinate (image 2):
- Hair: free choice but NEAT and tidy, dark.
- Pose: a chic brooding stance — one BLACK-gloved hand resting on the chin, the other tucked, composed and aloof.
- Headwear: a black WIDE-BRIM FEDORA hat.
- Outfit: a black tailored SUIT JACKET / long coat over a white dress shirt with a black NECKTIE.
- Accessories: BLACK GLOVES on both hands, thin GLASSES, a silver CROSS PENDANT on a chain.
- Shoes: polished black formal shoes.
- Expression: calm, cool and dignified, faint aloof look (chic, moody).
Style: 8-bit pixel sprite / dot art, hard pixel edges, NO anti-aliasing, NO gradients, flat shading.
       Keep her clearly the SAME Okja, classy and prim, dark gothic mood.
Framing: FULL body centered (head to shoes all visible), big head near top, feet near bottom, tall vertical 4:9 portrait, even margins.
Background: FLAT SOLID chroma green (#00ff00), no scenery, no props, no shadow on background.
```

네거티브(공통 + 추가): `no witch hat (it's a fedora), no witch dress (fully replaced), no maid skirt, no tailcoat tails (it's a suit jacket), no white gloves (use black), no bow tie (use a necktie), no different face, no cropped feet.`

### ④ 크리스마스 (`okja_xmas`)

> 레퍼 코디: 빨강 **산타 드레스** + 흰 **퍼 트림** · 그 위에 **초록 후드 케이프/망토**(흰 퍼 + 금색 땡땡이·별 = 크리스마스 트리 모티프, 후드 착용) · 볼 빨강 **X·하트** 데코 · 빨강 부츠. ⚠️ **크로마키 = 마젠타 `#ff00ff`**(초록 케이프/배경 대비).

```
[Attach TWO images — 1: okja_idle.png (identity lock), 2: a cute Santa / Christmas dress reference photo]
Keep image 1's character IDENTITY: same face, same chic tsundere look, same SD chibi proportions (1:3~1:4).
RESTYLE her as a cozy CHRISTMAS / Santa coordinate (image 2):
- Hair: free choice, festive and cute, bangs.
- Pose: warm and inviting — both hands holding the hood by the cheeks, or one hand by the cheek; gentle festive cheer.
- Outfit: a RED SANTA DRESS trimmed with WHITE FUR (cuffs, hem, collar).
- Outerwear: a GREEN HOODED CAPE / cloak with WHITE FUR trim, decorated with GOLD polka-dots and little STAR ornaments (Christmas-tree motif), the HOOD worn up over her head.
- Headwear: the green hood up (instead of a santa hat).
- Accessories: small star ornaments; a tiny red X mark and a heart drawn cutely on one cheek.
- Shoes: short RED BOOTS with white fur.
- Expression: warm cute smile.
Style: 8-bit pixel sprite / dot art, hard pixel edges, NO anti-aliasing, NO gradients, flat shading.
       Keep her clearly the SAME Okja, cozy Christmas mood, age-safe.
Framing: FULL body centered (head to shoes all visible), big head near top, feet near bottom, tall vertical 4:9 portrait, even margins.
Background: FLAT SOLID chroma MAGENTA (#ff00ff), no scenery, no props, no shadow on background.
```

네거티브(공통 + 추가): `no witch hat, no witch dress (fully replaced), no chroma green anywhere (use MAGENTA bg — the cape is green), no different face, no cropped feet.`

> 💡 시온이 루돌프(`photo_sion_xmas`, 배경 포함 베이크)는 [시온이 파일](./gemini-prompts-sion.md) "시온이 체키 의상" 섹션 참조.

---

## 후처리 연결 (옥자 — 받은 PNG → 규격 에셋)

```bash
# 옥자 표정 6종 (128×288, 크로마 그린 배경 제거) — idle/smile/shy/sad/brew/talk
tools/.venv/bin/python tools/dotify.py okja_smile_raw.png \
  --preset okja --chroma 00ff00 --out assets/sprites/okja_smile.png
# (나머지 표정도 파일명만 바꿔 동일하게: okja_idle / okja_shy / okja_sad / okja_brew / okja_talk)

# 옥자 지뢰계 ★히어로 체키 (금발·갸루 포즈 — 체키 카드용 정적 아트)
tools/.venv/bin/python tools/dotify.py okja_jirai_raw.png \
  --preset okja --chroma 00ff00 --out assets/sprites/okja_jirai.png

# 옥자 의상 3종 (128×288, preset okja — 체키 카드용 정적 아트)
tools/.venv/bin/python tools/dotify.py okja_kinder_raw.png \
  --preset okja --chroma 00ff00 --out assets/sprites/okja_kinder.png
tools/.venv/bin/python tools/dotify.py okja_hiphop_raw.png \
  --preset okja --chroma 00ff00 --out assets/sprites/okja_hiphop.png
tools/.venv/bin/python tools/dotify.py okja_butler_raw.png \
  --preset okja --chroma 00ff00 --out assets/sprites/okja_butler.png
# 옥자 크리스마스 의상 (⚠️ 산타 드레스에 초록 홀리 → 크로마는 마젠타 ff00ff)
tools/.venv/bin/python tools/dotify.py okja_xmas_raw.png \
  --preset okja --chroma ff00ff --out assets/sprites/okja_xmas.png
```

> 검수·반복 루프는 [공통 파일](./gemini-prompts-common.md) 참조.
