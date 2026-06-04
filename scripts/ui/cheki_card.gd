class_name ChekiCard
extends Control
## 체키 카드 렌더러 (T17) — 런타임 레이어 합성 양면 카드. (→ ADR 0003)
##
## 구운 1장 PNG 가 아니라 매번 레이어로 조립한다(닉네임·날짜가 플레이어별 동적).
##   - 앞면(표지)  = 파치먼트 배경 + 등급 엠블럼(날개/나비) + 나라카 워드마크 + 닉네임·날짜(갈무리)
##   - 뒷면(사진)  = [배경 풍경] + [의상 누끼 상반신 크롭] + [사진 프레임 테두리] + 데이 라벨
## 등급(일반/나비)은 표지 엠블럼 + 뒷면 프레임을 동시에 스왑한다(나비 = 나비 엠블럼 + 테마 프레임).
##
## 뒤집기 = 가짜 3D 가로 플립(scale_x 1→0→1 + 중간 텍스처 스왑). 셰이더 없음 → 도트·Nearest 유지.
## 피벗 = 카드 중심(플립이 중앙축 회전처럼 보이게). 부모는 원하는 위치·스케일로 배치.

const CARD := Vector2(120, 180)            # 도트 원본 카드 규격
const BORDER := 6                          # 폴라로이드 균일 테두리
var WINDOW := Vector2(CARD.x - BORDER * 2, CARD.y - BORDER * 2)  # 사진 창 ≈108×162

# 사진 면 의상 배치 — 전신이 서 있게(발치 여백 + 좌우 배경 노출). 창 높이 168 기준.
const COSTUME_FIT_H := 158.0   # 의상 표시 높이(전신, 발치 아래 여백 남김) — 클수록 의상↑·세로 배경↓
const COSTUME_GROUND := 3.0    # 발치~창 바닥 사이 여백

# 표지 공용 레이어(이벤트·캐릭터 무관) — ADR 0003 신규 공용 4점
const COVER_BG := "res://assets/sprites/frame_cover_bg.png"
const WORDMARK := "res://assets/sprites/wordmark_naraka.png"
const EMBLEM_WING := "res://assets/sprites/emblem_wing.png"        # 일반(비대칭 쌍날개)
const EMBLEM_BUTTERFLY := "res://assets/sprites/emblem_butterfly.png"  # 나비(대칭 변태)

signal flipped(showing_back: bool)

var _front: Control      # 표지 면
var _back: Control       # 사진 면
var _emblem: TextureRect
var _nick_label: Label
var _date_label: Label
var _frame: TextureRect
var _bg: TextureRect
var _costume: TextureRect
var _day_label: Label

var _showing_back := false
var _flip_tw: Tween


func _ready() -> void:
  custom_minimum_size = CARD
  size = CARD
  pivot_offset = CARD / 2.0   # 중앙축 플립
  _build_back()               # 뒤(사진) 먼저 → 앞(표지)이 위에 깔리게
  _build_front()
  _show_face(false)


## 카드 내용 채우기. record/grant 결과(또는 Cheki.record)로 호출.
##   character·event = 칸 식별, butterfly = 등급, nickname·acquired_at = 표지 헌사.
func setup(character: String, event: String, butterfly: bool, nickname: String, acquired_at: int) -> void:
  # ── 표지(앞) ──
  _emblem.texture = _tex(EMBLEM_BUTTERFLY if butterfly else EMBLEM_WING)
  _center_x(_emblem, _emblem.texture)
  _nick_label.text = _resolve_nick(nickname)
  _date_label.text = _format_date(acquired_at)

  # ── 사진(뒤) ── 3겹 합성: 배경 + 의상 누끼 + 프레임
  _bg.texture = _tex(Events.cheki_bg_path(event))
  _costume.texture = _tex(Events.cheki_costume_path(character, event))
  _frame.texture = _tex(Events.cheki_frame_path(event, butterfly))
  _day_label.text = Events.cheki_day_label(event)


## 즉시 한 면으로(애니메이션 없이). back=true 면 사진 면.
func show_face(back: bool) -> void:
  _show_face(back)


## 뒤집기 — 가짜 3D 가로 플립. 중간(scale_x≈0)에서 면 스왑.
func flip() -> void:
  if _flip_tw and _flip_tw.is_valid():
    return  # 플립 중 중복 입력 무시
  _flip_tw = create_tween()
  _flip_tw.tween_property(self, "scale:x", 0.0, 0.12).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
  _flip_tw.tween_callback(func() -> void: _show_face(not _showing_back))
  _flip_tw.tween_property(self, "scale:x", 1.0, 0.12).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


func is_showing_back() -> bool:
  return _showing_back


# ── 구성 ─────────────────────────────────────────────────

func _build_back() -> void:
  _back = Control.new()
  _back.size = CARD
  _back.mouse_filter = Control.MOUSE_FILTER_IGNORE
  add_child(_back)

  # 사진 창(클립) — 배경 + 의상 누끼가 테두리 밖으로 새지 않게
  var window := Control.new()
  window.position = Vector2(BORDER, BORDER)
  window.size = WINDOW
  window.clip_contents = true
  window.mouse_filter = Control.MOUSE_FILTER_IGNORE
  _back.add_child(window)

  # 1) 배경 풍경(불투명) — 풍경 '전체'를 창에 꽉 펴서 깐다(가장자리 크롭 0, 100% 노출).
  #    bg(120×180)↔창(108×168) 비율차가 ~3%라 STRETCH_SCALE 로 펴도 왜곡은 거의 안 보인다.
  #    의상 누끼(투명 배경) 뒤에 깔리므로 배경과 의상이 동시에 다 보인다(3겹 합성 → ADR 0003).
  _bg = TextureRect.new()
  _bg.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
  _bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
  _bg.stretch_mode = TextureRect.STRETCH_SCALE
  _bg.size = WINDOW
  _bg.position = Vector2.ZERO
  _bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
  window.add_child(_bg)

  # 2) 의상 누끼(128×288) — 전신이 창 안에 서 있게 축소(발치 아래 여백 + 좌우로 배경 노출).
  #    네이티브로 띄우면 너무 커서 전신·배경이 다 잘린다 → 창 높이에 맞춰 다운스케일.
  _costume = TextureRect.new()
  _costume.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
  _costume.size = Okja.SPR_SIZE  # 128×288 원본
  var s := COSTUME_FIT_H / Okja.SPR_SIZE.y       # 전신 표시 높이 / 원본 높이
  _costume.scale = Vector2(s, s)
  var disp_w := Okja.SPR_SIZE.x * s
  _costume.position = Vector2((WINDOW.x - disp_w) / 2.0, WINDOW.y - COSTUME_FIT_H - COSTUME_GROUND)
  _costume.mouse_filter = Control.MOUSE_FILTER_IGNORE
  window.add_child(_costume)

  # 3) 사진 프레임 테두리(투명 창 오버레이) — 카드 전체 위
  _frame = TextureRect.new()
  _frame.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
  _frame.size = CARD
  _frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
  _back.add_child(_frame)

  # 데이 라벨 — 사진 창 윗쪽 오버레이(손글씨 자리)
  _day_label = _make_label(Fonts.SIZE_SMALL, Palette.CREAM, HORIZONTAL_ALIGNMENT_CENTER)
  _day_label.position = Vector2(BORDER, BORDER + 4)
  _day_label.size = Vector2(WINDOW.x, 14)
  _back.add_child(_day_label)


func _build_front() -> void:
  _front = Control.new()
  _front.size = CARD
  _front.mouse_filter = Control.MOUSE_FILTER_IGNORE
  add_child(_front)

  # 파치먼트 표지 배경(불투명)
  var cover := TextureRect.new()
  cover.texture = _tex(COVER_BG)
  cover.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
  cover.size = CARD
  cover.mouse_filter = Control.MOUSE_FILTER_IGNORE
  _front.add_child(cover)

  # 나라카 붓글씨 워드마크(상단 중앙)
  var wm := TextureRect.new()
  wm.texture = _tex(WORDMARK)
  wm.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
  _center_x(wm, wm.texture)
  wm.position.y = 14
  wm.mouse_filter = Control.MOUSE_FILTER_IGNORE
  _front.add_child(wm)

  # 등급 엠블럼(중앙) — setup 에서 텍스처/정렬 갱신
  _emblem = TextureRect.new()
  _emblem.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
  _emblem.position.y = 56
  _emblem.mouse_filter = Control.MOUSE_FILTER_IGNORE
  _front.add_child(_emblem)

  # 닉네임 헌사 + 날짜 (엠블럼 바로 아래 묶음 — 바닥에 붙지 않게 위로)
  _nick_label = _make_label(Fonts.SIZE_BODY, Palette.BURGUNDY, HORIZONTAL_ALIGNMENT_CENTER)
  _nick_label.position = Vector2(8, 124)
  _nick_label.size = Vector2(CARD.x - 16, 16)
  _front.add_child(_nick_label)

  _date_label = _make_label(Fonts.SIZE_SMALL, Palette.GOLD_DARK, HORIZONTAL_ALIGNMENT_CENTER)
  _date_label.position = Vector2(8, 144)
  _date_label.size = Vector2(CARD.x - 16, 14)
  _front.add_child(_date_label)


# ── 헬퍼 ─────────────────────────────────────────────────

func _show_face(back: bool) -> void:
  _showing_back = back
  _front.visible = not back
  _back.visible = back
  flipped.emit(back)


## 텍스처를 가로 중앙에 배치(엠블럼·워드마크처럼 폭이 제각각인 누끼용).
func _center_x(rect: TextureRect, tex: Texture2D) -> void:
  var w := tex.get_width() if tex else 0
  rect.position.x = (CARD.x - w) / 2.0
  if tex:
    rect.size = tex.get_size()


func _make_label(font_size: int, color: Color, align: int) -> Label:
  var lb := Label.new()
  lb.add_theme_font_size_override("font_size", font_size)
  lb.add_theme_color_override("font_color", color)
  lb.add_theme_color_override("font_outline_color", Palette.INK)
  lb.add_theme_constant_override("outline_size", 3)
  lb.horizontal_alignment = align
  lb.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
  lb.mouse_filter = Control.MOUSE_FILTER_IGNORE
  return lb


## 표지에 박을 닉네임 결정. 스냅샷 우선 → 비었으면 현재 플레이어 닉 → 그래도 없으면 "손님".
## (구버전 세이브·온보딩 수동 기록처럼 스냅샷이 비어 있어도 내 이름이 뜨게 한다.)
func _resolve_nick(snapshot: String) -> String:
  var nick := snapshot.strip_edges()
  if nick.is_empty():
    nick = String(SaveManager.get_value("player.nickname", "")).strip_edges()
  return nick if not nick.is_empty() else "손님"


## epoch(초) → "YYYY.MM.DD". 0 이면 오늘 날짜로 폴백.
func _format_date(unix: int) -> String:
  var d: Dictionary
  if unix > 0:
    d = Time.get_datetime_dict_from_unix_time(unix)
  else:
    d = Time.get_datetime_dict_from_system()
  return "%04d.%02d.%02d" % [d["year"], d["month"], d["day"]]


## 경로 → 텍스처(없으면 null — TextureRect 는 빈 채로, 크래시 없음).
func _tex(path: String) -> Texture2D:
  if ResourceLoader.exists(path):
    return load(path) as Texture2D
  push_warning("[ChekiCard] 텍스처 없음: %s (에디터에서 임포트 필요)" % path)
  return null
