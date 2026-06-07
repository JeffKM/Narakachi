#!/usr/bin/env bash
# 나라쿠치 헤드리스 테스트 전수 실행기 (T23) — 세 씬을 돌려 결과를 합산한다.
#
#   tools/run_tests.sh
#
# 새 class_name(예: Clock) 추가 후엔 클래스 캐시 리빌드가 필요하므로 --import 를 먼저 1회 돈다.
# 각 테스트 씬은 실패 시 exit 1 로 끝나며, 하나라도 실패하면 이 스크립트도 1 로 끝난다(CI 친화).

set -u
cd "$(dirname "$0")/.." || exit 2

GODOT="${GODOT:-godot}"
command -v "$GODOT" >/dev/null 2>&1 || GODOT="/usr/local/bin/godot"
command -v "$GODOT" >/dev/null 2>&1 || { echo "✗ godot 실행파일을 찾을 수 없음 (GODOT 환경변수로 지정)"; exit 2; }

SCENES=(
  "res://tests/test_systems.tscn"
  "res://tests/test_content.tscn"
  "res://tests/test_cutin.tscn"
)

echo "── 클래스 캐시 리빌드(--import) ──"
"$GODOT" --headless --import --path . >/dev/null 2>&1

FAILED=0
for scene in "${SCENES[@]}"; do
  echo ""
  echo "▶ $scene"
  "$GODOT" --headless --path . "$scene"
  code=$?
  if [ "$code" -ne 0 ]; then
    echo "  ✗ 실패 (exit $code)"
    FAILED=1
  fi
done

echo ""
if [ "$FAILED" -eq 0 ]; then
  echo "═══ 전체 통과 ✅ ═══"
else
  echo "═══ 실패 있음 ❌ ═══"
fi
exit "$FAILED"
