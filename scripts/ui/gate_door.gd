class_name GateDoor
extends Node2D
## 지옥문 한쪽 문짝 — 경첩 기준으로 접히며 열리되, 슬랩 옆면(두께)이 드러나 "문" 두께감을 준다.
## (단순 scale.x 폴드는 옆면이 없어 종이처럼 보임 → 앞면 + 옆면 두 면을 직접 그린다.)
##
## 직교 폴드 근사: 열림각 θ = open·90°.
##   - 앞면 폭 = face_w·cos θ  (텍스처 region 을 가로로 압축 = 포어쇼트닝)
##   - 옆면(두께) 폭 = thickness·sin θ  (열릴수록 어두운 슬랩 옆면이 드러남)
## is_left=true 면 경첩이 왼쪽(로컬 x=0)·앞면을 +x 로, false 면 경첩이 오른쪽·앞면을 -x 로 그린다.

const H := 480

var tex: Texture2D     # 지옥문 전체 텍스처(333×480) — region 으로 반쪽만 그린다
var region: Rect2      # 이 문짝이 쓸 atlas 영역(픽셀)
var face_w := 0.0      # 앞면 원폭
var thickness := 10.0  # 슬랩 두께(옆면 최대 폭)
var is_left := true

var open := 0.0: set = _set_open  # 0=닫힘 … 1=활짝


func _ready() -> void:
  texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST


func _set_open(v: float) -> void:
  open = clampf(v, 0.0, 1.0)
  queue_redraw()


func _draw() -> void:
  var th := open * (PI / 2.0)
  var cw := face_w * cos(th)       # 앞면 투영 폭
  var sw := thickness * sin(th)    # 옆면(두께) 폭

  # 1) 앞면 — region 을 폭 cw 로 압축해 그린다(가로 포어쇼트닝).
  if cw >= 1.0:
    var face_x := 0.0 if is_left else -cw
    draw_texture_rect_region(tex, Rect2(face_x, 0, cw, H), region)

  # 2) 옆면(두께) — 앞면 자유단에서 바깥으로 sw 만큼. 어두운 앞면과 대비되게 빛 받는 우드 톤.
  if sw >= 1.0:
    var edge_x := cw if is_left else -cw - sw
    draw_rect(Rect2(edge_x, 0, sw, H), Palette.WOOD_LIGHT)  # 슬랩 옆면(빛 받음)
    # 바깥 끝 1px 잉크 외곽선 — 슬랩 윤곽을 또렷하게.
    var outer_x := edge_x + sw - 1.0 if is_left else edge_x
    draw_rect(Rect2(outer_x, 0, 1.0, H), Palette.INK)
    # 앞면↔옆면 경계 골드 라인 — 모서리 하이라이트.
    var seam_x := cw - 1.0 if is_left else -cw
    draw_rect(Rect2(seam_x, 0, 1.0, H), Palette.GOLD)
