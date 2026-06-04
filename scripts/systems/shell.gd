class_name ShellFrame
extends Node2D
## 게임기 셸 — 달걀 바디 + LCD 구멍(270×480) + 3버튼(SELECT/OK/CANCEL). (→ ADR 0001)
## 베이스 캔버스(460×818) 안에서 셸을 세로 중앙 배치하고, 위아래 여백은 다크 버건디로 채운다.
## LCD 콘텐츠는 외부에서 `lcd_root`(270×480 로컬 좌표) 아래에 붙인다.
## 버튼은 키보드/터치 하이브리드로 받아 `button_pressed(action)` 신호로 통지한다.
##   action: &"select" · &"ok" · &"cancel"

signal button_pressed(action: StringName)

const SHELL_TEX := "res://assets/sprites/shell_frame.png"

# ── 레이아웃 규격 (tools/prep_shell.py 가 레퍼런스에서 계측·출력) ─────────────
# 도트풍 레퍼런스(damagochi_frame.png)를 t=480/LCD높이 로 리샘플 → 캔버스 633×875.
# 콘텐츠(270×480)는 LCD(가로 333) 중앙에 배치, 좌우는 셸 LCD색이 여백으로 노출. (→ ADR 0001)
const CANVAS := Vector2i(633, 875)    # 셸 텍스처 = 캔버스 (셸이 화면 꽉)
const SHELL_POS := Vector2(0, 0)      # 셸 좌상단
const LCD_OFFSET := Vector2(150, 120) # LCD 구멍 좌상단 — 내부 화면 원점
const LCD_SIZE := Vector2(333, 480)   # 내부 화면 = LCD 구멍에 꽉 (크롭 없음)

# 하단 3버튼 (캔버스 좌표 — prep_shell.py 계측)
const BTN_Y := 748
const BTN_W := 65
const BTN_H := 42
const BTN_COLS := {
  &"select": 198,
  &"ok": 316,
  &"cancel": 436,
}

# 물리 키 → 액션 매핑 (한 액션에 여러 키)
const KEYMAP := {
  KEY_TAB: &"select", KEY_RIGHT: &"select", KEY_DOWN: &"select",
  KEY_SPACE: &"ok", KEY_ENTER: &"ok", KEY_KP_ENTER: &"ok", KEY_Z: &"ok",
  KEY_ESCAPE: &"cancel", KEY_X: &"cancel", KEY_BACKSPACE: &"cancel",
}

## LCD 콘텐츠를 붙일 루트 (위치 = SHELL_POS + LCD_OFFSET). _ready 후 사용 가능.
var lcd_root: Node2D

var _flashes := {}  # action -> Panel (눌림 피드백)


func _ready() -> void:
  # ── 1) LCD 콘텐츠 루트 (셸보다 먼저 = 뒤에 깔림) ────
  # 셸 바깥 여백은 칠하지 않음 → 뷰포트 투명 배경으로 비침(Main 에서 설정).
  lcd_root = Node2D.new()
  lcd_root.position = SHELL_POS + LCD_OFFSET
  add_child(lcd_root)

  # ── 2) 셸 스프라이트 (콘텐츠 위에 얹혀 구멍/베젤로 보임) ─
  var spr := Sprite2D.new()
  spr.texture = load(SHELL_TEX)
  spr.centered = false
  spr.position = SHELL_POS
  add_child(spr)

  # ── 4) 3버튼 (투명 터치영역 + 눌림 하이라이트) ──────
  for action in BTN_COLS:
    _make_button(action, BTN_COLS[action])


## 셸 내부 버튼 좌표에 투명 Button + 눌림 Panel 을 만든다.
func _make_button(action: StringName, center_x: int) -> void:
  var rect := Rect2(
    SHELL_POS + Vector2(center_x - BTN_W / 2.0, BTN_Y - BTN_H / 2.0),
    Vector2(BTN_W, BTN_H))

  var btn := Button.new()
  btn.flat = true
  btn.focus_mode = Control.FOCUS_NONE
  btn.position = rect.position
  btn.size = rect.size
  btn.tooltip_text = String(action).to_upper()
  btn.pressed.connect(_trigger.bind(action))
  add_child(btn)

  # 눌림 피드백: 골드 캡슐 (평소 alpha 0)
  var p := Panel.new()
  p.position = rect.position
  p.size = rect.size
  p.mouse_filter = Control.MOUSE_FILTER_IGNORE
  var sb := StyleBoxFlat.new()
  sb.bg_color = Palette.GOLD
  sb.set_corner_radius_all(int(BTN_H / 2))
  p.add_theme_stylebox_override("panel", sb)
  p.modulate = Color(1, 1, 1, 0)
  add_child(p)
  _flashes[action] = p


## 키보드 입력 → 액션 (터치는 Button.pressed 가 직접 _trigger 호출)
func _unhandled_input(event: InputEvent) -> void:
  if event is InputEventKey and event.pressed and not event.echo:
    var action: StringName = KEYMAP.get(
      event.physical_keycode, KEYMAP.get(event.keycode, &""))
    if action != &"":
      _trigger(action)
      get_viewport().set_input_as_handled()


## 키/터치 공통 진입점: 피드백 + 신호 방출
func _trigger(action: StringName) -> void:
  _flash(action)
  button_pressed.emit(action)


## 버튼 눌림 깜빡임 (골드 캡슐 페이드아웃)
func _flash(action: StringName) -> void:
  var p: Panel = _flashes.get(action)
  if p == null:
    return
  p.modulate.a = 0.55
  create_tween().tween_property(p, "modulate:a", 0.0, 0.2)
