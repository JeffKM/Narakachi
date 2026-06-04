#!/usr/bin/env python3
"""도트풍 셸 레퍼런스(damagochi_frame.png)를 게임 셸 텍스처로 가공한다.

흰 배경과 LCD 안쪽을 모두 투명화해 '가운데가 뚫린 프레임'으로 만들고,
콘텐츠 세로(480)가 LCD에 꽉 차도록 t = 480/LCD높이 로 리샘플한다.
게임 내부 화면은 LCD 구멍 크기(가로×480)에 그대로 맞춘다(크롭 없음).
LCD/버튼 좌표도 함께 출력해 scripts/systems/shell.gd 상수와 맞춘다.
(→ ADR 0001, 사용자 채택 레퍼런스)

사용:
  python tools/prep_shell.py        # 기본: 저장소 원본 → 게임 셸
  python tools/prep_shell.py --in <레퍼런스.png> --out <출력.png>
"""
import argparse
import os
from collections import deque

from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DEFAULT_SRC = os.path.join(ROOT, "assets", "sprites", "_src", "damagochi_frame.png")
DEFAULT_OUT = os.path.join(ROOT, "assets", "sprites", "shell_frame.png")

# 레퍼런스(원본) 기준 측정값 — 행/열 프로파일로 계측 (tools 분석 결과)
SRC_LCD = (418, 334, 1342, 1668)         # x0,y0,x1,y1
SRC_BTN_CX = {"select": 549, "ok": 879, "cancel": 1211}
SRC_BTN_Y = 2080
SRC_BTN_W = 180                           # 캡슐 폭(원본)
SRC_BTN_H = 116                           # 캡슐 높이(원본, 추정)

CONTENT_H = 480                           # 게임 콘텐츠 세로 (가로는 LCD 비율에 맞춤)
LCD_PUNCH_INSET = 10                       # LCD 투명화 inset(원본px) — 베젤 라인 보존


def flood_clear_white(img):
  """4모서리에서 시작해 연결된 흰 배경만 투명화(내부 흰 디테일 보존)."""
  px = img.load()
  w, h = img.size
  seen = bytearray(w * h)
  dq = deque()
  for c in [(0, 0), (w - 1, 0), (0, h - 1), (w - 1, h - 1)]:
    dq.append(c)
  def is_white(p):
    return p[0] > 235 and p[1] > 235 and p[2] > 235
  while dq:
    x, y = dq.popleft()
    if x < 0 or y < 0 or x >= w or y >= h:
      continue
    i = y * w + x
    if seen[i]:
      continue
    seen[i] = 1
    if not is_white(px[x, y]):
      continue
    px[x, y] = (0, 0, 0, 0)
    dq.extend([(x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)])
  return img


def main():
  ap = argparse.ArgumentParser(description="도트풍 셸 레퍼런스 가공기")
  ap.add_argument("--in", dest="src", default=DEFAULT_SRC, help="레퍼런스 PNG")
  ap.add_argument("--out", default=DEFAULT_OUT, help="출력 PNG (게임 셸)")
  args = ap.parse_args()

  img = Image.open(os.path.expanduser(args.src)).convert("RGBA")
  W, H = img.size
  lx0, ly0, lx1, ly1 = SRC_LCD
  lcd_h = ly1 - ly0

  # 콘텐츠 세로(480)가 LCD 세로에 꽉 차도록 스케일
  t = CONTENT_H / lcd_h
  tw, th = round(W * t), round(H * t)

  img = flood_clear_white(img)              # 셸 바깥 투명
  # LCD 안쪽 투명화 (가운데 뚫린 프레임)
  px = img.load()
  ins = LCD_PUNCH_INSET
  for y in range(ly0 + ins, ly1 - ins):
    for x in range(lx0 + ins, lx1 - ins):
      px[x, y] = (0, 0, 0, 0)
  img = img.resize((tw, th), Image.LANCZOS)

  os.makedirs(os.path.dirname(os.path.abspath(args.out)), exist_ok=True)
  img.save(args.out)

  # 캔버스 좌표 환산 (셸 좌상단 = 0,0)
  def s(v):
    return round(v * t)
  cl = (s(lx0), s(ly0), s(lx1), s(ly1))
  lcd_w, lcd_h2 = cl[2] - cl[0], cl[3] - cl[1]

  print(f"셸 저장: {args.out}  캔버스 {tw}×{th}  (t={t:.4f})")
  print("── shell.gd 상수 ──")
  print(f"CANVAS      = Vector2i({tw}, {th})")
  print(f"LCD_OFFSET  = Vector2({cl[0]}, {cl[1]})  # LCD 구멍 좌상단")
  print(f"LCD_SIZE    = Vector2({lcd_w}, {lcd_h2})  # 내부 화면 = LCD 구멍에 꽉")
  print(f"BTN_Y       = {s(SRC_BTN_Y)}")
  print(f"BTN_W, BTN_H= {s(SRC_BTN_W)}, {s(SRC_BTN_H)}")
  print("BTN_COLS    = {")
  for k, cx in SRC_BTN_CX.items():
    print(f'  &"{k}": {s(cx)},')
  print("}")


if __name__ == "__main__":
  main()
