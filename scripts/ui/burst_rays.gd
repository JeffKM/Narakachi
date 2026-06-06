class_name BurstRays
extends Node2D
## 골든 광선 버스트 (T18) — 체키 획득 순간 카드 뒤에서 퍼지는 방사형 햇살. (→ ADR 0001)
##
## 셰이더 없이 `_draw` 로 삼각형 광선 N개를 중심에서 그린다(도트·Nearest 친화, 팔레트 안 색만).
## `burst()` 로 팝 등장(스케일 오버슈트 + 페이드 인), 이후 _process 로 아주 천천히 회전해 살아있게.
## 부모가 카드 중심에 position 을 잡고 카드보다 **뒤(먼저 add)** 에 둔다.

const RAYS := 12          # 광선 수(짝수 — 균등 분포)
const INNER := 10.0       # 중심 빈 반경(카드에 가려지는 안쪽)
const OUTER := 150.0      # 광선 길이
const WIDTH_DEG := 9.0    # 광선 한 장의 각폭(도)
const SPIN_DPS := 8.0     # 초당 회전(도) — 거의 멈춘 듯 은은하게

var _color: Color = Palette.GOLD


func setup(color: Color = Palette.GOLD) -> void:
  _color = color


func _ready() -> void:
  scale = Vector2.ZERO
  modulate.a = 0.0


func _process(delta: float) -> void:
  rotation_degrees += SPIN_DPS * delta


## 팝 등장 — 스케일 0→오버슈트→1 + 부드러운 페이드 인 후 은은한 상시 밝기로.
func burst() -> void:
  var t := create_tween().set_parallel(true)
  t.tween_property(self, "scale", Vector2.ONE, 0.45) \
    .set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
  t.tween_property(self, "modulate:a", 0.55, 0.25)
  # 잠깐 밝게 번쩍였다가 은은하게 가라앉음(상시 잔광 — 카드 주목 유지)
  t.chain().tween_property(self, "modulate:a", 0.32, 0.5)


func _draw() -> void:
  var half := deg_to_rad(WIDTH_DEG) / 2.0
  for i in range(RAYS):
    var a := TAU * float(i) / float(RAYS)
    # 부채꼴 한 장(안쪽 좁고 바깥 넓은 삼각형 2장 = 사다리꼴)
    var p1 := Vector2(cos(a - half), sin(a - half)) * INNER
    var p2 := Vector2(cos(a + half), sin(a + half)) * INNER
    var p3 := Vector2(cos(a + half), sin(a + half)) * OUTER
    var p4 := Vector2(cos(a - half), sin(a - half)) * OUTER
    draw_colored_polygon([p1, p2, p3, p4], _color)
