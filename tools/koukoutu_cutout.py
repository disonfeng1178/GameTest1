#!/usr/bin/env python3
"""抠抠图 koukoutu 同步抠图：白底/绿幕原图 -> 真透明 PNG.

用法：
  export KOUKOUTU_API_KEY='你的key'
  python3 tools/koukoutu_cutout.py /tmp/guo2/nvxiu_w.jpg assets/chars/nvxiu.png
  python3 tools/koukoutu_cutout.py --all   # 批量重抠4张

API: POST https://sync.koukoutu.com/v1/create
  Header X-API-Key, model_key=background-removal, output_format=png, border=1, response=bytes
积分：同步接口 +1/张，并发 5。
"""
import os, sys, pathlib, urllib.request, urllib.parse

API = "https://sync.koukoutu.com/v1/create"
ROOT = pathlib.Path(__file__).resolve().parents[1]
JOBS = [
    ("/tmp/guo2/nvxiu_w.jpg", "assets/chars/nvxiu.png"),
    ("/tmp/guo2/xiaosuo_w.jpg", "assets/chars/xiaosuo.png"),
    ("/tmp/guo2/laohuang_g.jpg", "assets/chars/laohuang.png"),
    ("/tmp/guo2/huoji_g.jpg", "assets/chars/huoji.png"),
]

def cutout(src: str, dst: str, api_key: str) -> None:
    data = urllib.parse.urlencode({
        "model_key": "background-removal",
        "image_url": src if src.startswith("http") else None,
        "output_format": "png",
        "crop": "0",
        "border": "1",
        "stamp_crop": "0",
        "response": "bytes",
    }).encode()
    # 文件上传用 multipart 简化：走 base64 接口更稳
    if src.startswith("http"):
        req = urllib.request.Request(API, data=data, headers={"X-API-Key": api_key})
        with urllib.request.urlopen(req, timeout=120) as r:
            body = r.read()
    else:
        import base64
        b64 = base64.b64encode(pathlib.Path(src).read_bytes()).decode()
        data2 = urllib.parse.urlencode({
            "model_key": "background-removal",
            "image_base64": b64,
            "output_format": "png",
            "crop": "0",
            "border": "1",
            "response": "bytes",
        }).encode()
        req = urllib.request.Request(API, data=data2, headers={"X-API-Key": api_key})
        with urllib.request.urlopen(req, timeout=120) as r:
            body = r.read()
    out = ROOT / dst
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_bytes(body)
    print(f"OK {dst} {len(body)}B")

if __name__ == "__main__":
    key = os.environ.get("KOUKOUTU_API_KEY", "")
    if not key:
        print("先 export KOUKOUTU_API_KEY='你的key'（https://www.koukoutu.com/user/dev 领取）")
        sys.exit(2)
    if len(sys.argv) == 2 and sys.argv[1] == "--all":
        for s, d in JOBS:
            cutout(s, d, key)
    elif len(sys.argv) == 3:
        cutout(sys.argv[1], sys.argv[2], key)
    else:
        print(__doc__)
