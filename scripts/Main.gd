extends Node2D
## 나라카찌 부트스트랩 — 270×480 화면이 뜨는지 확인하는 플레이스홀더.
## 실제 화면(온보딩 → 교감 → 컬렉션북 → 공유)은 ROADMAP T06~ 에서 구현.
## 도트 규격: docs/adr/0001-dot-art-spec.md

const VIEW_W := 270
const VIEW_H := 480

# 마스터 팔레트 앵커 (→ ADR 0001). 본격 구현 시 data/ 로 이동.
const COL_BG := Color("0d0b12")      # 먹빛 블랙
const COL_GOLD := Color("caa75a")    # 앤틱 골드
const COL_BURGUNDY := Color("7a1f3d") # 버건디


func _ready() -> void:
  _build_placeholder()


func _build_placeholder() -> void:
  # 배경 (나라카 다크 앤틱)
  var bg := ColorRect.new()
  bg.color = COL_BG
  bg.size = Vector2(VIEW_W, VIEW_H)
  add_child(bg)

  # 타이틀 (갈무리 폰트 임포트 전이라 영문 플레이스홀더)
  var title := Label.new()
  title.text = "NARAKATCHI"
  title.position = Vector2(0, 200)
  title.size = Vector2(VIEW_W, 24)
  title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
  title.add_theme_color_override("font_color", COL_GOLD)
  add_child(title)

  var sub := Label.new()
  sub.text = "boot ok  -  270x480"
  sub.position = Vector2(0, 228)
  sub.size = Vector2(VIEW_W, 16)
  sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
  add_child(sub)

  var todo := Label.new()
  todo.text = "next: Galmuri font (T03)"
  todo.position = Vector2(0, 252)
  todo.size = Vector2(VIEW_W, 16)
  todo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
  todo.add_theme_color_override("font_color", COL_BURGUNDY)
  add_child(todo)
