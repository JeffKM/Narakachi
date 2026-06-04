class_name Cheki
extends RefCounted
## 체키 컬렉션 모델 (T12) — 보유·등급·승급. (→ ADR 0002 세트축×프레임등급 / ADR 0003 양면 카드)
##
## SaveManager.data["cheki"] 를 단일 출처(SSOT)로 직접 읽고 쓴다. 키 = "{character}:{event}".
## 한 칸(슬롯) 레코드:
##   { common:int(획득 누적수), butterfly:bool(나비 승급 여부),
##     shards:int(나비까지 모은 조각), nickname:String(첫 획득 시 닉 스냅샷), acquired_at:int(첫 획득 epoch) }
##
## 등급 규칙(ADR 0002): 일반 = 표준 프레임, 나비 = 테마 프레임. 아트는 등급 무관 동일.
## 승급 규칙(ADR 0003): "중복 → 나비 승급". 같은 칸을 다시 받으면 조각 +1,
##   BUTTERFLY_SHARDS_NEEDED(=3) 모이면 나비로 변태(탄날개 → 나비 부화).
## 수치는 전부 Balance(data/balance.gd)에서만.

const GRADE_NONE := "none"          # 미보유
const GRADE_COMMON := "common"      # 일반체키 (표준 프레임)
const GRADE_BUTTERFLY := "butterfly"  # 나비체키 (테마 프레임)


## 빈 슬롯 레코드 기본값.
static func _empty_record() -> Dictionary:
  return {"common": 0, "butterfly": false, "shards": 0, "nickname": "", "acquired_at": 0}


## 슬롯 레코드를 읽어 기본값으로 보정해 반환(읽기전용 사본). 미보유면 빈 레코드.
static func record(character: String, event: String) -> Dictionary:
  var col: Dictionary = SaveManager.get_value("cheki", {})
  var key := Events.cheki_key(character, event)
  var raw: Variant = col.get(key, null)
  var r := _empty_record()
  if typeof(raw) == TYPE_DICTIONARY:
    for k in r:
      if (raw as Dictionary).has(k):
        r[k] = (raw as Dictionary)[k]
  return r


## 슬롯 등급 ("none" | "common" | "butterfly").
static func grade(character: String, event: String) -> String:
  var r := record(character, event)
  if bool(r["butterfly"]):
    return GRADE_BUTTERFLY
  if int(r["common"]) > 0:
    return GRADE_COMMON
  return GRADE_NONE


## 보유 여부.
static func owned(character: String, event: String) -> bool:
  return grade(character, event) != GRADE_NONE


## "오늘의 체키" 이벤트를 고른다 (게이지 풀 → 자동 획득, T13).
## 캐릭터의 칸이 있고 + 아트가 준비된 이벤트 중에서:
##   1) 미보유 우선(브레드스 — 컬렉션 채우기)
##   2) 일반만 보유(나비 미승급) 우선(체이스 — 중복으로 승급 진행)
##   3) 전부 나비면 첫 후보(중복, 조각은 더 안 쌓임)
static func pick_today(character: String) -> String:
  var candidates: Array = []
  for ev in Events.LIST:
    if bool(Events.LIST[ev].get(character, false)) and Events.cheki_art_ready(ev):
      candidates.append(ev)
  if candidates.is_empty():
    return Events.FIRST_GIFT_EVENT  # 안전 폴백(아트 준비 전이라도 죽지 않게)

  for ev in candidates:
    if grade(character, ev) == GRADE_NONE:
      return ev
  for ev in candidates:
    if grade(character, ev) == GRADE_COMMON:
      return ev
  return candidates[0]


## 체키 1장 지급. 미보유 → 일반 신규, 중복 → 나비 조각(+승급 판정). 저장까지 한다.
## 반환(획득 연출 T13/T18 용):
##   { character, event, grade(획득 후), was_new:bool(첫 획득),
##     upgraded:bool(이번에 나비로 승급), shards:int, shards_needed:int,
##     nickname:String, acquired_at:int }
static func grant(character: String, event: String) -> Dictionary:
  var col: Dictionary = SaveManager.get_value("cheki", {})
  var key := Events.cheki_key(character, event)
  var r := record(character, event)  # 기본값 보정된 사본

  var was_new := int(r["common"]) == 0
  r["common"] = int(r["common"]) + 1

  var upgraded := false
  if was_new:
    # 첫 획득 — 닉네임·날짜 스냅샷(표지 헌사용)
    r["nickname"] = String(SaveManager.get_value("player.nickname", "손님"))
    r["acquired_at"] = int(Time.get_unix_time_from_system())
  elif not bool(r["butterfly"]):
    # 중복 → 나비 조각. 다 모이면 변태 승급.
    r["shards"] = int(r["shards"]) + 1
    if int(r["shards"]) >= Balance.BUTTERFLY_SHARDS_NEEDED:
      r["butterfly"] = true
      r["shards"] = 0
      upgraded = true

  col[key] = r
  SaveManager.set_value("cheki", col)
  SaveManager.save_game()

  var g := GRADE_BUTTERFLY if bool(r["butterfly"]) else GRADE_COMMON
  return {
    "character": character,
    "event": event,
    "grade": g,
    "was_new": was_new,
    "upgraded": upgraded,
    "shards": int(r["shards"]),
    "shards_needed": Balance.BUTTERFLY_SHARDS_NEEDED,
    "nickname": String(r["nickname"]),
    "acquired_at": int(r["acquired_at"]),
  }
