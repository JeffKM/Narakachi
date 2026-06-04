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

import numpy as np
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


def clear_white(img, thr=210):
  """모든 불투명 근백색 픽셀을 투명화(배경 + 목걸이 고리 안쪽 + 얼굴 눈·이빨까지 전부 누끼).

  연결성을 따지지 않고 흰색이면 다 뺀다 — 셸 아트에 보존할 흰 디테일이 없기 때문.
  (도형 외곽의 흰 프린지는 리샘플 뒤 clean_edge_fringe가 추가로 정리)
  """
  a = np.array(img)
  rgb, al = a[:, :, :3], a[:, :, 3]
  mask = (al > 0) & (rgb[:, :, 0] > thr) & (rgb[:, :, 1] > thr) & (rgb[:, :, 2] > thr)
  a[mask] = (0, 0, 0, 0)
  return Image.fromarray(a, "RGBA")


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

  img = clear_white(img)                    # 흰색 전부 투명(배경·고리 안쪽·눈·이빨)
  # LCD 안쪽 투명화 (가운데 뚫린 프레임) — numpy로 처리
  ins = LCD_PUNCH_INSET
  a = np.array(img)
  a[ly0 + ins:ly1 - ins, lx0 + ins:lx1 - ins, 3] = 0
  img = Image.fromarray(a, "RGBA").resize((tw, th), Image.LANCZOS)
  img = clear_white(img)                    # LANCZOS 링잉이 만든 흰 헤일로까지 한 번 더 제거

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
