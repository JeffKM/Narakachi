#!/usr/bin/env python3
"""나라카찌 게임기 셸 절차적 생성기 — LCD·버튼 위치를 코드로 100% 정확하게.

다마고치형 달걀 바디 + LCD 투명칸(270×480 @ 95,30) + 3버튼(SELECT/OK/CANCEL)
+ 목걸이 고리. 색은 마스터 팔레트(버건디 기조)만 사용 (→ ADR 0001, 옵션 D).
AI와 씨름 없이 규격 정확한 셸을 산출한다. 디테일·질감은 이후 pixilart에서 보강.

사용:
  python tools/gen_shell.py --out assets/sprites/shell.png
"""
import argparse
import os
import re

from PIL import Image, ImageDraw, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PALETTE_GD = os.path.join(ROOT, "data", "palette.gd")
FONT = os.path.join(ROOT, "assets", "fonts", "Galmuri11.ttf")

# 규격 (→ ADR 0001)
W, H = 460, 630
LCD = (95, 30, 270, 480)  # x, y, w, h — 게임 화면 구멍
DECK_Y = 510              # 하단 버튼 덱 시작 y


def load_palette():
  """palette.gd → {이름: (r,g,b)} 딕셔너리."""
  src = open(PALETTE_GD).read()
  pairs = re.findall(r'const\s+([A-Z0-9_]+)\s*:=\s*Color\("([0-9a-fA-F]{6})"\)', src)
  pal = {}
  for name, h in pairs:
    pal[name] = tuple(int(h[i:i + 2], 16) for i in (0, 2, 4))
  return pal


def egg_bbox(inset):
  """달걀 바디 bbox — 위가 살짝 좁은 느낌을 위해 inset만큼 줄인 박스."""
  return (inset, inset + 6, W - inset, H - inset)


def draw_shell(pal):
  img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
  d = ImageDraw.Draw(img)

  INK = pal["INK"]
  # ── 1) 달걀 바디: 외곽선 → 메인 → 명암 ──────────────────
  d.ellipse(egg_bbox(8), fill=INK)                      # 외곽 라인(검정)
  d.ellipse(egg_bbox(14), fill=pal["BURGUNDY"])         # 바디 메인(버건디)
  # 좌상단 하이라이트
  d.ellipse((40, 60, 250, 360), fill=pal["BLOOD"])
  d.ellipse((60, 80, 210, 300), fill=pal["ROSE"])
  # 우하단 그림자 (메인색으로 덮어 입체)
  d.ellipse((150, 220, W - 18, H - 22), fill=pal["BURGUNDY"])
  d.ellipse((230, 360, W - 22, H - 30), fill=pal["BURGUNDY_DARK"])
  # 바디 메인을 다시 중앙에 얹어 하이라이트/그림자를 부드럽게 감쌈
  d.ellipse((70, 110, 390, 540), fill=pal["BURGUNDY"])

  # ── 2) LCD 베젤(검은 액자) + 골드 라인 ────────────────
  x, y, lw, lh = LCD
  pad = 12
  d.rounded_rectangle((x - pad, y - pad, x + lw + pad, y + lh + pad),
                      radius=14, fill=pal["GOLD_DARK"])     # 골드 테두리
  d.rounded_rectangle((x - pad + 3, y - pad + 3, x + lw + pad - 3, y + lh + pad - 3),
                      radius=12, fill=INK)                   # 검은 액자
  d.rectangle((x, y, x + lw, y + lh), fill=pal["CHARCOAL"])  # LCD 바닥(나중에 투명)

  # ── 3) 좌우 불꽃 장식 (촛불/지옥) ──────────────────────
  for fx in (44, W - 44):
    flame(d, fx, 300, pal)
    flame(d, fx, 380, pal)

  # ── 4) N 브랜드 (LCD 아래) ────────────────────────────
  f_n = ImageFont.truetype(FONT, 34)
  d.text((W // 2, DECK_Y - 14), "N", font=f_n, fill=pal["CANDLE"], anchor="mm")

  # ── 5) 하단 3버튼 + 라벨 ──────────────────────────────
  f_lbl = ImageFont.truetype(FONT, 13)
  btn_y = 560
  bw, bh = 78, 38
  cols = {"SELECT": 118, "OK": 230, "CANCEL": 342}
  for label, cx in cols.items():
    # 라벨
    d.text((cx, btn_y - bh // 2 - 12), label, font=f_lbl, fill=pal["CANDLE"], anchor="mm")
    # 버튼 캡슐
    d.rounded_rectangle((cx - bw // 2, btn_y - bh // 2, cx + bw // 2, btn_y + bh // 2),
                        radius=bh // 2, fill=INK)
    d.rounded_rectangle((cx - bw // 2 + 3, btn_y - bh // 2 + 3, cx + bw // 2 - 3, btn_y + bh // 2 - 3),
                        radius=bh // 2 - 3, fill=pal["WOOD"])
    d.ellipse((cx - bw // 2 + 8, btn_y - bh // 2 + 6, cx, btn_y), fill=pal["WOOD_LIGHT"])  # 하이라이트

  # ── 6) 목걸이 고리 (상단 중앙) ────────────────────────
  d.ellipse((W // 2 - 16, 2, W // 2 + 16, 30), outline=pal["GOLD"], width=5)
  d.ellipse((W // 2 - 16, 2, W // 2 + 16, 30), outline=INK, width=1)

  # ── 7) LCD칸 투명 뚫기 (게임 화면 자리) ───────────────
  hole = Image.new("RGBA", (lw, lh), (0, 0, 0, 0))
  img.paste(hole, (x, y))

  return img


def flame(d, cx, cy, pal):
  """작은 불꽃: 외염(blood) + 내염(candle)."""
  d.polygon([(cx, cy - 14), (cx - 7, cy + 6), (cx, cy + 2), (cx + 7, cy + 6)], fill=pal["BLOOD"])
  d.polygon([(cx, cy - 6), (cx - 3, cy + 5), (cx + 3, cy + 5)], fill=pal["CANDLE"])


def main():
  ap = argparse.ArgumentParser(description="나라카찌 게임기 셸 생성기")
  ap.add_argument("--out", required=True, help="출력 PNG 경로")
  ap.add_argument("--preview", type=int, default=2, help="×N nearest 확대 미리보기 (0=off)")
  args = ap.parse_args()

  pal = load_palette()
  img = draw_shell(pal)
  os.makedirs(os.path.dirname(os.path.abspath(args.out)), exist_ok=True)
  img.save(args.out)
  print(f"셸 생성: {args.out}  ({W}×{H}, LCD {LCD})")

  if args.preview > 0:
    pv = os.path.splitext(args.out)[0] + f"_x{args.preview}.png"
    img.resize((W * args.preview, H * args.preview), Image.NEAREST).save(pv)
    print(f"미리보기: {pv}")


if __name__ == "__main__":
  main()
