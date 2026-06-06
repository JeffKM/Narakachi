extends Node
## 효과음 시스템 (T18 "사운드 자리") — 8비트 SFX 큐 디스패처. (→ ROADMAP S3 / PRD §10)
##
## 지금은 **자리만 잡는다**: 큐 키 → `assets/audio/` 경로만 매핑해 두고, 파일이 아직 없으면
## 조용히 무시(no-op)한다. S3에서 8비트 효과음을 그 경로에 떨궈 넣으면 코드 수정 없이 자동 발화.
## 마스터와 분리된 SFX 버스(개별 음량 제어용)를 런타임에 만들어 붙인다(.tres 불필요).
##
## 사용: `Sfx.play(&"cheki_get")` · `Sfx.play(&"tap", 1.1)` (pitch 변주).
## 오토로드 "Sfx" (project.godot). 일시정지/오버레이 중에도 울리게 PROCESS_MODE_ALWAYS.

# 큐 키 → 에셋 경로. 없으면 no-op(=사운드 자리). 키는 ROADMAP S3(오더/획득/나비) 기준.
const CUES := {
  &"order":      "res://assets/audio/sfx_order.wav",       # 체키/음료 주문(딸랑)
  &"cheki_get":  "res://assets/audio/sfx_cheki_get.wav",   # 오늘의 체키 획득(언박싱 팡)
  &"butterfly":  "res://assets/audio/sfx_butterfly.wav",   # 나비 승급(반짝 상승음)
  &"flip":       "res://assets/audio/sfx_flip.wav",        # 카드 뒤집기(촤락)
  &"tap":        "res://assets/audio/sfx_tap.wav",         # UI 버튼/선택(틱)
  &"gauge_full": "res://assets/audio/sfx_gauge_full.wav",  # 호감도 게이지 풀(차오름 완료)
  &"book":       "res://assets/audio/sfx_book.wav",        # 체키북 열기(책장)
  &"shutter":    "res://assets/audio/sfx_shutter.wav",     # 공유 이미지 저장(찰칵)
}
const VOICES := 6          # 동시 발화 풀(빠른 연속 큐 겹침 허용)
const SFX_BUS := &"SFX"

var _players: Array[AudioStreamPlayer] = []
var _cache := {}           # path → AudioStream (null 도 캐시 — 반복 exists 체크 회피)
var _next := 0


func _ready() -> void:
  process_mode = Node.PROCESS_MODE_ALWAYS  # 오버레이/일시정지 중에도 울림
  _ensure_bus()
  for _i in VOICES:
    var p := AudioStreamPlayer.new()
    p.bus = String(SFX_BUS)
    add_child(p)
    _players.append(p)


## 큐 발화. 파일이 아직 없으면 조용히 무시(사운드 자리). pitch_scale 로 같은 큐를 가볍게 변주.
func play(cue: StringName, pitch_scale := 1.0) -> void:
  var stream := _stream_for(cue)
  if stream == null:
    return
  var p := _players[_next]
  _next = (_next + 1) % _players.size()
  p.stream = stream
  p.pitch_scale = pitch_scale
  p.play()


# ── 내부 ─────────────────────────────────────────────────

## SFX 전용 버스를 런타임에 한 번 만들어 Master 로 보낸다(이미 있으면 그대로).
func _ensure_bus() -> void:
  if AudioServer.get_bus_index(String(SFX_BUS)) != -1:
    return
  var idx := AudioServer.bus_count
  AudioServer.add_bus(idx)
  AudioServer.set_bus_name(idx, String(SFX_BUS))
  AudioServer.set_bus_send(idx, &"Master")


## 큐 키의 스트림(없으면 null). 경로별 1회 로드 후 캐시.
func _stream_for(cue: StringName) -> AudioStream:
  if not CUES.has(cue):
    return null
  var path: String = CUES[cue]
  if _cache.has(path):
    return _cache[path]
  var s: AudioStream = null
  if ResourceLoader.exists(path):
    s = load(path) as AudioStream
  _cache[path] = s
  return s
