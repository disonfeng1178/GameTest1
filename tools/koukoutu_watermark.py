#!/usr/bin/env python3
"""抠抠图去水印（异步）：透明 PNG 先铺白底 -> 去水印 -> 重新抠图."""
import os, sys, json, time, base64, pathlib, urllib.request, urllib.parse
import io

CREATE = "https://async.koukoutu.com/v1/create"
QUERY = "https://async.koukoutu.com/v1/query"
ROOT = pathlib.Path(__file__).resolve().parents[1]

def post_multipart(url, fields: dict, files: dict, api_key: str) -> dict:
    boundary = "----kkboundary1234"
    body = io.BytesIO()
    for k, v in fields.items():
        body.write(f"--{boundary}\r\n".encode())
        body.write(f'Content-Disposition: form-data; name="{k}"\r\n\r\n'.encode())
        body.write(f"{v}\r\n".encode())
    for k, (fname, data, ctype) in files.items():
        body.write(f"--{boundary}\r\n".encode())
        body.write(f'Content-Disposition: form-data; name="{k}"; filename="{fname}"\r\n'.encode())
        body.write(f"Content-Type: {ctype}\r\n\r\n".encode())
        body.write(data)
        body.write(b"\r\n")
    body.write(f"--{boundary}--\r\n".encode())
    req = urllib.request.Request(url, data=body.getvalue(), headers={
        "X-API-Key": api_key,
        "Content-Type": f"multipart/form-data; boundary={boundary}",
    })
    with urllib.request.urlopen(req, timeout=120) as r:
        return json.loads(r.read().decode())

def post_form(url, fields: dict, api_key: str) -> dict:
    data = urllib.parse.urlencode(fields).encode()
    req = urllib.request.Request(url, data=data, headers={"X-API-Key": api_key})
    with urllib.request.urlopen(req, timeout=60) as r:
        return json.loads(r.read().decode())

def remove_watermark(png_path: pathlib.Path, api_key: str) -> pathlib.Path:
    from PIL import Image
    im = Image.open(png_path).convert("RGBA")
    white = Image.new("RGB", im.size, (255, 255, 255))
    white.paste(im, (0, 0), im)
    buf = io.BytesIO()
    white.save(buf, format="JPEG", quality=95)
    resp = post_multipart(CREATE, {"model_key": "image-watermark-v2"},
                          {"image_file": ("in.jpg", buf.getvalue(), "image/jpeg")}, api_key)
    task_id = resp.get("task_id") or resp.get("data", {}).get("task_id") or resp.get("id")
    if not task_id:
        raise RuntimeError(f"create failed: {resp}")
    print(f"  task {task_id} ...", flush=True)
    for _ in range(60):
        time.sleep(3)
        q = post_form(QUERY, {"task_id": task_id, "response": "url", "model_key": "image-watermark-v2"}, api_key)
        s = json.dumps(q)
        # 找 url
        url = q.get("url") or q.get("data", {}).get("url") if isinstance(q.get("data"), dict) else None
        if not url:
            for v in [q.get("result"), q.get("data")]:
                if isinstance(v, str) and v.startswith("http"):
                    url = v
        status = str(q.get("status", "")).lower()
        if url and ("pending" not in status and "process" not in status):
            out = png_path.with_name(png_path.stem + "_nowm.jpg")
            req = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0"})
            with urllib.request.urlopen(req, timeout=120) as r, open(out, "wb") as f:
                f.write(r.read())
            print(f"  saved {out} {out.stat().st_size}B")
            return out
        if "fail" in status:
            raise RuntimeError(f"task failed: {q}")
    raise RuntimeError(f"timeout: {task_id}")

if __name__ == "__main__":
    key = os.environ.get("KOUKOUTU_API_KEY", "")
    if not key:
        print("export KOUKOUTU_API_KEY='...'")
        sys.exit(2)
    targets = sys.argv[1:] or ["assets/chars/nvxiu.png", "assets/chars/xiaosuo.png",
                                "assets/chars/laohuang.png", "assets/chars/huoji.png"]
    for t in targets:
        p = ROOT / t
        print(f"watermark: {t}", flush=True)
        remove_watermark(p, key)
