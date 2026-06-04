class_name HeartCursor
extends Node2D
## 골드 하트 커서 — 포커스된 버튼을 가리키는 작은 도트 하트. (공용 버튼 테마 포커스 표시)
## 폰트 ♥ 글리프 호환을 못 믿어 직접 도트로 그린다(갈무리 비트맵엔 ♥가 없을 수 있음).
## 원점 = 하트 중심. 살짝 맥동(pulse)해 살아있는 느낌. (→ ADR 0001 팔레트·정수 좌표)

# 8×6 도트 하트 비트맵 (X=채움) — 중심 기준으로 그린다.
const BITMAP := [
  " XX  XX ",
  "XXXXXXXX",
  "XXXXXXXX",
  " XXXXXX ",
  "  XXXX  ",
  "   XX   ",
]
const CX := 4  # 비트맵 가로 중심 오프셋
const CY := 3  # 비트맵 세로 중심 오프셋


func _ready() -> void:
  _pulse()


func _draw() -> void:
  var col := Palette.GOLD
  for r in BITMAP.size():
    var line: String = BITMAP[r]
    for c in line.length():
      if line[c] == "X":
        draw_rect(Rect2(c - CX, r - CY, 1, 1), col)


## 가벼운 맥동(scale 1.0 ↔ 1.18 무한 루프).
func _pulse() -> void:
  var t := create_tween().set_loops()
  t.tween_property(self, "scale", Vector2(1.18, 1.18), 0.5) \
    .set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
  t.tween_property(self, "scale", Vector2.ONE, 0.5) \
    .set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
