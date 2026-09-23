#!/usr/bin/env python3
"""即梦 Seedream 生图（火山方舟 Ark）：文本 -> 国风立绘/背景.

用法：
  export VOLC_API_KEY='你的火山方舟API Key'
  python3 tools/jimeng_generate.py --prompt "古风少女..." --size 880x1320 --output /tmp/test.png
  python3 tools/jimeng_generate.py --list-models
  python3 tools/jimeng_generate.py --batch docs/art/JIMENG_JOBS.json

接口：POST https://ark.cn-beijing.volces.com/api/v3/images/generations
  Header Authorization: Bearer <key>
  body: {model, prompt, size, response_format=url, watermark=false}
模型默认 doubao-seedream-4-0-250828（1K/2K/4K，最稳）；
4.6 产品见 https://docs.volcengine.com/docs/JimengAI/JimengAI-ImageGeneration46-ProductIntroduction?lang=zh，
如控制台给你开了 4.6/4.5/5.0 就用 --model 切过去，参数同源。
"""
import os, sys, json, argparse, pathlib, urllib.request

BASE = "https://ark.cn-beijing.volces.com/api/v3"
DEFAULT_MODEL = "doubao-seedream-4-0-250828"

def api_post(path: str, body: dict, api_key: str, timeout=300) -> dict:
    data = json.dumps(body).encode()
    req = urllib.request.Request(BASE + path, data=data, headers={
        "Authorization": f"Bearer {api_key}",
        "Content-Type": "application/json",
    })
    with urllib.request.urlopen(req, timeout=timeout) as r:
        return json.loads(r.read().decode())

def list_models(api_key: str) -> None:
    req = urllib.request.Request(BASE + "/models", headers={"Authorization": f"Bearer {api_key}"})
    with urllib.request.urlopen(req, timeout=30) as r:
        print(r.read().decode()[:4000])

def generate(prompt: str, size: str, model: str, api_key: str, watermark=False) -> str:
    body = {
        "model": model,
        "prompt": prompt,
        "size": size,
        "response_format": "url",
        "watermark": watermark,
    }
    resp = api_post("/images/generations", body, api_key)
    data = resp.get("data", [])
    if not data or not data[0].get("url"):
        raise RuntimeError(f"no image url: {resp}")
    return data[0]["url"]

def download(url: str, out: pathlib.Path) -> None:
    req = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0"})
    with urllib.request.urlopen(req, timeout=120) as r, open(out, "wb") as f:
        f.write(r.read())
    print(f"OK {out} {out.stat().st_size}B")

if __name__ == "__main__":
    ap = argparse.ArgumentParser()
    ap.add_argument("--prompt", default="")
    ap.add_argument("--size", default="880x1320")
    ap.add_argument("--model", default=DEFAULT_MODEL)
    ap.add_argument("--output", default="")
    ap.add_argument("--batch", default="")
    ap.add_argument("--list-models", action="store_true")
    ap.add_argument("--api-key", default=os.environ.get("VOLC_API_KEY", ""))
    ap.add_argument("--watermark", action="store_true")
    a = ap.parse_args()
    if a.list_models:
        if not a.api_key:
            print("export VOLC_API_KEY='...'"); sys.exit(2)
        list_models(a.api_key); sys.exit(0)
    if not a.api_key:
        print("先 export VOLC_API_KEY='你的火山方舟Key'"); sys.exit(2)
    if a.batch:
        jobs = json.loads(pathlib.Path(a.batch).read_text(encoding="utf-8"))
        for j in jobs:
            url = generate(j["prompt"], j.get("size", "880x1320"), j.get("model", a.model), a.api_key, j.get("watermark", False))
            print(f"URL {j['output']}: {url}")
            download(url, pathlib.Path(j["output"]))
    else:
        if not a.prompt or not a.output:
            ap.print_help(); sys.exit(2)
        url = generate(a.prompt, a.size, a.model, a.api_key, a.watermark)
        print(f"URL: {url}")
        download(url, pathlib.Path(a.output))
