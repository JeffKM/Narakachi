class_name ShareCard
extends Control
## 공유 이미지 내보내기 (T19) — 체키 한 장을 워터마크 `@나라카` + QR 자리와 합성해 저장/공유. (→ PRD §5.4 / ADR 0003)
##
## 흐름(PRD §142): 카드 확대/획득 화면 → "공유" → 이 오버레이가 **공유용 이미지를 합성**해 미리보기 →
##   "저장" → 웹은 브라우저 다운로드(JavaScriptBridge), 데스크톱은 user://shares/ 에 PNG.
## 합성 = SubViewport 에 [크림 액자 + 체키 사진면(2배) + 푸터(@나라카 워드마크 · QR 자리)]를 그려
##   한 프레임 렌더 → get_image(). 도트 유지(전부 NEAREST, 카드는 정수 2배).
## 셸 3버튼: OK=저장 · CANCEL=닫기. 터치는 버튼/딤(바깥 탭=닫기).
## LCD(333×480) 전체를 덮는 오버레이. 닫히면 closed 신호.

signal closed

const LCD := Vector2(333, 480)

# 합성 캔버스(공유 이미지 원본) — 카드 정수 2배(240×360) + 패드 + 푸터.
const PAD := 12.0
const CARD_SCALE := 2.0
const FOOTER_GAP := 8.0
const FOOTER_H := 40.0
var SHARE_SIZE := Vector2(
  PAD + ChekiCard.CARD.x * CARD_SCALE + PAD,                       # 12+240+12 = 264
  PAD + ChekiCard.CARD.y * CARD_SCALE + FOOTER_GAP + FOOTER_H + PAD)  # 12+360+8+40+12 = 432

const HANDLE := "@나라카"

var _character: String
var _event: String
var _butterfly: bool
var _nickname: String
var _acquired_at: int

var _image: Image          # 저장용 원본(합성 결과)
var _compose_card: ChekiCard  # 합성 캔버스의 체키 카드(트리 진입 후 setup)
var _preview: TextureRect
var _hint: Label
var _closing := false


## 공유할 체키 데이터 주입(트리 진입 전).
func setup(character: String, event: String, butterfly: bool, nickname: String, acquired_at: int) -> void:
  _character = character
  _event = event
  _butterfly = butterfly
  _nickname = nickname
  _acquired_at = acquired_at


func _ready() -> void:
  size = LCD
  mouse_filter = Control.MOUSE_FILTER_STOP  # 뒤 입력 차단

  var dim := ColorRect.new()
  dim.color = Color(Palette.INK.r, Palette.INK.g, Palette.INK.b, 0.0)
  dim.size = LCD
  dim.mouse_filter = Control.MOUSE_FILTER_STOP
  dim.gui_input.connect(_on_dim_input)
  add_child(dim)
  create_tween().tween_property(dim, "color:a", 0.84, 0.2)

  var title := _make_label(Fonts.SIZE_TITLE, Palette.GOLD, 6)
  title.text = "공유 이미지"
  title.add_theme_constant_override("outline_size", 3)
  add_child(title)

  # 미리보기 자리(합성 완료 전까지 안내)
  _preview = TextureRect.new()
  _preview.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
  _preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
  _preview.stretch_mode = TextureRect.STRETCH_SCALE
  _preview.mouse_filter = Control.MOUSE_FILTER_STOP  # 카드 탭은 닫기로 안 넘김
  add_child(_preview)

  _hint = _make_label(Fonts.SIZE_SMALL, Palette.GREY_300, 458)
  _hint.text = "이미지를 만드는 중…"
  add_child(_hint)

  _build_buttons()

  modulate.a = 0.0
  create_tween().tween_property(self, "modulate:a", 1.0, 0.16)

  _compose_async()  # SubViewport 합성 → 미리보기 채움(코루틴)


# ── 입력 ─────────────────────────────────────────────────

## 셸 3버튼 중계 (상위 오버레이 → 여기). OK=저장 · CANCEL=닫기.
func handle_shell_action(action: StringName) -> void:
  match action:
    &"ok", &"select": _save()
    &"cancel": _close()


func _on_dim_input(event: InputEvent) -> void:
  if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
    _close()
    accept_event()


# ── 합성 (SubViewport → 이미지) ───────────────────────────

## 공유 이미지를 오프스크린에서 한 프레임 렌더해 캡처 → 미리보기 텍스처로.
func _compose_async() -> void:
  var vp := SubViewport.new()
  vp.size = Vector2i(SHARE_SIZE)
  vp.transparent_bg = false
  vp.render_target_update_mode = SubViewport.UPDATE_ONCE
  vp.add_child(_compose())
  add_child(vp)

  # 카드가 이제 트리에 들어와 _ready(내부 _front/_back/_emblem 생성) 가 끝났다 →
  # 그 다음에 내용을 채우고 사진 면으로 돌린다(트리 진입 전 setup 은 null 접근 — 합성 누락).
  _compose_card.setup(_character, _event, _butterfly, _nickname, _acquired_at)
  _compose_card.show_face(true)  # 사진 면(자랑용 비주얼)

  # 렌더 완료 대기(한 프레임) 후 이미지 회수.
  await RenderingServer.frame_post_draw
  await get_tree().process_frame
  _image = vp.get_texture().get_image()
  vp.queue_free()

  if _image == null:
    _hint.text = "이미지 생성 실패"
    return
  _preview.texture = ImageTexture.create_from_image(_image)
  _layout_preview()
  _hint.text = "OK ▶ 저장  ·  바깥 탭 ▶ 닫기"


## 합성 캔버스(공유 이미지 원본) Control 트리 — 크림 액자 + 체키 사진면 + 푸터.
func _compose() -> Control:
  var root := Control.new()
  root.size = SHARE_SIZE

  # 1) 크림 바탕 + 골드 액자(이중 테두리)
  var bg := ColorRect.new()
  bg.color = Palette.CREAM
  bg.size = SHARE_SIZE
  root.add_child(bg)
  _add_border(root, SHARE_SIZE, 4.0, Palette.GOLD)
  _add_border(root, SHARE_SIZE, 1.0, Palette.GOLD_DARK, 5.0)

  # 2) 체키 사진 면(정수 2배) — 액자 안 상단
  var holder := Control.new()
  holder.scale = Vector2(CARD_SCALE, CARD_SCALE)
  holder.position = Vector2(PAD, PAD)
  root.add_child(holder)
  # 카드 내용 채우기(setup)·면 전환은 트리 진입 후 _compose_async 에서(여기선 노드만 단다).
  _compose_card = ChekiCard.new()
  holder.add_child(_compose_card)

  # 3) 푸터 — 구분선 + @나라카 워드마크 + QR 자리
  var fy := PAD + ChekiCard.CARD.y * CARD_SCALE + FOOTER_GAP
  var sep := ColorRect.new()
  sep.color = Palette.GOLD_DARK
  sep.position = Vector2(PAD, fy)
  sep.size = Vector2(ChekiCard.CARD.x * CARD_SCALE, 1)
  root.add_child(sep)

  # @나라카(핸들) + 보조 한 줄 — 좌측
  var handle := _make_label(Fonts.SIZE_LEAD, Palette.BURGUNDY, 0)
  handle.add_theme_color_override("font_outline_color", Palette.CANDLE)
  handle.add_theme_constant_override("outline_size", 1)
  handle.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
  handle.text = HANDLE
  handle.position = Vector2(PAD + 4, fy + 6)
  handle.size = Vector2(140, 16)
  root.add_child(handle)

  var sub := _make_label(Fonts.SIZE_SMALL, Palette.GOLD_DARK, 0)
  sub.add_theme_color_override("font_outline_color", Palette.CREAM)
  sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
  sub.text = "나라쿠치 체키"
  sub.position = Vector2(PAD + 4, fy + 22)
  sub.size = Vector2(140, 12)
  root.add_child(sub)

  # QR 자리 — 우측
  var qr := QrPlaceholder.new()
  qr.setup(33.0)
  var qside := qr.side_px()
  qr.position = Vector2(SHARE_SIZE.x - PAD - qside, fy + (FOOTER_H - qside) / 2.0)
  root.add_child(qr)

  return root


## 미리보기를 화면에 맞춰 배치(세로 기준 축소 — 원본은 저장 시 크리스프).
func _layout_preview() -> void:
  var avail_h := 392.0
  var s := minf(LCD.x / SHARE_SIZE.x, avail_h / SHARE_SIZE.y)
  var w := SHARE_SIZE.x * s
  var h := SHARE_SIZE.y * s
  _preview.size = Vector2(w, h)
  _preview.position = Vector2((LCD.x - w) / 2.0, 32)


# ── 저장 / 공유 ───────────────────────────────────────────

## 합성 이미지를 PNG 로 내보낸다. 웹=브라우저 다운로드 · 그 외=user://shares/.
func _save() -> void:
  if _image == null:
    return
  Sfx.play(&"shutter")
  var buf := _image.save_png_to_buffer()
  var fname := "narakuchi_cheki_%s_%s.png" % [Events.event_slug(_event), _date_stamp()]

  if OS.has_feature("web"):
    _web_download(buf, fname)
    _flash("이미지를 저장했어요  (워터마크 %s)" % HANDLE)
  else:
    var dir := "user://shares"
    DirAccess.make_dir_recursive_absolute(dir)
    var path := "%s/%s" % [dir, fname]
    var err := _image.save_png(path)
    if err == OK:
      _flash("저장됨: %s" % ProjectSettings.globalize_path(path))
    else:
      _flash("저장 실패 (err %d)" % err)


## 웹 — base64 data URL 을 임시 <a download> 로 받아 내려받기.
func _web_download(buf: PackedByteArray, fname: String) -> void:
  if not OS.has_feature("web"):
    return
  var b64 := Marshalls.raw_to_base64(buf)
  var js := "(function(d,n){var a=document.createElement('a');" \
    + "a.href='data:image/png;base64,'+d;a.download=n;" \
    + "document.body.appendChild(a);a.click();a.remove();})('%s','%s');"
  JavaScriptBridge.eval(js % [b64, fname], true)


# ── 구성 / 닫기 / 헬퍼 ────────────────────────────────────

func _build_buttons() -> void:
  var save := Button.new()
  save.text = "저장"
  UiTheme.style_button(save)
  save.size = Vector2(120, 28)
  save.position = Vector2(LCD.x / 2.0 - 124, 430)
  save.pressed.connect(_save)
  add_child(save)

  var close := Button.new()
  close.text = "닫기"
  UiTheme.style_button(close)
  close.size = Vector2(120, 28)
  close.position = Vector2(LCD.x / 2.0 + 4, 430)
  close.pressed.connect(_close)
  add_child(close)


func _add_border(parent: Control, sz: Vector2, width: float, color: Color, inset := 0.0) -> void:
  var p := Panel.new()
  p.position = Vector2(inset, inset)
  p.size = sz - Vector2(inset * 2.0, inset * 2.0)
  p.mouse_filter = Control.MOUSE_FILTER_IGNORE
  var sb := StyleBoxFlat.new()
  sb.bg_color = Color(0, 0, 0, 0)
  sb.set_border_width_all(int(width))
  sb.border_color = color
  p.add_theme_stylebox_override("panel", sb)
  parent.add_child(p)


func _close() -> void:
  if _closing:
    return
  _closing = true
  var t := create_tween()
  t.tween_property(self, "modulate:a", 0.0, 0.16)
  t.tween_callback(func() -> void:
    closed.emit()
    queue_free())


## 힌트를 잠깐 바꿨다가 기본 안내로 복귀.
func _flash(msg: String) -> void:
  _hint.text = msg
  var t := create_tween()
  t.tween_interval(2.4)
  t.tween_callback(func() -> void:
    if is_instance_valid(_hint) and not _closing:
      _hint.text = "OK ▶ 저장  ·  바깥 탭 ▶ 닫기")


## epoch(초) → "YYYYMMDD". 0 이면 오늘.
func _date_stamp() -> String:
  var d: Dictionary
  if _acquired_at > 0:
    d = Time.get_datetime_dict_from_unix_time(_acquired_at)
  else:
    d = Time.get_datetime_dict_from_system()
  return "%04d%02d%02d" % [d["year"], d["month"], d["day"]]


func _make_label(font_size: int, color: Color, y: float) -> Label:
  var lb := Label.new()
  if font_size <= 9:
    var f9 := Fonts.galmuri9()
    if f9:
      lb.add_theme_font_override("font", f9)
  lb.add_theme_font_size_override("font_size", font_size)
  lb.add_theme_color_override("font_color", color)
  lb.add_theme_color_override("font_outline_color", Palette.INK)
  lb.add_theme_constant_override("outline_size", 2)
  lb.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
  lb.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
  lb.position = Vector2(0, y)
  lb.size = Vector2(LCD.x, 22)
  lb.mouse_filter = Control.MOUSE_FILTER_IGNORE
  return lb
