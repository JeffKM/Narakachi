# Gemini 도트 변환 프롬프트 가이드 (옥자 · 시온이)

> 워크플로우 B: **AI는 형태·색감만, 규격은 `tools/dotify.py`가 강제.** (→ [tools/README.md](../tools/README.md))
> ADR 0001 파이프라인 = **실물 사진 → AI 도트화**. 상상 생성이 아니라 **사진 변환(img2img)**이 기본이다 — 인물 고증·일관성을 위해.

## 핵심 원칙 (왜 이렇게 쓰나)

1. **사진 변환 우선** — 옥자/시온이는 실존 컨셉이므로 실물 사진을 첨부해 "이 사진을 픽셀아트로" 요청한다. 텍스트만으로 새로 생성하면 매번 얼굴이 달라진다.
2. **단색 배경(크로마키)으로 받는다** — Gemini는 투명 배경을 못 만든다. **캐릭터에 없는 선명한 단색**을 배경으로 깔게 하고, `dotify --chroma`로 투명 분리한다.
   - 기본: 크로마 그린 `#00ff00` · 초록 의상(크리스마스)이면 마젠타 `#ff00ff`
3. **정확한 px·색 수는 요구하지 않는다** — "270×480" "32색" 같은 건 Gemini가 못 지킨다. **구도·비율·무드만** 지정하고 나머지는 후처리에 맡긴다.
4. **표정 6종은 같은 포즈·프레이밍** — 표정 스왑이 자연스러우려면 몸·구도 고정, 얼굴만 변경(→ ADR 0001 리스크).

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
Background: FLAT SOLID chroma green (#00ff00), no scenery, no props, no shadow on background.
```

### 네거티브 (공통)

```
no text, no watermark, no signature, no multiple characters, no cropped limbs,
no background scenery, no gradient background, no soft anti-aliased edges,
no realistic photo finish, no 3D render.
```

### 표정 6종 — 베이스에 한 줄만 추가

같은 사진/포즈를 유지하고 **얼굴 표정만** 바꾼다. (표정별 사진이 있으면 각각 변환이 더 정확)

| 파일명 | 추가 문구 |
|---|---|
| `okja_idle`    | `Expression: calm, slight chic look, mouth closed.` |
| `okja_smile`   | `Expression: soft warm smile, eyes gently curved.` |
| `okja_shy`     | `Expression: shy, blushing cheeks, eyes averted.` |
| `okja_sad`     | `Expression: sulky / pouting, downturned mouth (never crying).` |
| `okja_brew`    | `Pose tweak: holding a drink, focused "brewing" expression.` |
| `okja_talk`    | `Expression: mouth slightly open, talking, one hand raised.` |

> ⚠️ `okja_brew`만 손동작이 들어가 포즈가 조금 달라진다. 나머지 5종은 몸 고정.

---

## 시온이 (펫)

```
Convert into retro pixel art, a chubby white cat with patches ("Sioni"), Okja's pet.
Small chibi sprite, front view, simple cute shape, sitting (idle).
Style: 8-bit pixel sprite, hard edges, NO anti-aliasing, limited palette.
Background: FLAT SOLID chroma green (#00ff00).
```

### 반응 변형

| 파일명 | 추가 문구 |
|---|---|
| `sioni_idle`  | `sitting calmly, tail curled.` |
| `sioni_treat` | `looking up happily at a treat, mouth open.` |
| `sioni_play`  | `playful pounce pose, paws up.` |
| `sioni_pet`   | `eyes closed, content, being petted.` |

---

## 후처리 연결 (받은 PNG → 규격 에셋)

```bash
# 옥자 (128×288, 크로마 그린 배경 제거)
tools/.venv/bin/python tools/dotify.py okja_smile_raw.png \
  --preset okja --chroma 00ff00 --out assets/sprites/okja_smile.png

# 시온이 (48×48)
tools/.venv/bin/python tools/dotify.py sioni_idle_raw.png \
  --preset sioni --chroma 00ff00 --out assets/sprites/sioni_idle.png
```

→ 검수 리포트가 ✅ 통과하면 사용, ⚠️ 면 pixilart에서 노이즈/외곽선 수동 정리.

## 반복 루프

1. **(나)** 위 프롬프트 제공 (필요 시 사진별로 미세 조정)
2. **(너)** Gemini에 사진+프롬프트 → 결과 PNG 전달
3. **(나)** `dotify`로 규격화 + 검수 → 통과/미달 판정
4. 미달이면 어디가 어긋났는지 짚고 **프롬프트 수정안** 제시 → 2번 반복
5. 통과 → pixilart 수동 정리 → 에셋 확정

> 팁: 표정 6종은 **첫 1장(idle)을 확정**한 뒤, 그 결과를 레퍼런스로 첨부하며 나머지를 뽑으면 일관성이 크게 오른다.
