#!/usr/bin/env python3
"""로컬 웹 빌드 서버 — Godot 4 HTML5 export 미리보기용.

Godot 4 웹은 SharedArrayBuffer(스레드)를 쓰므로 브라우저 교차출처 격리가 필요하다.
일반 http.server 는 COOP/COEP 헤더가 없어 검은 화면이 된다 → 여기서 헤더를 강제로 붙인다.

  python3 tools/serve_web.py            # export/ 를 127.0.0.1:8765 로 서빙
  python3 tools/serve_web.py 9000 dir   # 포트·디렉터리 지정
"""
import sys
from functools import partial
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer

PORT = int(sys.argv[1]) if len(sys.argv) > 1 else 8765
ROOT = sys.argv[2] if len(sys.argv) > 2 else "export"


class Handler(SimpleHTTPRequestHandler):
  def end_headers(self):
    # 교차출처 격리 — SharedArrayBuffer 활성화
    self.send_header("Cross-Origin-Opener-Policy", "same-origin")
    self.send_header("Cross-Origin-Embedder-Policy", "require-corp")
    self.send_header("Cross-Origin-Resource-Policy", "cross-origin")
    # 개발 중 캐시 무력화(새 빌드 즉시 반영)
    self.send_header("Cache-Control", "no-store")
    super().end_headers()

  def log_message(self, fmt, *args):  # 조용히
    pass


if __name__ == "__main__":
  httpd = ThreadingHTTPServer(("127.0.0.1", PORT), partial(Handler, directory=ROOT))
  print("serving %s/ at http://127.0.0.1:%d/" % (ROOT, PORT))
  httpd.serve_forever()
