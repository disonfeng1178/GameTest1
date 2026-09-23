#!/usr/bin/env python3
"""即梦 Seedream 4.6（火山视觉 CVSync2Async）：AK/SK -> 国风立绘/背景.

用法：
  python3 tools/jimeng_generate.py --prompt "..." --width 880 --height 1320 --output /tmp/x.png
  python3 tools/jimeng_generate.py --batch docs/art/JIMENG_JOBS.json
  AK/SK 从环境 VOLC_AK / VOLC_SK 读（存 /tmp/.volc_ak /tmp/.volc_sk 亦可）。

流程：cv_sync2async_submit_task(req_key=jimeng_seedream46_cvtob) -> 轮询 get_result -> binary_data_base64 落盘。
"""
import os, sys, json, time, base64, argparse, pathlib

REQ_KEY = "jimeng_seedream46_cvtob"

def creds():
    ak = os.environ.get("VOLC_AK", "")
    sk = os.environ.get("VOLC_SK", "")
    if not ak and pathlib.Path("/tmp/.volc_ak").exists():
        ak = pathlib.Path("/tmp/.volc_ak").read_text().strip()
    if not sk and pathlib.Path("/tmp/.volc_sk").exists():
        sk = pathlib.Path("/tmp/.volc_sk").read_text().strip()
    if not ak or not sk:
        print("缺 AK/SK：export VOLC_AK=... VOLC_SK=...")
        sys.exit(2)
    return ak, sk

def svc(ak, sk):
    from volcengine.visual.VisualService import VisualService
    s = VisualService()
    s.set_ak(ak)
    s.set_sk(sk)
    return s

def gen_one(s, prompt: str, width: int, height: int, out: pathlib.Path) -> None:
    resp = s.cv_sync2async_submit_task({
        "req_key": REQ_KEY,
        "prompt": prompt,
        "width": width, "height": height,
    })
    task_id = resp["data"]["task_id"]
    print(f"  task {task_id} ...", flush=True)
    for _ in range(40):
        time.sleep(4)
        r = s.cv_sync2async_get_result({"req_key": REQ_KEY, "task_id": task_id})
        d = r.get("data", {})
        st = d.get("status")
        if st == "done":
            b64 = d["binary_data_base64"][0]
            out.parent.mkdir(parents=True, exist_ok=True)
            out.write_bytes(base64.b64decode(b64))
            print(f"OK {out} {out.stat().st_size}B")
            return
        if st in ("failed", "error"):
            raise RuntimeError(f"task failed: {r}")
    raise RuntimeError(f"timeout {task_id}")

if __name__ == "__main__":
    ap = argparse.ArgumentParser()
    ap.add_argument("--prompt", default="")
    ap.add_argument("--width", type=int, default=880)
    ap.add_argument("--height", type=int, default=1320)
    ap.add_argument("--output", default="")
    ap.add_argument("--batch", default="")
    a = ap.parse_args()
    ak, sk = creds()
    s = svc(ak, sk)
    if a.batch:
        jobs = json.loads(pathlib.Path(a.batch).read_text(encoding="utf-8"))
        for j in jobs:
            print(f"gen {j['output']}", flush=True)
            w, h = map(int, j.get("size", "880x1320").split("x"))
            gen_one(s, j["prompt"], w, h, pathlib.Path(j["output"]))
    else:
        if not a.prompt or not a.output:
            ap.print_help(); sys.exit(2)
        gen_one(s, a.prompt, a.width, a.height, pathlib.Path(a.output))
