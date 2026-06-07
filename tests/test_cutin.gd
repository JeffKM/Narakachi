extends Node
## 단계 상승 컷인이 '넘긴 그 자리'가 아니라 '다음 입장(Cafe.start)'에 1회 뜨는지 통합 검증.
## 실제 Cafe 를 인스턴스화해 start() 를 태우고 _cutin(StageCutin) 노드 생성 여부를 본다.
##
##   godot --headless --path . tests/test_cutin.tscn
##
## 주의: build_state/개발 프리셋으로 세이브를 덮으므로, 기존 세이브를 백업했다가 끝에 원복한다.

const CafeScript = preload("res://scripts/cafe.gd")
const SAVE_PATH = "user://narakuchi_save.json"

var _pass := 0
var _fail := 0


func _ready() -> void:
  var backup = _read_save()  # 기존 세이브 백업
  await _run()
  _restore_save(backup)      # 원복(없었으면 삭제)
  print("── 컷인 통합: %d 통과 / %d 실패 ──" % [_pass, _fail])
  get_tree().quit(0 if _fail == 0 else 1)


func _check(cond: bool, label: String) -> void:
  if cond:
    _pass += 1
    print("  ✓ ", label)
  else:
    _fail += 1
    print("  ✗ 실패: ", label)


func _run() -> void:
  # 0) 단골 등극 컷인: announced=guest 에서 단골(regular) 도달 → 다음 입장에 단골 컷인 발화
  SaveManager.data = SaveManager.build_state({"okja_stage": "regular", "announced_stage": "guest"})
  SaveManager.save_game()
  _check(Balance.relationship_stage(int(SaveManager.get_value("okja.affinity_total", 0))) == "regular",
    "상태: 단골(regular) 도달")
  var cafe0: Node = CafeScript.new()
  add_child(cafe0)
  cafe0.start()
  await get_tree().process_frame
  _check(cafe0._cutin != null, "단골 도달: 단골 등극 컷인 발화")
  _check(cafe0._cutin != null and cafe0._cutin._stage == "regular", "단골 컷인 stage=regular")
  _check(String(SaveManager.get_value("flags.announced_stage", "?")) == "regular",
    "단골 컷인 후: announced_stage=regular 커밋")
  cafe0.queue_free()
  await get_tree().process_frame

  # 1) 개발 프리셋 상태: 반말 전환(comfy) 직전 단골 + announced_stage=regular
  SaveManager.apply_dev_preset("comfy_edge")
  _check(String(SaveManager.get_value("flags.announced_stage", "?")) == "regular",
    "프리셋: announced_stage=regular")
  _check(Balance.relationship_stage(int(SaveManager.get_value("okja.affinity_total", 0))) == "regular",
    "프리셋: comfy 직전이라 아직 단골(regular)")

  # 첫 입장 — 컷인 안 떠야(시드가 이미 단골이라 알릴 게 없음)
  var cafe1: Node = CafeScript.new()
  add_child(cafe1)
  cafe1.start()
  await get_tree().process_frame
  _check(cafe1._cutin == null, "첫 입장: 반말 컷인 안 뜸")
  _check(String(SaveManager.get_value("flags.announced_stage", "?")) == "regular",
    "첫 입장: announced 그대로(regular)")
  cafe1.queue_free()
  await get_tree().process_frame

  # 2) 한 번 교감해 임계값(REL_COMFY)을 넘김 — comfy 도달
  SaveManager.set_value("okja.affinity_total", Balance.REL_COMFY)
  SaveManager.save_game()
  _check(Balance.relationship_stage(Balance.REL_COMFY) == "comfy", "교감 후: 편해진 사이(comfy) 도달")

  # 다음 입장 — 반말 전환 컷인 발화
  var cafe2: Node = CafeScript.new()
  add_child(cafe2)
  cafe2.start()
  await get_tree().process_frame
  _check(cafe2._cutin != null, "다음 입장: 반말 전환 컷인 발화")
  _check(String(SaveManager.get_value("flags.announced_stage", "?")) == "comfy",
    "컷인 후: announced_stage=comfy 커밋")
  cafe2.queue_free()
  await get_tree().process_frame

  # 3) 또 들어가도 재발화 안 함(이미 알림 완료)
  var cafe3: Node = CafeScript.new()
  add_child(cafe3)
  cafe3.start()
  await get_tree().process_frame
  _check(cafe3._cutin == null, "재입장: 컷인 재발화 안 함")
  cafe3.queue_free()
  await get_tree().process_frame

  # 4) regular_edge 프리셋(단골 등극 직전, 디버그 키 7) — comfy_edge 와 대칭 데모 비트.
  #    announced=guest 라 한 번 교감해 단골 도달하면 다음 입장에 '단골 인사' 컷인이 터져야.
  SaveManager.apply_dev_preset("regular_edge")
  _check(String(SaveManager.get_value("flags.announced_stage", "?")) == "guest",
    "regular_edge: announced_stage=guest(단골 알림 살아있음)")
  _check(Balance.relationship_stage(int(SaveManager.get_value("okja.affinity_total", 0))) == "guest",
    "regular_edge: 단골 직전이라 아직 손님(guest)")

  # 첫 입장 — 아직 손님이라 컷인 없음
  var cafe4: Node = CafeScript.new()
  add_child(cafe4)
  cafe4.start()
  await get_tree().process_frame
  _check(cafe4._cutin == null, "regular_edge 첫 입장: 컷인 없음(아직 손님)")
  cafe4.queue_free()
  await get_tree().process_frame

  # 한 번 교감해 단골(REL_REGULAR) 도달 → 다음 입장에 단골 등극 컷인
  SaveManager.set_value("okja.affinity_total", Balance.REL_REGULAR)
  SaveManager.save_game()
  var cafe5: Node = CafeScript.new()
  add_child(cafe5)
  cafe5.start()
  await get_tree().process_frame
  _check(cafe5._cutin != null and cafe5._cutin._stage == "regular",
    "regular_edge: 단골 도달 → 단골 등극 컷인 발화")
  _check(String(SaveManager.get_value("flags.announced_stage", "?")) == "regular",
    "regular_edge: 단골 컷인 후 announced_stage=regular 커밋")
  cafe5.queue_free()
  await get_tree().process_frame


func _read_save():
  if not FileAccess.file_exists(SAVE_PATH):
    return null
  var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
  var s := f.get_as_text()
  f.close()
  return s


func _restore_save(backup) -> void:
  if backup == null:
    var d := DirAccess.open("user://")
    if d and d.file_exists("narakuchi_save.json"):
      d.remove("narakuchi_save.json")
    return
  var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
  f.store_string(String(backup))
  f.close()
