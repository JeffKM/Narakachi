#!/usr/bin/env python3
"""나라쿠치 콘텐츠 스튜디오 — 대사·선택지·버튼·감정을 브라우저 GUI 로 편집하는 로컬 툴.

data/*.json (ticker·talk·gifts·buttons) 을 읽어 GUI 로 보여주고, 검증 후 그대로 다시 쓴다.
게임(GameData)과 이 툴이 같은 JSON 을 본다 → 단일 출처. (dot_studio.py 와 같은 무의존 패턴)

  - 옥자 티커: 상황(잠금)×단계(존댓말/반말) 라인 추가/삭제/수정
  - 시온이 티커: 버튼별 풀(cheki/snack/play/pet/idle) 라인 편집
  - 대화: 단계별 토막(질문) + 선택지(label/reply/tier/감정) CRUD
  - 선물: 프롬프트 + 선물 항목(label/reply/tier/감정) CRUD
  - 버튼·감정: 옥자 버튼/터치 감정맵 + 시온이 4버튼(라벨·감정·티커풀)

감정은 실제 스프라이트(assets/sprites/okja_*.png·sioni_*.png)를 썸네일로 보여준다.
대사 미리보기는 {nick} 을 샘플 닉네임으로 치환해 표시한다.

실행:
  python3 tools/content_studio.py            # 브라우저 자동 오픈(127.0.0.1:8770)
  python3 tools/content_studio.py --port 8800 --no-browser
"""
import argparse
import json
import os
import threading
import webbrowser
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
DATA_DIR = os.path.join(ROOT, "data")
SPRITES_DIR = os.path.join(ROOT, "assets", "sprites")

FILES = {
    "ticker": "ticker.json",
    "talk": "talk.json",
    "gifts": "gifts.json",
    "buttons": "buttons.json",
}

# 게임 코드와 일치해야 하는 허용값(검증용 단일 출처 — okja.gd / sioni.gd EXPRESSIONS 와 동기).
OKJA_EXPR = ["idle", "smile", "shy", "sad", "brew", "talk"]
SIONI_EXPR = ["idle", "snack", "play", "pet"]
TALK_TIERS = ["good", "plain"]
GIFT_TIERS = ["match", "sion", "plain"]
MAX_CHOICES = 4


# ── 데이터 입출력 ────────────────────────────────────────────

def load_all():
    db = {}
    for key, fname in FILES.items():
        path = os.path.join(DATA_DIR, fname)
        with open(path, encoding="utf-8") as f:
            db[key] = json.load(f)
    return db


def validate(db):
    """하드 에러(저장 차단) 목록을 반환한다. 빈 문자열 등은 경고로 두고 막지 않는다."""
    errs = []

    def is_str_list(v):
        return isinstance(v, list) and all(isinstance(x, str) for x in v)

    # ticker.okja
    okja = db.get("ticker", {}).get("okja", {})
    for sit, pools in okja.items():
        if sit.startswith("_"):
            continue
        if not isinstance(pools, dict):
            errs.append(f"옥자 티커 '{sit}' 형식 오류")
            continue
        for stage, lines in pools.items():
            if stage.startswith("_"):
                continue
            if not is_str_list(lines):
                errs.append(f"옥자 티커 '{sit}.{stage}' 는 문자열 배열이어야 함")

    # ticker.sion
    sion = db.get("ticker", {}).get("sion", {})
    sion_keys = [k for k in sion.keys() if not k.startswith("_")]
    for k in sion_keys:
        if not is_str_list(sion[k]):
            errs.append(f"시온이 티커 '{k}' 는 문자열 배열이어야 함")

    # talk
    talk = db.get("talk", {})
    for stage in ("guest", "regular"):
        topics = talk.get(stage, [])
        if not isinstance(topics, list):
            errs.append(f"대화 '{stage}' 는 토막 배열이어야 함")
            continue
        for ti, topic in enumerate(topics):
            choices = topic.get("choices", [])
            if not isinstance(choices, list) or not (1 <= len(choices) <= MAX_CHOICES):
                errs.append(f"대화 {stage}#{ti+1} 선택지는 1~{MAX_CHOICES}개여야 함")
                continue
            for ci, c in enumerate(choices):
                if c.get("tier") not in TALK_TIERS:
                    errs.append(f"대화 {stage}#{ti+1} 선택지{ci+1} tier 값 오류({c.get('tier')})")
                if c.get("expr") not in OKJA_EXPR:
                    errs.append(f"대화 {stage}#{ti+1} 선택지{ci+1} 감정 값 오류({c.get('expr')})")

    # gifts
    for gi, g in enumerate(db.get("gifts", {}).get("gifts", [])):
        if g.get("tier") not in GIFT_TIERS:
            errs.append(f"선물#{gi+1} tier 값 오류({g.get('tier')})")
        if g.get("expr") not in OKJA_EXPR:
            errs.append(f"선물#{gi+1} 감정 값 오류({g.get('expr')})")

    # buttons.okja.emotion
    em = db.get("buttons", {}).get("okja", {}).get("emotion", {})
    for k in ("cheki", "drink", "touch_cap"):
        if em.get(k) not in OKJA_EXPR:
            errs.append(f"옥자 감정 '{k}' 값 오류({em.get(k)})")
    touch = em.get("touch", [])
    if not isinstance(touch, list) or len(touch) == 0:
        errs.append("옥자 터치 감정 풀은 최소 1개여야 함")
    elif any(x not in OKJA_EXPR for x in touch):
        errs.append(f"옥자 터치 감정 풀에 잘못된 값({touch})")

    # buttons.sion.actions
    for a in db.get("buttons", {}).get("sion", {}).get("actions", []):
        if a.get("emotion") not in SIONI_EXPR:
            errs.append(f"시온이 버튼 '{a.get('id')}' 감정 값 오류({a.get('emotion')})")
        if a.get("ticker") not in sion_keys:
            errs.append(f"시온이 버튼 '{a.get('id')}' 티커풀 '{a.get('ticker')}' 가 시온이 티커에 없음")

    return errs


def save_all(db):
    for key, fname in FILES.items():
        path = os.path.join(DATA_DIR, fname)
        with open(path, "w", encoding="utf-8") as f:
            json.dump(db[key], f, ensure_ascii=False, indent=2)
            f.write("\n")


# ── HTTP 핸들러 ─────────────────────────────────────────────

class Handler(BaseHTTPRequestHandler):
    def log_message(self, *args):
        pass  # 조용히

    def _send(self, code, body, ctype="application/json; charset=utf-8"):
        data = body if isinstance(body, bytes) else body.encode("utf-8")
        self.send_response(code)
        self.send_header("Content-Type", ctype)
        self.send_header("Content-Length", str(len(data)))
        self.end_headers()
        self.wfile.write(data)

    def do_GET(self):
        if self.path == "/" or self.path.startswith("/?"):
            self._send(200, INDEX_HTML, "text/html; charset=utf-8")
        elif self.path == "/api/data":
            payload = {
                "db": load_all(),
                "meta": {
                    "okjaExpr": OKJA_EXPR,
                    "sioniExpr": SIONI_EXPR,
                    "talkTiers": TALK_TIERS,
                    "giftTiers": GIFT_TIERS,
                    "maxChoices": MAX_CHOICES,
                },
            }
            self._send(200, json.dumps(payload, ensure_ascii=False))
        elif self.path.startswith("/sprite/"):
            self._serve_sprite(self.path[len("/sprite/"):])
        else:
            self._send(404, json.dumps({"error": "not found"}))

    def _serve_sprite(self, name):
        # 경로 traversal 차단 — 영숫자/언더스코어만.
        safe = "".join(c for c in name if c.isalnum() or c == "_")
        path = os.path.join(SPRITES_DIR, safe + ".png")
        if not os.path.isfile(path):
            self._send(404, b"", "image/png")
            return
        with open(path, "rb") as f:
            self._send(200, f.read(), "image/png")

    def do_POST(self):
        if self.path != "/api/save":
            self._send(404, json.dumps({"error": "not found"}))
            return
        length = int(self.headers.get("Content-Length", 0))
        try:
            db = json.loads(self.rfile.read(length).decode("utf-8"))
        except Exception as e:
            self._send(400, json.dumps({"ok": False, "errors": [f"JSON 파싱 실패: {e}"]}))
            return
        errs = validate(db)
        if errs:
            self._send(400, json.dumps({"ok": False, "errors": errs}, ensure_ascii=False))
            return
        try:
            save_all(db)
        except Exception as e:
            self._send(500, json.dumps({"ok": False, "errors": [f"저장 실패: {e}"]}, ensure_ascii=False))
            return
        self._send(200, json.dumps({"ok": True}))


# ── 프론트엔드 (단일 페이지) ─────────────────────────────────

INDEX_HTML = r"""<!DOCTYPE html>
<html lang="ko">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>나라쿠치 콘텐츠 스튜디오</title>
<style>
  :root {
    --bg:#1a1320; --panel:#241a2e; --panel2:#2e2238; --ink:#f3e9f7; --muted:#a892b8;
    --line:#3c2d4a; --accent:#d4607f; --accent2:#7a5cff; --good:#5cc98a; --warn:#e0a85c;
  }
  * { box-sizing:border-box; }
  body { margin:0; font-family:-apple-system,"Apple SD Gothic Neo",system-ui,sans-serif;
    background:var(--bg); color:var(--ink); font-size:14px; }
  header { position:sticky; top:0; z-index:10; background:#160f1c; border-bottom:1px solid var(--line);
    display:flex; align-items:center; gap:12px; padding:10px 16px; }
  header h1 { font-size:15px; margin:0; letter-spacing:.5px; }
  header .spacer { flex:1; }
  .tabs { display:flex; gap:4px; padding:0 12px; background:#160f1c; border-bottom:1px solid var(--line);
    position:sticky; top:43px; z-index:9; }
  .tab { padding:9px 14px; cursor:pointer; color:var(--muted); border-bottom:2px solid transparent; }
  .tab.active { color:var(--ink); border-bottom-color:var(--accent); }
  main { padding:16px; max-width:980px; margin:0 auto; }
  .card { background:var(--panel); border:1px solid var(--line); border-radius:10px; padding:12px 14px;
    margin-bottom:12px; }
  .card > h3 { margin:0 0 10px; font-size:13px; color:var(--ink); display:flex; align-items:center; gap:8px; }
  .lock { font-size:11px; color:var(--muted); border:1px solid var(--line); border-radius:6px; padding:1px 6px; }
  .cols { display:grid; grid-template-columns:1fr 1fr; gap:14px; }
  @media(max-width:720px){ .cols{ grid-template-columns:1fr; } }
  .stage-label { font-size:12px; color:var(--accent); margin-bottom:6px; font-weight:600; }
  .row { display:flex; gap:6px; align-items:flex-start; margin-bottom:6px; }
  input[type=text], textarea, select {
    background:var(--panel2); color:var(--ink); border:1px solid var(--line); border-radius:7px;
    padding:6px 8px; font-size:13px; font-family:inherit; width:100%; }
  textarea { resize:vertical; min-height:34px; }
  input:focus, textarea:focus, select:focus { outline:none; border-color:var(--accent2); }
  .x { flex:0 0 auto; background:transparent; border:1px solid var(--line); color:var(--muted);
    border-radius:7px; width:30px; height:32px; cursor:pointer; font-size:14px; }
  .x:hover { color:#fff; border-color:var(--accent); }
  .add { background:transparent; border:1px dashed var(--line); color:var(--muted); border-radius:7px;
    padding:6px 10px; cursor:pointer; font-size:12px; margin-top:2px; }
  .add:hover { color:var(--ink); border-color:var(--accent2); }
  .add[disabled]{ opacity:.4; cursor:not-allowed; }
  .preview { font-size:12px; color:var(--muted); margin:2px 0 8px 2px; }
  .preview b { color:var(--ink); font-weight:500; }
  button.primary { background:var(--accent); color:#fff; border:none; border-radius:8px;
    padding:8px 16px; cursor:pointer; font-size:13px; font-weight:600; }
  button.primary:hover { filter:brightness(1.1); }
  button.ghost { background:transparent; border:1px solid var(--line); color:var(--muted);
    border-radius:8px; padding:8px 12px; cursor:pointer; font-size:13px; }
  .status { font-size:12px; color:var(--muted); }
  .status.dirty { color:var(--warn); }
  .status.ok { color:var(--good); }
  .status.err { color:var(--accent); }
  .emo { display:flex; gap:4px; flex-wrap:wrap; }
  .emo-chip { border:2px solid transparent; border-radius:8px; padding:2px; cursor:pointer;
    background:#1a1320; display:flex; flex-direction:column; align-items:center; width:46px; }
  .emo-chip img { width:36px; height:46px; object-fit:contain; image-rendering:pixelated; }
  .emo-chip span { font-size:9px; color:var(--muted); margin-top:1px; }
  .emo-chip.sel { border-color:var(--accent); }
  .emo-chip.sel span { color:var(--ink); }
  .choice { background:var(--panel2); border:1px solid var(--line); border-radius:8px; padding:8px;
    margin-bottom:8px; }
  .choice .grid { display:grid; grid-template-columns:1fr 1fr; gap:6px; }
  .field-label { font-size:11px; color:var(--muted); margin:6px 0 3px; }
  .topic { border-left:3px solid var(--accent2); }
  .badge { font-size:11px; color:var(--muted); background:#1a1320; border:1px solid var(--line);
    border-radius:6px; padding:2px 7px; }
  .err-list { background:#3a1620; border:1px solid var(--accent); border-radius:8px; padding:8px 12px;
    margin-bottom:12px; color:#ffd2dd; font-size:12px; white-space:pre-wrap; }
  .nick-input { width:120px; }
  .hint { font-size:11px; color:var(--muted); margin-top:4px; }
</style>
</head>
<body>
<header>
  <h1>🩸 나라쿠치 콘텐츠 스튜디오</h1>
  <span class="lock">data/*.json 직접 편집</span>
  <div class="spacer"></div>
  <label class="status">닉네임 미리보기: <input type="text" id="nick" class="nick-input" value="지반계"></label>
  <span id="status" class="status">불러오는 중…</span>
  <button class="ghost" id="reload">새로고침</button>
  <button class="primary" id="save">저장</button>
</header>
<div class="tabs" id="tabs"></div>
<main id="main"></main>

<script>
"use strict";
let DB = null, META = null;
let dirty = false;
let activeTab = "okja";
const TABS = [
  ["okja", "옥자 티커"],
  ["sion", "시온이 티커"],
  ["talk", "대화"],
  ["gifts", "선물"],
  ["buttons", "버튼·감정"],
];
const SITU_LABEL = {
  enter:"입장/첫 방문", neglect:"방치 후 복귀", cheki:"체키 주문", drink:"음료 주문",
  talk:"대화 진입", gift:"선물 진입", touch:"옥자 터치", touch_cap:"터치 상한",
  no_stamina:"기력 소진", cheki_get:"체키 획득", stage_up:"단계 상승", idle:"평소/심심",
};
const STAGE_LABEL = { guest:"존댓말 (손님)", regular:"반말 (단골)" };

// ── DOM 헬퍼 ──
function el(tag, attrs={}, kids=[]) {
  const n = document.createElement(tag);
  for (const k in attrs) {
    if (k === "class") n.className = attrs[k];
    else if (k === "html") n.innerHTML = attrs[k];
    else if (k.startsWith("on")) n.addEventListener(k.slice(2), attrs[k]);
    else n.setAttribute(k, attrs[k]);
  }
  for (const c of [].concat(kids)) if (c != null) n.append(c.nodeType ? c : document.createTextNode(c));
  return n;
}
function markDirty() { dirty = true; setStatus("저장되지 않은 변경", "dirty"); }
function setStatus(msg, cls) {
  const s = document.getElementById("status");
  s.textContent = msg; s.className = "status " + (cls||"");
}
function nick() { return document.getElementById("nick").value || "손님"; }
function sub(s) { return (s||"").replaceAll("{nick}", nick()); }

// 감정 썸네일 선택기(단일). charType: "okja"|"sioni".
function emotionPicker(charType, value, onChange) {
  const list = charType === "okja" ? META.okjaExpr : META.sioniExpr;
  const wrap = el("div", {class:"emo"});
  for (const expr of list) {
    const chip = el("div", {class:"emo-chip"+(expr===value?" sel":""), title:expr}, [
      el("img", {src:`/sprite/${charType}_${expr}`, alt:expr}),
      el("span", {}, expr),
    ]);
    chip.addEventListener("click", () => {
      value = expr;
      wrap.querySelectorAll(".emo-chip").forEach(c => c.classList.remove("sel"));
      chip.classList.add("sel");
      onChange(expr);
    });
    wrap.append(chip);
  }
  return wrap;
}

// 감정 멀티 선택기(터치 풀). 토글, 최소 1개.
function emotionMulti(charType, arr) {
  const list = charType === "okja" ? META.okjaExpr : META.sioniExpr;
  const wrap = el("div", {class:"emo"});
  for (const expr of list) {
    const on = arr.includes(expr);
    const chip = el("div", {class:"emo-chip"+(on?" sel":""), title:expr}, [
      el("img", {src:`/sprite/${charType}_${expr}`, alt:expr}),
      el("span", {}, expr),
    ]);
    chip.addEventListener("click", () => {
      const i = arr.indexOf(expr);
      if (i >= 0) { if (arr.length > 1) { arr.splice(i,1); chip.classList.remove("sel"); } }
      else { arr.push(expr); chip.classList.add("sel"); }
      markDirty();
    });
    wrap.append(chip);
  }
  return wrap;
}

// 라인 한 줄(텍스트 + {nick} 미리보기 + 삭제). arr 에서 idx 제거 가능.
function lineRow(arr, idx, rerender) {
  const val = arr[idx];
  const input = el("input", {type:"text", value:val});
  input.addEventListener("input", () => { arr[idx] = input.value; markDirty(); updatePrev(); });
  const prev = el("div", {class:"preview"});
  function updatePrev() {
    if ((arr[idx]||"").includes("{nick}")) { prev.style.display=""; prev.innerHTML = "▸ <b>"+esc(sub(arr[idx]))+"</b>"; }
    else prev.style.display = "none";
  }
  updatePrev();
  const row = el("div", {}, [
    el("div", {class:"row"}, [
      input,
      el("button", {class:"x", onclick:() => { arr.splice(idx,1); markDirty(); rerender(); }}, "✕"),
    ]),
    prev,
  ]);
  return row;
}
function esc(s){ return (s||"").replace(/[&<>]/g, c=>({"&":"&amp;","<":"&lt;",">":"&gt;"}[c])); }

// 문자열 배열 풀 편집 블록(라인 목록 + 추가).
function poolBlock(arr, addLabel) {
  const box = el("div");
  function render() {
    box.innerHTML = "";
    arr.forEach((_, i) => box.append(lineRow(arr, i, render)));
    box.append(el("button", {class:"add", onclick:() => { arr.push(""); markDirty(); render(); }}, "+ "+addLabel));
  }
  render();
  return box;
}

// ── 탭: 옥자 티커 ──
function renderOkja() {
  const main = document.getElementById("main");
  const okja = DB.ticker.okja;
  for (const sit in okja) {
    if (sit.startsWith("_")) continue;
    const pools = okja[sit];
    const cols = el("div", {class:"cols"});
    for (const stage of ["guest","regular"]) {
      if (!(stage in pools)) continue;
      cols.append(el("div", {}, [
        el("div", {class:"stage-label"}, STAGE_LABEL[stage]||stage),
        poolBlock(pools[stage], "라인 추가"),
      ]));
    }
    main.append(el("div", {class:"card"}, [
      el("h3", {}, [SITU_LABEL[sit]||sit, el("span", {class:"lock"}, "상황: "+sit+" (잠금)")]),
      cols,
    ]));
  }
}

// ── 탭: 시온이 티커 ──
function renderSion() {
  const main = document.getElementById("main");
  const sion = DB.ticker.sion;
  main.append(el("div", {class:"hint"}, "버튼 id 별 풀 + idle(터치·획득·평소). 버튼탭에서 각 버튼이 어느 풀을 쓰는지 지정합니다."));
  for (const key in sion) {
    if (key.startsWith("_")) continue;
    main.append(el("div", {class:"card"}, [
      el("h3", {}, [key, el("span", {class:"badge"}, "시온이 풀")]),
      poolBlock(sion[key], "라인 추가"),
    ]));
  }
}

// ── 선택지/선물 항목 편집 ──
function choiceBlock(choice, tiers, onRemove) {
  const labelI = el("input", {type:"text", value:choice.label||""});
  labelI.addEventListener("input", ()=>{ choice.label=labelI.value; markDirty(); });
  const replyI = el("input", {type:"text", value:choice.reply||""});
  const replyPrev = el("div", {class:"preview"});
  function up(){ replyPrev.innerHTML = "▸ 옥자: <b>"+esc(sub(choice.reply))+"</b>"; }
  replyI.addEventListener("input", ()=>{ choice.reply=replyI.value; markDirty(); up(); });
  up();
  const tierS = el("select", {});
  for (const t of tiers) tierS.append(el("option", {value:t, ...(t===choice.tier?{selected:"selected"}:{})}, t));
  tierS.addEventListener("change", ()=>{ choice.tier=tierS.value; markDirty(); });
  return el("div", {class:"choice"}, [
    el("div", {class:"row"}, [
      el("div", {style:"flex:1"}, [el("div",{class:"field-label"},"선택지 라벨(버튼)"), labelI]),
      el("button", {class:"x", onclick:onRemove}, "✕"),
    ]),
    el("div", {class:"field-label"}, "옥자 반응(하단 티커)"),
    replyI, replyPrev,
    el("div", {class:"grid"}, [
      el("div", {}, [el("div",{class:"field-label"},"tier (호감도)"), tierS]),
      el("div", {}, [el("div",{class:"field-label"},"선택 후 옥자 표정"),
        emotionPicker("okja", choice.expr, v=>{ choice.expr=v; markDirty(); })]),
    ]),
  ]);
}

// ── 탭: 대화 ──
function renderTalk() {
  const main = document.getElementById("main");
  for (const stage of ["guest","regular"]) {
    const topics = DB.talk[stage] || [];
    const wrap = el("div");
    function render() {
      wrap.innerHTML = "";
      topics.forEach((topic, ti) => {
        const promptI = el("input", {type:"text", value:topic.prompt||""});
        const promptPrev = el("div", {class:"preview"});
        function up(){ promptPrev.style.display=(topic.prompt||"").includes("{nick}")?"":"none";
          promptPrev.innerHTML="▸ <b>"+esc(sub(topic.prompt))+"</b>"; }
        promptI.addEventListener("input", ()=>{ topic.prompt=promptI.value; markDirty(); up(); });
        up();
        const choicesBox = el("div");
        function renderChoices() {
          choicesBox.innerHTML = "";
          topic.choices.forEach((c, ci) => choicesBox.append(
            choiceBlock(c, META.talkTiers, ()=>{ topic.choices.splice(ci,1); markDirty(); renderChoices(); })));
          const addBtn = el("button", {class:"add", onclick:()=>{
            if (topic.choices.length>=META.maxChoices) return;
            topic.choices.push({label:"",reply:"",tier:"plain",expr:"talk"}); markDirty(); renderChoices();
          }}, "+ 선택지 추가 (최대 "+META.maxChoices+")");
          if (topic.choices.length>=META.maxChoices) addBtn.setAttribute("disabled","");
          choicesBox.append(addBtn);
        }
        renderChoices();
        wrap.append(el("div", {class:"card topic"}, [
          el("h3", {}, ["토막 #"+(ti+1)+" — 옥자 질문",
            el("div",{class:"spacer",style:"flex:1"}),
            el("button", {class:"x", onclick:()=>{ topics.splice(ti,1); markDirty(); render(); }}, "✕")]),
          promptI, promptPrev,
          el("div", {class:"field-label", style:"margin-top:8px"}, "선택지"),
          choicesBox,
        ]));
      });
      wrap.append(el("button", {class:"add", onclick:()=>{
        topics.push({prompt:"", choices:[{label:"",reply:"",tier:"plain",expr:"talk"}]}); markDirty(); render();
      }}, "+ 토막 추가"));
    }
    render();
    main.append(el("div", {}, [
      el("h3", {style:"color:var(--accent);margin:18px 0 8px"}, STAGE_LABEL[stage]||stage),
      wrap,
    ]));
  }
}

// ── 탭: 선물 ──
function renderGifts() {
  const main = document.getElementById("main");
  const g = DB.gifts;
  // 프롬프트
  const promptCard = el("div", {class:"card"}, [el("h3",{},"선물 프롬프트 (옥자 질문)")]);
  for (const stage of ["guest","regular"]) {
    const i = el("input", {type:"text", value:(g.prompt||{})[stage]||""});
    i.addEventListener("input", ()=>{ g.prompt[stage]=i.value; markDirty(); });
    promptCard.append(el("div", {}, [el("div",{class:"field-label"}, STAGE_LABEL[stage]||stage), i]));
  }
  main.append(promptCard);
  // 선물 목록
  const listCard = el("div", {class:"card"}, [el("h3",{},"선물 항목")]);
  const box = el("div");
  function render() {
    box.innerHTML = "";
    g.gifts.forEach((gift, gi) => box.append(
      choiceBlock(gift, META.giftTiers, ()=>{ g.gifts.splice(gi,1); markDirty(); render(); })));
    box.append(el("button", {class:"add", onclick:()=>{
      g.gifts.push({label:"",reply:"",tier:"plain",expr:"idle"}); markDirty(); render();
    }}, "+ 선물 추가"));
  }
  render();
  listCard.append(box);
  main.append(listCard);
}

// ── 탭: 버튼·감정 ──
function renderButtons() {
  const main = document.getElementById("main");
  const b = DB.buttons;
  // 옥자 버튼(라벨 잠금) + 감정맵
  const okjaActs = (b.okja.actions||[]).map(a=>a.id+"("+a.label+")").join("  ·  ");
  const em = b.okja.emotion;
  const okjaCard = el("div", {class:"card"}, [
    el("h3", {}, ["옥자 감정 연결", el("span",{class:"lock"},"버튼 라벨·순서 잠금")]),
    el("div", {class:"hint", style:"margin-bottom:10px"}, "버튼: "+okjaActs+"  (대화/선물 감정은 각 탭의 선택지에서 편집)"),
  ]);
  const emoRow = (label, key) => el("div", {style:"margin-bottom:12px"}, [
    el("div", {class:"field-label"}, label),
    emotionPicker("okja", em[key], v=>{ em[key]=v; markDirty(); }),
  ]);
  okjaCard.append(emoRow("체키 버튼 → 표정", "cheki"));
  okjaCard.append(emoRow("음료 버튼 → 표정 (제조 연출)", "drink"));
  okjaCard.append(el("div", {style:"margin-bottom:12px"}, [
    el("div", {class:"field-label"}, "옥자 터치 → 무작위 표정 풀 (여러 개 토글, 최소 1)"),
    emotionMulti("okja", em.touch),
  ]));
  okjaCard.append(emoRow("터치 상한 도달 → 표정", "touch_cap"));
  main.append(okjaCard);

  // 시온이 4버튼
  const sionCard = el("div", {class:"card"}, [
    el("h3", {}, ["시온이 4버튼", el("span",{class:"lock"},"id·호감도종류 잠금")]),
  ]);
  const sionTickerKeys = Object.keys(DB.ticker.sion).filter(k=>!k.startsWith("_"));
  for (const a of b.sion.actions) {
    const labelI = el("input", {type:"text", value:a.label||""});
    labelI.addEventListener("input", ()=>{ a.label=labelI.value; markDirty(); });
    const tickerS = el("select", {});
    for (const k of sionTickerKeys) tickerS.append(el("option", {value:k, ...(k===a.ticker?{selected:"selected"}:{})}, k));
    tickerS.addEventListener("change", ()=>{ a.ticker=tickerS.value; markDirty(); });
    sionCard.append(el("div", {class:"choice"}, [
      el("div", {class:"row"}, [
        el("span", {class:"badge"}, "id: "+a.id),
        el("span", {class:"badge"}, "호감도: "+a.affinity),
      ]),
      el("div", {class:"grid", style:"margin-top:6px"}, [
        el("div", {}, [el("div",{class:"field-label"},"버튼 라벨"), labelI]),
        el("div", {}, [el("div",{class:"field-label"},"티커 풀"), tickerS]),
      ]),
      el("div", {class:"field-label", style:"margin-top:6px"}, "누르면 → 시온이 표정"),
      emotionPicker("sioni", a.emotion, v=>{ a.emotion=v; markDirty(); }),
    ]));
  }
  main.append(sionCard);
}

// ── 탭 전환/렌더 ──
const RENDER = { okja:renderOkja, sion:renderSion, talk:renderTalk, gifts:renderGifts, buttons:renderButtons };
function render() {
  document.getElementById("main").innerHTML = "";
  RENDER[activeTab]();
}
function renderTabs() {
  const t = document.getElementById("tabs");
  t.innerHTML = "";
  for (const [id, label] of TABS) {
    t.append(el("div", {class:"tab"+(id===activeTab?" active":""), onclick:()=>{ activeTab=id; renderTabs(); render(); }}, label));
  }
}

// ── 로드/저장 ──
async function load() {
  setStatus("불러오는 중…","");
  const r = await fetch("/api/data");
  const p = await r.json();
  DB = p.db; META = p.meta; dirty = false;
  setStatus("불러옴 ✓","ok");
  renderTabs(); render();
}
async function save() {
  setStatus("저장 중…","");
  const r = await fetch("/api/save", {method:"POST", headers:{"Content-Type":"application/json"},
    body: JSON.stringify(DB)});
  const p = await r.json();
  if (p.ok) { dirty=false; setStatus("저장됨 ✓ (에디터 F5 로 확인)","ok"); }
  else {
    setStatus("검증 실패 — 저장 안 됨","err");
    const old = document.querySelector(".err-list"); if (old) old.remove();
    document.getElementById("main").prepend(el("div", {class:"err-list"}, "⚠ 저장 차단:\n• "+(p.errors||[]).join("\n• ")));
  }
}
document.getElementById("save").addEventListener("click", save);
document.getElementById("reload").addEventListener("click", ()=>{
  if (dirty && !confirm("저장하지 않은 변경이 사라집니다. 새로고침할까요?")) return;
  load();
});
document.getElementById("nick").addEventListener("input", render);
window.addEventListener("beforeunload", e=>{ if (dirty){ e.preventDefault(); e.returnValue=""; } });
load();
</script>
</body>
</html>
"""


def main():
    ap = argparse.ArgumentParser(description="나라쿠치 콘텐츠 스튜디오")
    ap.add_argument("--port", type=int, default=8770)
    ap.add_argument("--no-browser", action="store_true")
    args = ap.parse_args()

    # 데이터 파일 존재 확인(친절한 에러)
    for fname in FILES.values():
        path = os.path.join(DATA_DIR, fname)
        if not os.path.isfile(path):
            raise SystemExit(f"[오류] 데이터 파일 없음: {path}\n  먼저 리팩터링(JSON 이전)을 끝내세요.")

    server = ThreadingHTTPServer(("127.0.0.1", args.port), Handler)
    url = f"http://127.0.0.1:{args.port}/"
    print(f"나라쿠치 콘텐츠 스튜디오 → {url}")
    print("  편집 → 저장 → Godot 에디터 F5 로 반영 확인. (Ctrl+C 종료)")
    if not args.no_browser:
        threading.Timer(0.6, lambda: webbrowser.open(url)).start()
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("\n종료.")


if __name__ == "__main__":
    main()
