class_name Clock
extends RefCounted
## 시계 seam (T23) — 게임이 "지금/오늘"을 묻는 단일 출처.
##
## 출석·기분(방치)·세이브 타임스탬프가 시스템 시계를 직접 부르면 날짜를 넘기는
## 회귀 테스트를 쓸 수 없다. 모든 시간 질의를 여기로 모아, 테스트는 override 로
## "며칠 뒤"를 가짜로 흘려보낸다(`set_day`/`advance_days`). 평상시(override 없음)는
## 시스템 시계 그대로.
##
## 날짜 기준은 **로컬**로 통일한다. (과거 evaluate_session 은 today=로컬·yesterday=UTC 로
## 갈려 tz 자정 부근에서 연속출석 오판 소지가 있었다 → 이 seam 으로 한 기준으로 못 박음.)
##
## ⚠️ override 는 **디버그/테스트 전용**이다. 릴리스 게임 경로에서 호출하지 않는다.

# override 한 epoch(초). -1 이면 시스템 시계 사용(평상시).
static var _override_unix: int = -1


## 현재 시각(epoch 초). override 가 걸려 있으면 그 값, 아니면 시스템.
static func now() -> int:
  if _override_unix >= 0:
    return _override_unix
  return int(Time.get_unix_time_from_system())


## 오늘 로컬 날짜 "YYYY-MM-DD". now() 기준으로 파생(단일 출처).
static func today() -> String:
  return day_string(now())


## 임의 epoch → 로컬 날짜 "YYYY-MM-DD". (어제 계산: day_string(now() - 86400))
## Time 의 unix→문자열은 UTC 라, 시스템 tz bias(분)를 더해 로컬로 맞춘다.
static func day_string(unix: int) -> String:
  var bias_min := int(Time.get_time_zone_from_system().get("bias", 0))
  return Time.get_datetime_string_from_unix_time(unix + bias_min * 60).split("T")[0]


# ── 테스트/디버그 override ────────────────────────────────

## 시계를 특정 로컬 날짜의 정오로 고정한다(자정 경계 회피). 이후 day_string 이 그 날짜로 라운드트립.
static func set_day(date_str: String) -> void:
  var bias_sec := int(Time.get_time_zone_from_system().get("bias", 0)) * 60
  _override_unix = int(Time.get_unix_time_from_datetime_string(date_str + "T12:00:00")) - bias_sec


## 고정된 시계를 N일 앞으로(음수면 뒤로) 옮긴다. set_day 로 먼저 고정한 뒤 사용.
static func advance_days(n: int) -> void:
  if _override_unix < 0:
    _override_unix = now()
  _override_unix += n * 86400


## override 를 특정 epoch 로 직접 고정(방치 경과시간 테스트 등 시각 단위 제어용).
static func freeze_at(unix: int) -> void:
  _override_unix = unix


## override 해제 → 시스템 시계로 복귀. 테스트는 끝에 반드시 호출해 오염 방지.
static func reset() -> void:
  _override_unix = -1
