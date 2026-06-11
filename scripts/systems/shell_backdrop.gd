class_name ShellBackdrop
extends Node2D
## 셸 뒤 잔불 백드롭 — 달걀 디바이스가 놓인 "지옥 공간". (→ ADR 0001 개정)
##
## 목적은 공유성: 라이브 화면을 캡처했을 때 달걀 둘레가 검은 보이드가 아니라
##   은은한 잔불로 살아 있게 한다. (전용 QR 공유 카드 share_card.gd 는 별개 표면 — 안 건드림)
##
## 구성(정적, 게임 상태 무반응):
##   L0 베이스 — 방사형 그라데이션. 달걀 뒤 중심=따뜻한 버건디 → 가장자리=먹빛 INK(비네팅 내장).
##              가장자리 색을 INK 로 맞춰, aspect=keep 의 레터박스 바(clear color=INK)와 이음매 없이 잇는다.
##   L1 잔불   — CPUParticles2D 로 드문드문(~22) 캔들→블러드 불티가 화면 바닥 전폭에서 천천히 상승 + 점멸.
##
## 셸 스프라이트보다 **뒤**(Main 에서 먼저 add_child)라, 달걀이 중앙을 마스킹하고
##   양옆·위 여백으로 새어 오르는 불티만 보인다(디바이스 도트는 안 가림). GL Compatibility 안전 위해 CPU 입자.

const CANVAS := ShellFrame.CANVAS  # 베이스 캔버스 = 셸 텍스처 (635×877)

# ── L1 잔불 튜닝 (presentation 상수 — shell.gd 가 BTN_Y 등을 자체 보유하는 것과 동일 패턴) ──
# 달걀 "배"(y200~600)가 폭을 꽉 막아 옆 통로가 없다(셸 알파 실측). 그래서 두 소스로 나눈다:
#   발치 — 바닥 코너 쐐기(y600~877)에서 상승. 정수리 — 고리·불꽃 둘레 크게 열린 크라운(y0~130)에서 상승.
# 그 사이 통짜 배는 어차피 셸이 마스킹하므로 거기엔 안 쏜다. (→ ADR 0001 2026-06-11)
const EMBER_LIFETIME := 6.0       # 길게 떠 천천히 상승
const EMBER_SPEED_MIN := 12.0
const EMBER_SPEED_MAX := 26.0
const EMBER_GRAVITY := Vector2(0, -6)  # 살짝 가속하며 떠오름
const EMBER_SPREAD := 12.0         # 상승 방향 퍼짐(도)
const EMBER_SCALE_MIN := 1.0
const EMBER_SCALE_MAX := 2.0
const EMBER_TEX_SIZE := 2          # 불티 도트 한 변(px) — 정수배로 또렷이

const FOOT_COUNT := 22            # 발치 — 드문드문 (불바다 아님)
const FOOT_EMIT_Y := float(CANVAS.y)  # 화면 바닥
const CROWN_COUNT := 12          # 정수리 — 더 드물게 (셸 불꽃과 호응만)
const CROWN_EMIT_Y := 130.0      # 배 윗변 ≈ 크라운 밑자락 (실측: y120 부터 좌우 크게 열림)


func _ready() -> void:
  _make_base_gradient()
  _make_embers()


## L0 — 방사형 그라데이션 한 장 (중심 버건디 → 가장자리 INK).
func _make_base_gradient() -> void:
  var grad := Gradient.new()
  grad.offsets = PackedFloat32Array([0.0, 0.55, 1.0])
  grad.colors = PackedColorArray([
    Palette.BURGUNDY_DARK,  # 달걀 뒤 따뜻한 중심
    Color(Palette.BURGUNDY_DARK).lerp(Palette.INK, 0.7),
    Palette.INK,            # 가장자리 = 레터박스 바와 동색
  ])

  var tex := GradientTexture2D.new()
  tex.gradient = grad
  tex.width = CANVAS.x
  tex.height = CANVAS.y
  tex.fill = GradientTexture2D.FILL_RADIAL
  tex.fill_from = Vector2(0.5, 0.5)   # 중심
  tex.fill_to = Vector2(0.5, 1.0)     # 아래 가장자리까지 1.0 — 코너는 그보다 멀어 자연히 INK

  var spr := Sprite2D.new()
  spr.texture = tex
  spr.centered = false
  spr.position = Vector2.ZERO
  spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
  add_child(spr)


## L1 — 두 소스(발치 + 정수리)에서 피어오르는 캔들→블러드 불티.
## 텍스처·색 램프는 한 번 만들어 공유한다.
func _make_embers() -> void:
  var tex := _make_ember_texture()
  var ramp := _make_ember_ramp()
  _make_ember_source(FOOT_EMIT_Y, FOOT_COUNT, tex, ramp)    # 발치 (바닥 쐐기)
  _make_ember_source(CROWN_EMIT_Y, CROWN_COUNT, tex, ramp)  # 정수리 (고리·불꽃 크라운)


## 전폭 박스 에미터 하나 — emit_y 높이에서 count 개가 위로 상승. (배는 셸이 마스킹)
func _make_ember_source(emit_y: float, count: int, tex: Texture2D, ramp: Gradient) -> void:
  var p := CPUParticles2D.new()
  p.texture = tex
  p.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

  # 전폭 박스에서 방출 (좌표는 중앙 기준 반-extent)
  p.position = Vector2(CANVAS.x / 2.0, emit_y)
  p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
  p.emission_rect_extents = Vector2(CANVAS.x / 2.0, 2.0)

  p.amount = count
  p.lifetime = EMBER_LIFETIME
  p.randomness = 0.6
  p.preprocess = EMBER_LIFETIME  # 시작부터 화면 가득(빈 곳에서 차오르는 어색함 제거)

  # 위로 상승
  p.direction = Vector2(0, -1)
  p.spread = EMBER_SPREAD
  p.gravity = EMBER_GRAVITY
  p.initial_velocity_min = EMBER_SPEED_MIN
  p.initial_velocity_max = EMBER_SPEED_MAX

  p.scale_amount_min = EMBER_SCALE_MIN
  p.scale_amount_max = EMBER_SCALE_MAX
  p.color_ramp = ramp

  p.emitting = true
  add_child(p)


## 수명에 걸친 색: 캔들로 페이드인 → 블러드로 식으며 → 소멸.
func _make_ember_ramp() -> Gradient:
  var ramp := Gradient.new()
  ramp.offsets = PackedFloat32Array([0.0, 0.15, 0.6, 1.0])
  ramp.colors = PackedColorArray([
    Color(Palette.CANDLE, 0.0),
    Color(Palette.CANDLE, 0.9),
    Color(Palette.BLOOD, 0.7),
    Color(Palette.BLOOD, 0.0),
  ])
  return ramp


## 불티 도트 텍스처 — 팔레트 흰색 정사각 한 장(색은 color_ramp 가 입힌다). NEAREST 로 또렷.
func _make_ember_texture() -> ImageTexture:
  var img := Image.create(EMBER_TEX_SIZE, EMBER_TEX_SIZE, false, Image.FORMAT_RGBA8)
  img.fill(Color.WHITE)
  return ImageTexture.create_from_image(img)
