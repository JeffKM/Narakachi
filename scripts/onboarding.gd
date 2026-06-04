class_name Onboarding
extends Node2D
## 온보딩 (T06b) — 첫 접속 1회. (→ PRD §6, §4.5)
##   1) 닉네임 입력 → 옥자가 그 이름을 불러줌(몰입)
##   2) 옥자 존댓말 맞이 + 첫 방문 기념 지뢰계 일반체키 증정
## 끝나면 finished 신호 → Main 이 오버레이를 걷고 Cafe.start() 호출.
##
## flags.onboarded 로 1회만 뜬다(분기는 Main). 셸 OK 로도 진행 가능(터치 하이브리드).

signal finished

const LCD_W := 333
const LCD_H := 480
const NICK_MAX := 8
const NICK_DEFAULT := "손님"

# 가운데 초대장 카드 규격 (글자를 배경에서 떼어내 가독성 + 겹침 해소)
const CARD := Rect2(24, 96, 285, 304)
const HEART_SCALE := 2.4  # 골드 하트 엠블럼 확대 배율 (맥동)
const INPUT_W := 200
const BTN_W := 160

var _step := 0  # 0=닉네임 입력, 1=맞이/증정
var _submitting := false  # 제출 await 중 중복 진입 방지(엔터+버튼 동시)
var _title: Label
var _body: Label
var _nick_edit: LineEdit
var _confirm: Button
var _nick := ""


func _ready() -> void:
  # 1) 화면 전체를 살짝 어둡게 덮어 카페 입력 차단 (앤틱 무드는 살짝 남김)
  var bg := ColorRect.new()
  bg.color = Color(Palette.INK.r, Palette.INK.g, Palette.INK.b, 0.82)
  bg.position = Vector2.ZERO
  bg.size = Vector2(LCD_W, LCD_H)
  add_child(bg)

  # 2) 가운데 초대장 카드 (골드 테두리 버건디 패널 + 부드러운 그림자)
  var card := Panel.new()
  card.position = CARD.position
  card.size = CARD.size
  var sb := StyleBoxFlat.new()
  sb.bg_color = Color(Palette.BURGUNDY_DARK.r, Palette.BURGUNDY_DARK.g, Palette.BURGUNDY_DARK.b, 0.96)
  sb.set_corner_radius_all(10)
  sb.set_border_width_all(2)
  sb.border_color = Palette.GOLD
  sb.shadow_color = Color(Palette.INK.r, Palette.INK.g, Palette.INK.b, 0.6)
  sb.shadow_size = 6
  card.add_theme_stylebox_override("panel", sb)
  add_child(card)

  # 3) 맥동하는 골드 하트 엠블럼 (귀여움 포인트)
  var heart := HeartCursor.new()
  heart.position = Vector2(LCD_W / 2.0, 122)
  heart.scale = Vector2(HEART_SCALE, HEART_SCALE)
  add_child(heart)

  _title = _make_label("나라카에 오신 걸\n환영해요", 140, Fonts.SIZE_TITLE, Palette.CANDLE)
  add_child(_title)

  _body = _make_label("당신을 뭐라고 부를까요?", 212, Fonts.SIZE_BODY, Palette.CREAM)
  add_child(_body)

  _nick_edit = LineEdit.new()
  _nick_edit.placeholder_text = "닉네임"
  _nick_edit.max_length = NICK_MAX
  _nick_edit.alignment = HORIZONTAL_ALIGNMENT_CENTER
  _nick_edit.position = Vector2((LCD_W - INPUT_W) / 2.0, 248)
  _nick_edit.size = Vector2(INPUT_W, 34)
  UiTheme.style_input(_nick_edit)  # 공용 지옥풍 입력칸 테마
  _nick_edit.text_submitted.connect(func(_t): _advance())  # 엔터로 제출
  add_child(_nick_edit)

  _confirm = Button.new()
  _confirm.text = "들어가기"
  _confirm.position = Vector2((LCD_W - BTN_W) / 2.0, 314)
  _confirm.size = Vector2(BTN_W, 40)
  UiTheme.style_button(_confirm)  # 공용 지옥풍 버튼 테마
  _confirm.pressed.connect(_advance)
  add_child(_confirm)

  _nick_edit.grab_focus()


## 셸 OK → 진행 (SELECT/CANCEL 은 온보딩에선 무시).
func handle_shell_action(action: StringName) -> void:
  if action == &"ok":
    _advance()


# ── 진행 ─────────────────────────────────────────────────

func _advance() -> void:
  if _step == 0:
    _submit_nickname()
  else:
    finished.emit()


## 닉네임 확정 → 저장 + 첫 체키 증정 → 맞이 화면으로.
func _submit_nickname() -> void:
  if _submitting:
    return
  _submitting = true
  # 한글 IME 로 조합 중(preedit)인 마지막 음절은 아직 LineEdit.text 에 없다.
  # 포커스를 풀어 조합을 확정시키고 한 프레임 뒤에 읽어 마지막 글자 누락을 막는다.
  _nick_edit.release_focus()
  await get_tree().process_frame
  _nick = _nick_edit.text.strip_edges()
  if _nick.is_empty():
    _nick = NICK_DEFAULT
  SaveManager.set_value("player.nickname", _nick)
  _grant_first_cheki()
  SaveManager.set_value("flags.onboarded", true)
  SaveManager.save_game()

  # 입력 UI 숨기고 맞이 메시지로 전환
  _nick_edit.hide()
  _step = 1
  _title.text = "어서 오세요,\n%s님" % _nick
  _body.text = "첫 방문 기념이에요.\n지뢰계 체키를 드릴게요.\n\n(소중히 간직하세요)"
  _confirm.text = "시작하기"


## 첫 방문 기념: 지뢰계(★히어로) 일반체키 1장. (체키 모델 본격화는 T12)
func _grant_first_cheki() -> void:
  var key := Events.cheki_key(Events.OKJA, Events.FIRST_GIFT_EVENT)
  var cheki: Dictionary = SaveManager.get_value("cheki", {})
  cheki[key] = {"common": 1, "butterfly": false, "shards": 0}
  SaveManager.set_value("cheki", cheki)


## 가운데 정렬 + 외곽선 라벨 헬퍼.
func _make_label(text: String, y: int, size: int, color: Color) -> Label:
  var lb := Label.new()
  lb.text = text
  # 카드 안쪽(좌우 12px 여백)에 맞춰 가운데 정렬
  lb.position = Vector2(CARD.position.x + 12, y)
  lb.size = Vector2(CARD.size.x - 24, 0)
  lb.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
  lb.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
  lb.add_theme_font_size_override("font_size", size)
  lb.add_theme_color_override("font_color", color)
  lb.add_theme_color_override("font_outline_color", Palette.INK)
  lb.add_theme_constant_override("outline_size", 4)
  lb.add_theme_constant_override("line_spacing", 4)
  return lb
