extends Node2D
## 나라카찌 부트스트랩 — 게임기 셸 + 3버튼 입력 연결 데모. (→ ADR 0001)
## 셸(ShellFrame) LCD 안에 옥자 4버튼 컨셉 메뉴를 올리고,
##   SELECT(커서 순환) · OK(선택) · CANCEL(처음으로) 가 실제로 동작하는지 보인다.
## 실제 교감 화면(온보딩 → 교감 → 컬렉션북 → 공유)은 ROADMAP T06~ 에서 구현.
## 팔레트: data/palette.gd · 폰트: scripts/systems/fonts.gd · 셸: scripts/systems/shell.gd

# 내부 화면 = 셸 LCD 구멍 크기 (ShellFrame.LCD_SIZE 와 일치)
const LCD_W := 333
const LCD_H := 480

# 옥자 메인 4버튼 컨셉 (CLAUDE.md 핵심 흐름)
var _items: Array[String]
var _cursor := 0

var _item_labels: Array[Label] = []
var _toast: Label
var _dbg: Label


func _ready() -> void:
  # 갈무리 폰트가 있으면 전역 기본 테마로 적용 (없으면 엔진 기본 폰트)
  get_window().theme = Fonts.make_theme()
  # 셸 바깥 여백은 투명 — 웹/창 배경이 비치게 (per_pixel_transparency 허용됨)
  get_window().transparent_bg = true

  var kr := Fonts.has_galmuri()
  if kr:
    _items = ["체키 주문", "음료 주문", "대화", "선물"]
  else:
    _items = ["Cheki", "Drink", "Talk", "Gift"]

  # 셸을 띄우고 LCD 안에 메뉴 콘텐츠를 붙인다
  var shell := ShellFrame.new()
  add_child(shell)
  shell.button_pressed.connect(_on_shell_button)
  _build_lcd(shell.lcd_root, kr)
  _refresh()


## LCD(270×480) 안에 데모 메뉴 UI를 만든다.
func _build_lcd(root: Node2D, kr: bool) -> void:
  # 화면 바닥 (나라카 실내 — 임시 단색)
  var bg := ColorRect.new()
  bg.color = Palette.INK
  bg.size = Vector2(LCD_W, LCD_H)
  bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
  root.add_child(bg)

  # 타이틀
  root.add_child(_make_label(
    "NARAKACHI", 18, Fonts.SIZE_TITLE, Palette.GOLD))
  root.add_child(_make_label(
    ("데일리 교감 데모" if kr else "daily bonding demo"),
    48, Fonts.SIZE_SMALL, Palette.GREY_300))

  # 옥자 자리 (스탠딩 에셋 A1 들어갈 곳 — 임시 표기)
  root.add_child(_make_label(
    ("[ 옥자 자리 ]" if kr else "[ OKJA ]"),
    96, Fonts.SIZE_BODY, Palette.BURGUNDY))

  # 4버튼 메뉴 (세로 리스트, 커서로 순환)
  var start_y := 156
  var gap := 42
  for i in _items.size():
    var lb := _make_label("", start_y + i * gap, Fonts.SIZE_BODY, Palette.WHITE)
    root.add_child(lb)
    _item_labels.append(lb)

  # 선택/취소 토스트
  _toast = _make_label("", 348, Fonts.SIZE_BODY, Palette.CANDLE)
  root.add_child(_toast)

  # 조작 힌트
  root.add_child(_make_label(
    ("SELECT 이동 · OK 선택 · CANCEL 처음으로" if kr
      else "SELECT move / OK pick / CANCEL home"),
    424, Fonts.SIZE_SMALL, Palette.GREY_400))

  # 마지막 입력 디버그
  _dbg = _make_label(
    ("마지막 입력: -" if kr else "last input: -"),
    452, Fonts.SIZE_SMALL, Palette.GREY_300)
  root.add_child(_dbg)


## 가로 중앙 정렬 라벨 헬퍼 (LCD 로컬 좌표).
func _make_label(text: String, y: int, size: int, color: Color) -> Label:
  var lb := Label.new()
  lb.text = text
  lb.position = Vector2(0, y)
  lb.size = Vector2(LCD_W, size + 6)
  lb.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
  lb.add_theme_font_size_override("font_size", size)
  lb.add_theme_color_override("font_color", color)
  return lb


## 셸 버튼 입력 처리
func _on_shell_button(action: StringName) -> void:
  match action:
    &"select":
      _cursor = (_cursor + 1) % _items.size()
    &"ok":
      _flash_toast("▶ %s" % _items[_cursor])
    &"cancel":
      _cursor = 0
      _flash_toast("× 처음으로")
  _dbg.text = "마지막 입력: %s" % String(action).to_upper()
  _refresh()


## 커서 위치를 메뉴 라벨에 반영
func _refresh() -> void:
  for i in _item_labels.size():
    var selected := i == _cursor
    _item_labels[i].text = ("▶ %s" if selected else "%s") % _items[i]
    _item_labels[i].add_theme_color_override(
      "font_color", Palette.CANDLE if selected else Palette.GREY_300)


## 토스트 메시지 (1.2초 페이드아웃)
func _flash_toast(msg: String) -> void:
  _toast.text = msg
  _toast.modulate.a = 1.0
  var t := create_tween()
  t.tween_interval(0.9)
  t.tween_property(_toast, "modulate:a", 0.0, 0.3)
