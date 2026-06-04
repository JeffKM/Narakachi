class_name UiTheme
extends RefCounted
## 공용 인게임 버튼 스타일 (지옥풍 다크 앤티크) — 온보딩·액션바·스플래시·팝업이 한 톤을 공유한다.
## 색은 Palette 상수만, 라운드/테두리만 줘서 도트 톤(Nearest·정수)을 깨지 않는다. (→ ADR 0001)
## 포커스(커서) 표시는 골드 하트(scripts/ui/heart_cursor.gd)로 별도. 여기선 바탕 강조만 담당.

## 버튼 배경 스타일박스. focused=true 면 살짝 밝은 버건디 + 골드 테두리(강조).
static func button_box(focused: bool) -> StyleBoxFlat:
  var sb := StyleBoxFlat.new()
  sb.bg_color = Palette.BURGUNDY if focused else Palette.BURGUNDY_DARK
  sb.set_corner_radius_all(6)
  sb.set_border_width_all(2 if focused else 1)
  sb.border_color = Palette.GOLD if focused else Palette.GOLD_DARK
  return sb


## 버튼에 공용 지옥풍 테마를 입힌다(글자색·폰트·상태별 스타일박스). 커서는 우리가 직접 그린다.
static func style_button(btn: Button) -> void:
  btn.focus_mode = Control.FOCUS_NONE
  btn.add_theme_font_size_override("font_size", Fonts.SIZE_BODY)
  btn.add_theme_color_override("font_color", Palette.CREAM)
  btn.add_theme_color_override("font_hover_color", Palette.WHITE)
  btn.add_theme_color_override("font_pressed_color", Palette.WHITE)
  btn.add_theme_stylebox_override("normal", button_box(false))
  btn.add_theme_stylebox_override("hover", button_box(false))
  btn.add_theme_stylebox_override("pressed", button_box(true))


## 포커스 상태 갱신 — 커서가 가리키는 버튼만 강조 바탕으로.
static func set_button_focused(btn: Button, focused: bool) -> void:
  btn.add_theme_stylebox_override("normal", button_box(focused))
  btn.add_theme_stylebox_override("hover", button_box(focused))


## 텍스트 입력칸 배경 스타일박스. focused=true 면 골드 테두리로 강조.
static func input_box(focused: bool) -> StyleBoxFlat:
  var sb := StyleBoxFlat.new()
  sb.bg_color = Palette.GREY_900
  sb.set_corner_radius_all(5)
  sb.set_border_width_all(2)
  sb.border_color = Palette.GOLD if focused else Palette.GOLD_DARK
  sb.content_margin_left = 8
  sb.content_margin_right = 8
  sb.content_margin_top = 4
  sb.content_margin_bottom = 4
  return sb


## LineEdit 에 공용 지옥풍 입력칸 테마(글자색·플레이스홀더·캐럿·상태별 스타일박스).
static func style_input(edit: LineEdit) -> void:
  edit.add_theme_font_size_override("font_size", Fonts.SIZE_BODY)
  edit.add_theme_color_override("font_color", Palette.CREAM)
  edit.add_theme_color_override("font_placeholder_color", Palette.GREY_400)
  edit.add_theme_color_override("caret_color", Palette.GOLD)
  edit.add_theme_color_override("selection_color", Palette.BURGUNDY)
  edit.add_theme_stylebox_override("normal", input_box(false))
  edit.add_theme_stylebox_override("focus", input_box(true))
