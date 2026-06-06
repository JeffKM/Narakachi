class_name QrPlaceholder
extends Node2D
## QR 자리 (T19) — 공유 이미지에 박는 "QR 느낌" 플레이스홀더. (→ PRD §5.4 / ROADMAP T24)
##
## 실제 QR(배포 링크)은 웹 호스팅이 정해지는 T24에서 생성한다. 지금은 자리를 잡아 두기 위해
## 셰이더 없이 `_draw` 로 파인더 패턴 + 고정 더미 모듈을 그려 "여기에 QR이 온다"를 보여준다.
## 모듈 크기를 정수 픽셀로 맞춰 도트 룩을 깨지 않는다.

const MODULES := 11       # 한 변 모듈 수(컴팩트 — 실제 QR보다 단순)

var _px := 3.0            # 모듈 한 칸 픽셀(정수 권장)


## 한 변 픽셀 크기로 모듈 픽셀을 정한다(정수로 내림 → 도트 정렬).
func setup(size_px := 33.0) -> void:
  _px = max(1.0, floor(size_px / float(MODULES)))


func side_px() -> float:
  return _px * MODULES


func _draw() -> void:
  var s := side_px()
  draw_rect(Rect2(0, 0, s, s), Palette.WHITE)  # 흰 바탕(콰이어트 존 포함)
  var pat := _pattern()
  for y in MODULES:
    for x in MODULES:
      if pat[y][x] == 1:
        draw_rect(Rect2(x * _px, y * _px, _px, _px), Palette.INK)


## 고정 패턴 — 코너 파인더 3개(3×3 블록) + 흩뿌린 더미 데이터 모듈. 매번 같은 모양.
func _pattern() -> Array:
  var g: Array = []
  for y in MODULES:
    var row: Array = []
    for x in MODULES:
      row.append(0)
    g.append(row)
  # 코너 파인더(좌상·우상·좌하) 3×3 블록
  for c in [[0, 0], [0, MODULES - 3], [MODULES - 3, 0]]:
    for yy in 3:
      for xx in 3:
        g[c[0] + yy][c[1] + xx] = 1
  # 더미 데이터 모듈(고정 좌표 — 패턴이 흔들리지 않게)
  for d in [[5, 1], [6, 2], [4, 4], [5, 5], [6, 6], [7, 5], [8, 7], [3, 7],
            [2, 5], [7, 3], [9, 9], [5, 8], [8, 9], [1, 8], [9, 5], [4, 9]]:
    g[d[0]][d[1]] = 1
  return g
