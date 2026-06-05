class_name ContactShadow
extends Node2D
## 접지 그림자 — 캐릭터/오브젝트 발밑에 깔리는 납작한 반투명 타원. (Phase 3.5)
## 도트 스프라이트가 그려진 배경 위에서 "붕 뜨는" 느낌을 없애고 바닥에 앉은 듯 보이게 한다.
## 원점 = 그림자 중심(= 발밑 접지점). 스프라이트가 bob 으로 떠도 그림자는 고정이라 접지감이 산다.

var shadow_size := Vector2(40, 10)         # 타원 지름(가로, 세로)
var color := Color(0, 0, 0, 0.32)          # 반투명 잉크


func setup(at: Vector2, width: float, height: float = 0.0, alpha: float = 0.32) -> void:
  position = at
  shadow_size = Vector2(width, height if height > 0.0 else width * 0.26)
  color = Color(0, 0, 0, alpha)
  queue_redraw()


func _draw() -> void:
  var pts := PackedVector2Array()
  var segs := 18
  for i in range(segs):
    var a := TAU * float(i) / float(segs)
    pts.append(Vector2(cos(a) * shadow_size.x * 0.5, sin(a) * shadow_size.y * 0.5))
  draw_colored_polygon(pts, color)
