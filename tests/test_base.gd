class_name TestBase
extends Node
## 헤드리스 회귀 테스트 공용 베이스 (T23 테스트 재설계).
##
## 서브클래스는 `_suite` 이름을 정하고 `run_suite()`(await 가능)에 단언만 작성한다.
## 베이스가 처리: ① 플레이어 실제 세이브 백업→원복(테스트가 user:// 오염 안 시킴),
##   ② Clock override 리셋, ③ pass/fail 집계·요약·exit code.
##
## 실행: godot --headless res://tests/<scene>.tscn  (전수는 tools/run_tests.sh)

const SAVE_PATH := "user://narakuchi_save.json"

var _pass := 0
var _fail := 0
var _suite := "테스트"  # 서브클래스가 _init/run_suite 앞에서 덮어쓴다


## 서브클래스 구현부 — 실제 단언. await 사용 가능(씬/노드 검증 시).
func run_suite() -> void:
  push_error("[TestBase] run_suite() 미구현 — 서브클래스에서 재정의하라")


func _ready() -> void:
  var backup: Variant = _read_save()  # 기존 세이브 백업
  print("── %s 시작 ──" % _suite)
  await run_suite()
  Clock.reset()                       # override 오염 방지(다음 씬/실플레이 보호)
  _restore_save(backup)               # 플레이어 실제 세이브 원복(없었으면 삭제)
  print("── %s: %d 통과 / %d 실패 ──" % [_suite, _pass, _fail])
  get_tree().quit(0 if _fail == 0 else 1)


## 단언 1건. cond 가 참이면 통과.
func check(cond: bool, label: String) -> void:
  if cond:
    _pass += 1
    print("  ✓ ", label)
  else:
    _fail += 1
    print("  ✗ 실패: ", label)


## 메모리 세이브를 기본값으로 되돌린다(파일은 건드리지 않음). 케이스 사이 격리용.
func wipe() -> void:
  SaveManager.data = SaveManager.default_save()


## Clock 기준 오늘에서 offset_days 만큼 떨어진 로컬 날짜 "YYYY-MM-DD".
## (어제 = ymd(-1)) — 상대 날짜 단언에 쓴다.
func ymd(offset_days: int = 0) -> String:
  return Clock.day_string(Clock.now() + offset_days * 86400)


# ── 세이브 백업/원복 (실플레이 보호) ──────────────────────
func _read_save() -> Variant:
  if not FileAccess.file_exists(SAVE_PATH):
    return null
  var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
  var s := f.get_as_text()
  f.close()
  return s


func _restore_save(backup: Variant) -> void:
  if backup == null:
    var d := DirAccess.open("user://")
    if d and d.file_exists("narakuchi_save.json"):
      d.remove("narakuchi_save.json")
    return
  var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
  f.store_string(String(backup))
  f.close()
